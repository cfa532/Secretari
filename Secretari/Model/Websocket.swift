//
//  Websocket.swift
//  SummaryAI
//
//  Created by 超方 on 2024/4/2.
//

import Foundation
import SwiftUI

@MainActor
class Websocket: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    @Published var isStreaming: Bool = false
    @Published var streamedText: String = ""
    @Published var alertItem: AlertItem?
    @EnvironmentObject private var identifierManager: IdentifierManager
    
    private var urlSession: URLSession?
    private var wssURL: String?
    private var wsTask: URLSessionWebSocketTask?
    
    func configure(_ url: String) {
        var request = URLRequest(url: URL(string: "http://127.0.0.1")!)
        if self.wssURL == nil {
            self.wssURL = url
            request = URLRequest(url: URL(string: self.wssURL!)!)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer access token", forHTTPHeaderField: "Authorization")
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 5.0
            self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        }

        if let activeTask = self.wsTask, activeTask.state == .running {
            // do nothing
        } else  {
            // cancel hanging wsTask if any
            self.wsTask?.cancel()
//            self.wsTask = urlSession?.webSocketTask(with: URL(string: self.wssURL!)!)
            self.wsTask = urlSession?.webSocketTask(with: request)
        }
    }

    func fetchToken(username: String, password: String="zaq12WSX", completion: @escaping (String?) -> Void) {
        var identifier = self.identifierManager.getDeviceIdentifier()
        var request = URLRequest(url: URL(string: self.wssURL!)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let token = json?["token"] as? String
            completion(token)
        }
        task.resume()
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
    }
    
    func send(_ jsonString: String, errorWrapper: @escaping (_: Error)->Void) {
        wsTask?.send(.string(jsonString)) { error in
            if let error = error {
                print("Websocket.send() failed", error)
                self.alertItem = AlertContext.unableToComplete
            }
        }
    }
    
    func receive(action: @escaping (_: String) -> Void) {
        // expecting {"type": "result", "answer": "summary content"}
        // add a timeout timer
        wsTask?.receive( completionHandler: { result in
            switch result {
            case .failure(let error):
                print("WebSocket failure: \(error)")
                self.alertItem = AlertContext.invalidResponse
                self.alertItem?.message = Text(error.localizedDescription)
                self.cancel()
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        do {
                            if let dict = try JSONSerialization.jsonObject(with: data) as? NSDictionary {
                                if let type = dict["type"] as? String {
                                    if type == "result" {
                                        if let answer = dict["answer"] as? String {
                                            print(answer, dict["tokens"]!, dict["cost"]!)
                                            // send reply from AI to display
                                            action(answer)
                                            self.cancel()
                                        }
                                    } else {
                                        // should be stream type
                                        if let s = dict["data"] as? String {
                                            Task { @MainActor in
                                                self.streamedText += s
                                            }
                                            self.receive(action: action)
                                        }
                                    }
                                }
                            }
                        } catch {
                            self.alertItem = AlertContext.invalidData
                        }
                    }
                case .data(let data):
                    print("Received data: \(data)")
                    self.cancel()
                @unknown default:
                    self.cancel()
                    self.alertItem = AlertContext.invalidData
                }
            }
        })
    }
    
    func resume() {
        Task { @MainActor in
            self.isStreaming = true
        }
        wsTask?.resume()
    }
    
    func cancel() {
        Task { @MainActor in
            self.isStreaming = false
            self.streamedText = ""
        }
        wsTask?.cancel(with: .goingAway, reason: nil)
        //        urlSession?.invalidateAndCancel()
    }
}

extension Websocket {
    @MainActor func sendToAI(_ rawText: String, prompt: String, wssURL: String, action: @escaping (_ summary: String)->Void) {
        let msg = [
            "input": [
                "prompt": prompt,
                "rawtext": rawText],
            "parameters": [
                "llm": AppConstants.LLM,
                "temperature": AppConstants.OpenAITemperature,
                "client":"mobile",
                "model": AppConstants.OpenAIModel]] as [String : Any]
        
        // Convert the Data to String
        let jsonData = try! JSONSerialization.data(withJSONObject: msg)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Websocket sending: ", jsonString)
            self.configure(wssURL)
            Task {
                self.send(jsonString) { error in
                    self.alertItem = AlertContext.unableToComplete
                }
                self.receive(action: action)
                self.resume()
            }
        }
    }
}
