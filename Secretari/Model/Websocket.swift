//
//  Websocket.swift
//  SummaryAI
//
//  Created by 超方 on 2024/4/2.
//

import Foundation
import SwiftUI

//@MainActor
class Websocket: NSObject, ObservableObject, URLSessionWebSocketDelegate, Observable {
    @Published var isStreaming: Bool = false
    @Published var streamedText: String = ""
    @Published var alertItem: AlertItem?
    
    private var tokenManager = TokenManager.shared
    private var urlSession: URLSession?
    private var settings = SettingsManager.shared.getSettings()
    private var wsTask: URLSessionWebSocketTask?
    
    static let shared = Websocket()
    
    private override init() {
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        //        self.serverURL = SettingsManager.shared.getSettings().serverURL      // dead sure it is a string
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
        var request = URLRequest(url: URL(string: self.settings.serverURL)!)
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
                                print("Data from ws: ", dict)
                                if let type = dict["type"] as? String {
                                    if type == "result" {
                                        if let answer = dict["answer"] as? String {
                                            // send reply from AI to display
                                            action(answer)
                                            self.cancel()
                                            
                                            // bookkeeping. Update token count
                                            let user = dict["user"] as? [String: Any] ?? [:]
                                            UserManager.shared.currentUser = Utility.convertDictionaryToUser(from: user, user: UserManager.shared.currentUser!)
                                            print("Received from ws", UserManager.shared.currentUser as Any)
                                            if !KeychainManager.shared.save(data: UserManager.shared.currentUser, for: "currentUser") {
                                                print("Failed to update user account from WS")
                                            }
                                        }
                                    } else {
                                        // should be stream type
                                        if let s = dict["data"] as? String {
                                            Task { @MainActor in
                                                self.streamedText += s      // display streaming message from ai to user.
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
    @MainActor func sendToAI(_ rawText: String, action: @escaping (_ summary: String)->Void) {
        guard settings.llmParams != nil, settings.llmParams![settings.llmModel!] != nil else { print("Empty LLM parameters"); return }
        let llmParams = settings.llmParams![settings.llmModel!]
        let prompt = settings.prompt[settings.promptType]![settings.selectedLocale]
        Utility.printDict(obj: llmParams!)
        let user = UserManager.shared.currentUser
        let msg = [
            "user": user!.username,
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
                self.wsTask = urlSession?.webSocketTask(with: URL(string: "ws://" + self.settings.serverURL + "/ws/")!)
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

enum HTTPStatusCode: Int {
  case success = 200
  case created = 201
  case accepted = 202
  case noContent = 204
    case failure = 400
  // ... Add other common codes as needed
}

// http calls for user account management
extension Websocket {
    func registerUser(_ user: User, completion: @escaping ([String: Any]?, HTTPStatusCode?) -> Void) {
        // send to register endpoint
        var request = URLRequest(url: URL(string: "http://"+self.settings.serverURL+"/users/register")!)   // should be https://ip/secretari/users/register
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["username": user.username, "password": user.password, "family_name": user.family_name ?? "", "given_name": user.given_name ?? "", "email": user.email ?? "", "mid": user.mid ?? "", "subscription": user.subscription]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    completion(nil, .failure)
                } else {
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    completion(json, .created)
                }
            }
        }
        task.resume()
    }
    
    func updateUser(_ user: User) {
        // update
    }
    
    // create a temp user record on server
    func createTempUser(_ user: User, completion: @escaping ([String: Any]?, HTTPStatusCode?) -> Void) {
        var request = URLRequest(url: URL(string: "http://"+self.settings.serverURL + "/users/temp")!)   // should be https://ip/secretari/users/temp
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["username": user.username, "password": user.password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    completion(nil, .failure)
                } else {
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    completion(json, .created)
                }
            }
        }
        task.resume()
    }
    
    // fetch login token and updated user information from server
    @MainActor func fetchToken(_ user: User, completion: @escaping ([String: Any]?, HTTPStatusCode?) -> Void) {
        var request = URLRequest(url: URL(string: "http://"+self.settings.serverURL + "/token")!)   // should be https://ip/secretari/token
        request.httpMethod = "POST"
        //        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")   // required by FastAPI
        
        let body: [String: String] = ["username": user.username, "password": user.password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 400 {
                    completion(nil, .failure)
                } else {
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    completion(json, .created)
                }
            }
        }
        task.resume()
    }}
