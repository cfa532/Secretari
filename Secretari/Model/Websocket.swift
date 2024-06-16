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
    @Published var showAlert = false

    private var urlSession: URLSession?
    private var wsTask: URLSessionWebSocketTask?
    private var webURL: URLComponents
    private var wsURL: URLComponents

    static let shared = Websocket()
    private override init() {
        webURL = URLComponents()
        wsURL = URLComponents()
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webURL.scheme = "https"
        webURL.host = "leither.uk"
        wsURL.scheme = "wss"
        wsURL.host = "leither.uk"
//        webURL.scheme = "http"
//        webURL.host = "localhost"
//        wsURL.scheme = "ws"
//        wsURL.host = "localhost"
//        webURL.port = 8000
//        wsURL.port = 8000
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
    }
    
    func send(_ jsonString: String, errorWrapper: @escaping (_: Error)->Void) {
        wsTask?.send(.string(jsonString)) { error in
            Task {@MainActor in
                if let error = error {
                    print("Websocket.send() failed", error)
                    self.alertItem = AlertContext.unableToComplete
                    self.showAlert = true
                }
            }
        }
    }
    
    func receive(action: @escaping (_: String) -> Void) {
        // expecting {"type": "result", "answer": "summary content"}
        // add a timeout timer
        wsTask?.receive( completionHandler: { result in
            Task { @MainActor in
                switch result {
                case .failure(let error):
                    print("WebSocket failure: \(error)")
                    self.alertItem = AlertContext.invalidResponse
                    self.alertItem?.message = Text(error.localizedDescription)
                    self.showAlert = true
                    self.cancel()
                case .success(let message):
                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8) {
                            do {
                                if let dict = try JSONSerialization.jsonObject(with: data) as? NSDictionary, let type = dict["type"] as? String {
                                    print("Data from ws: ", dict)
                                    if type == "result" {
                                        if let answer = dict["answer"] as? String {
                                            // send reply from AI to display
                                            action(answer)
                                            
                                            // bookkeeping. Update token count
                                            if let cost=dict["cost"] as? Double, let tokens=dict["tokens"] as? UInt {
                                                let userManager = UserManager.shared
                                                userManager.currentUser?.dollar_balance -= cost
                                                userManager.currentUser?.token_count += tokens
                                                userManager.persistCurrentUser()
                                            }
                                            if let eof = dict["eof"] as? Bool, eof==true {
                                                self.isStreaming = false
                                                self.streamedText = ""
                                                self.cancel()
                                                // uvicorn myapp:app --timeout-keep-alive 30 to keep idle connection open for 30s. Default is 5s.
                                            } else {
                                                self.receive(action: action)    // keep receiving
                                            }
                                        }
                                    } else {
                                        // should be stream type. Display the streaming text from AI
                                        if let s = dict["data"] as? String {
                                            self.streamedText += s      // display streaming message from ai to user.
                                            self.receive(action: action)    // receive next charater
                                        }
                                    }
                                }
                            } catch {
                                self.alertItem = AlertContext.invalidData
                                self.showAlert = true
                            }
                        }
                    case .data(let data):
                        print("Received data: \(data)")
                        self.cancel()
                    @unknown default:
                        self.cancel()
                        self.alertItem = AlertContext.invalidData
                        self.showAlert = true
                    }
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
        wsTask?.cancel(with: .normalClosure, reason: nil)
        //        urlSession?.invalidateAndCancel()
    }
    
    // Might need to temporarily revise settings' value.
    @MainActor func sendToAI(_ rawText: String, prompt: String, action: @escaping (_ summary: String)->Void) {
        if let user = UserManager.shared.currentUser {
            // logic here to distinguish between subscribers and others.
            // non-subscribers use gpt-3.5, if there is still balance. Not memo prompt
            let settings = SettingsManager.shared.getSettings()
            var promptType = settings.promptType
            if user.dollar_balance <= 0.1, !EntitlementManager.isSubscriber {
                promptType = .summary       // need further test
            }
            
            if let sprompt = settings.prompt[promptType] {
                let msg = [
                    "input": [
                        "prompt": prompt=="" ? sprompt[settings.selectedLocale] as Any : prompt,    // use defualt prompt if not provided as parameter
                        "rawtext": rawText,
                        "subscription": EntitlementManager.isSubscriber,
                        "balance": user.dollar_balance
                    ],
                    "parameters": [
                        "llm": settings.llmParams["llm"] as Any,
                        "temperature": settings.llmParams["temperature"] as Any,
                    ]] as [String : Any]
                
                // Convert String to Data
                let jsonData = try! JSONSerialization.data(withJSONObject: msg)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Websocket sending: ", jsonString)
                    
                    if let activeTask = self.wsTask, activeTask.state != .running {
                        // cancel hanging wsTask if any
                        self.wsTask?.cancel()
                    }
                    if let accessToken = UserManager.shared.userToken {
                        self.wsURL.path = EndPoint.websocket.rawValue
                        self.wsURL.query = "token="+accessToken
                        self.wsTask = urlSession?.webSocketTask(with: self.wsURL.url!)

                        self.send(jsonString) { error in
                            Task { @MainActor in
                                self.alertItem = AlertContext.unableToComplete
                                self.showAlert = true
                            }
                        }
                        self.receive(action: action)
                        self.resume()
                    } else {
                        self.alertItem = AlertContext.invalidUserData
                        self.alertItem?.message = Text("Invalid access token")
                        self.showAlert = true
                    }
                }
            }
        }
    }
    
    func createUser(user: User) {
        // send user iden
    }
}

