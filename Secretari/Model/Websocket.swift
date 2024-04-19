//
//  Websocket.swift
//  SummaryAI
//
//  Created by 超方 on 2024/4/2.
//

import Foundation

@MainActor
class Websocket: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    @Published var isStreaming: Bool = false
    @Published var streamedText: String = ""
    
    private var urlSession: URLSession?
    private var wsUrl: String?
    private var wsTask: URLSessionWebSocketTask?
    
    override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }
    
    func prepare(_ url: String) {
        self.wsTask = urlSession!.webSocketTask(with: URL(string: url)!)
        self.wsUrl = url
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
                print("Websocket.send() failed")
                errorWrapper(error)
            }
        }
    }

    func receive(action: @escaping (_: String) -> Void) {
        // expecting {"type": "result", "answer": "summary content"}
        // add a timeout timer
        wsTask?.receive( completionHandler: { result in
            // once WS begin to receive data
            
            switch result {
            case .failure(let error):
                print("WebSocket failure: \(error)")
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
                            print("Invalid Json string received.")
                            self.cancel()
                        }
                    }
                case .data(let data):
                    print("Received data: \(data)")
                    self.cancel()
                @unknown default:
                    print("Unknown data")
                    self.cancel()
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
    @MainActor func sendToAI(_ rawText: String, settings: AppSettings, action: @escaping (_ summary: String)->Void) {
        let msg = ["input":[
            "prompt": settings.prompt,
            "rawtext": rawText],
                   "parameters":[
                    "llm": AppConstants.LLM,
                    "temperature": AppConstants.OpenAITemperature,
                    "client":"mobile",
                    "model": AppConstants.OpenAIModel]] as [String : Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: msg)
        Task {
            // Convert the Data to String
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                self.wsUrl = settings.wssURL
                self.wsTask = urlSession!.webSocketTask(with: URL(string: self.wsUrl!)!)
                self.send(jsonString) { error in
//                    errorWrapper = ErrorWrapper(error: error, guidance: "Cannot connect to Websocket. Try it later.")
                    fatalError("Could not send to websocket: \(error)")
                }
                self.receive(action: action)
                self.resume()
            }
        }
    }
}
