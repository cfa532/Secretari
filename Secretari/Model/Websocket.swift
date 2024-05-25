//
//  Websocket.swift
//  SummaryAI
//
//  Created by 超方 on 2024/4/2.
//

import Foundation
import SwiftUI

@MainActor
class Websocket: NSObject, ObservableObject, URLSessionWebSocketDelegate, Observable {
    @Published var isStreaming: Bool = false
    @Published var streamedText: String = ""
    @Published var alertItem: AlertItem?
    
    private var tokenManager = TokenManager()
    private var urlSession: URLSession?
    private var serverURL: String = AppConstants.defaultSettings.serverURL
    private var wsTask: URLSessionWebSocketTask?
    
    static let shared = Websocket()
    
    private override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        self.serverURL = SettingsManager.shared.loadSettings()["serverURL"] as! String      // dead sure it is a string
    }
    
    func configure(_ url: String) {
//        self.serverURL = url       // different request has different end point.
        if let token=self.tokenManager.loadToken(), !tokenManager.isTokenExpired(token: token) {
            // valid token
            setRequestHeader()
        } else {
//            fetchToken() { token, tokenCount in
//                guard token != nil else {
//                    print("Empty token from server.")
//                    self.alertItem = AlertContext.invalidData
//                    return
//                }
//                self.tokenManager.saveToken(token: token!)
//                self.setRequestHeader()
//            }
        }
    }
    
    func setRequestHeader() {
        var request = URLRequest(url: URL(string: self.serverURL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer " + self.tokenManager.loadToken()!, forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 5.0
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
    
    // Might need to temporarily revise settings' value.
    @MainActor func sendToAI(_ rawText: String, settings: Settings, action: @escaping (_ summary: String)->Void) {
        // pass in settings as parameter instead of using local global copy, so the settings can be modified for special case before hand.
        guard settings.llmParams != nil, settings.llmParams![settings.llmModel!] != nil else { print("Empty LLM parameters"); return }
        let llmParams = settings.llmParams![settings.llmModel!]
        let prompt = settings.prompt[settings.promptType]![settings.selectedLocale]
        Utility.printDict(obj: llmParams!)

        let msg = [
            "input": [
                "prompt": prompt,
                "rawtext": rawText],
            "parameters": [
                "llm": llmParams!["llm"],
                "temperature": llmParams!["temperature"],
                "client":"mobile",
                "model": settings.llmModel!.rawValue
            ]] as [String : Any]
        
        // Convert the Data to String
        let jsonData = try! JSONSerialization.data(withJSONObject: msg)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Websocket sending: ", jsonString)
            
            if let activeTask = self.wsTask, activeTask.state == .running {
                // do nothing
            } else  {
                // cancel hanging wsTask if any
                self.wsTask?.cancel()
                self.wsTask = urlSession?.webSocketTask(with: URL(string: "ws://" + self.serverURL + "/ws/")!)
            }

            Task {
                self.send(jsonString) { error in
                    self.alertItem = AlertContext.unableToComplete
                }
                self.receive(action: action)
                self.resume()
            }
        }
    }
    
    func createUser(user: User) {
        // send user iden
    }
}

extension Websocket {
    // http calls for user account management
    func registerUser(_ user: User, completion: @escaping ([String: Any]?) -> Void) {
        // send to register endpoint
        var request = URLRequest(url: URL(string: "https://"+self.serverURL+"/users/register")!)   // should be https://ip/secretari/users/register
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["username": user.username, "password": user.password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            completion(json)
        }
        task.resume()
    }
    
    func updateUser(_ user: User) {
        // update
    }
    
    // create a temp user record on server
    func createTempUser(_ user: User, completion: @escaping ([String: Any]?) -> Void) {
        var request = URLRequest(url: URL(string: "http://"+self.serverURL + "/users/temp")!)   // should be https://ip/secretari/users/temp
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["username": user.username, "password": user.password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            completion(json)
        }
        task.resume()
    }
    
    // fetch login token and updated user information from server
    @MainActor func fetchToken(_ user: User, completion: @escaping ([String: Any]?) -> Void) {
        var request = URLRequest(url: URL(string: "https://"+self.serverURL + "/token")!)   // should be https://ip/secretari/token
        request.httpMethod = "POST"
        //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")   // required by FastAPI
        
        let body: [String: String] = ["username": user.username, "password": user.password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            completion(json)
        }
        task.resume()
    }}