enum HTTPStatusCode: Int, Comparable {
    case success = 200
    case created = 201
    case accepted = 202
    case noContent = 204
    case failure = 400
    // ... Add other common codes as needed
    
    static func < (lhs: HTTPStatusCode, rhs: HTTPStatusCode) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum EndPoint: String {
    case accessToken    = "/secretari/token"
    case productIDs     = "/secretari/productids"
    case notice         = "/secretari/notice"
    case register       = "/secretari/users/register"
    case updateUser     = "/secretari/users/update"
    case temporaryUser  = "/secretari/users/temp"
    case recharge       = "/secretari/users/recharge"
    case subscibe       = "/secretari/users/subscribe"
    case websocket      = "/secretari/ws/"
}

// http calls for user account management
extension Websocket {
    func registerUser(_ user: User, completion: @escaping ([String: Any]?, HTTPStatusCode?) -> Void) {
        // send to register endpoint
        self.webURL.path = EndPoint.register.rawValue
        var request = URLRequest(url: self.webURL.url!)   // should be https://ip/secretari/users/register
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["username": user.username, "password": user.password, "family_name": user.family_name ?? "", "given_name": user.given_name ?? "", "email": user.email ?? "", "mid": user.mid ?? ""]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
                completion(json, .failure)
            } else {
                completion(json, .created)
            }
        }
        task.resume()
    }
    
    func updateUser(_ user: User) async throws -> [String: Any]? {
        self.webURL.path = EndPoint.updateUser.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["username": user.username, "password": user.password, "email": user.email ?? "", "family_name": user.family_name ?? "", "given_name": user.given_name ?? ""]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let accessToken = UserManager.shared.userToken else { return nil}
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            return nil
        }
    }
    
    func createTempUser(_ user: User) async throws -> [String: Any]? {
        self.webURL.path = EndPoint.temporaryUser.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["username": user.username, "password": user.password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            return nil
        }
    }
    
    func getProductIDs(_ completion: @escaping ([String: Any]?, HTTPStatusCode?) -> Void) {
        self.webURL.path = EndPoint.productIDs.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(json, .success)
            } else {
                completion(json, .failure)
            }
        }
        task.resume()
    }
    
    func getNotice() async throws -> String? {
        self.webURL.path = EndPoint.notice.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    func recharge(_ dict: [String: Any]) async throws -> [String: Any]? {
        self.webURL.path = EndPoint.recharge.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let accessToken = UserManager.shared.userToken else { return nil}
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: dict)
  
        // receipt is not necessary according to: https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            return nil
        }
    }
    
    func subscribe(_ dict: [String: Any]) async throws -> [String: Any]? {
        self.webURL.path = EndPoint.subscibe.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let accessToken = UserManager.shared.userToken else { return nil}
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: dict)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            return nil
        }
    }
    
    // fetch login token and updated user information from server
    func fetchToken(username: String, password: String, completion: @escaping ([String: Any]?, HTTPStatusCode?) -> Void) {
        self.webURL.path = EndPoint.accessToken.rawValue
        var request = URLRequest(url: self.webURL.url!)   // should be https://ip/secretari/token
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")   // required by FastAPI
        let formData = "username=\(username)&password=\(password)"
        request.httpBody = formData.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(json, .success)
            } else {
                completion(json, .failure)
            }
        }
        task.resume()
    }}
