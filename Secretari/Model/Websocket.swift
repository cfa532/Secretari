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
    private let settings = SettingsManager.shared.getSettings()

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
                                            self.cancel()       // close websocket
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
        Task { @MainActor in
            self.isStreaming = false
            self.streamedText = ""
        }
        wsTask?.cancel(with: .goingAway, reason: nil)
        //        urlSession?.invalidateAndCancel()
    }
    
    // Might need to temporarily revise settings' value.
    @MainActor func sendToAI(_ rawText: String, prompt: String, action: @escaping (_ summary: String)->Void) {
        if let user = UserManager.shared.currentUser {
            // logic here to distinguish between subscribers and others.
            // non-subscribers use gpt-3.5, if there is still balance. Not memo prompt
            var promptType = settings.promptType
            if user.dollar_balance <= 0.1, !EntitlementManager.isSubscriber {
                promptType = .summary       // need further test
            }
            
            if let sprompt = settings.prompt[promptType] {
                let msg = [
                    "input": [
                        "prompt": prompt=="" ? sprompt[settings.selectedLocale] as Any : prompt,    // use defualt prompt if not provided as parameter
                        "rawtext": "A China-registered account is a WeChat account that was originally registered to a mainland Chinese phone number. A non-China-registered account is any WeChat account that was not originally registered to a mainland Chinese phone number (for example an account registered to a Canadian or United States phone number). China-registered accounts are under terms of service in the jurisdiction of China (specifically Shenzhen) and are subject to censorship. Censorship persists for China-registered accounts even if the account is later associated with a phone number outside of China. Non-China-registered accounts are under terms of service outside the jurisdiction of China (specifically Singapore). While in previous research non-China-registered accounts had not been found to be under political censorship, our latest study reveals that documents and images sent from these accounts are nevertheless under political surveillance and that this content is used to invisibly build up WeChat’s censorship system for China-registered accounts. Someone asked us if non-China-registered users were safe from political surveillance using WeChat as long as they weren’t talking to China-registered users. Since we knew that messages between such users were free from political censorship, we responded that “we think they are free from surveillance too.” But then we got to thinking: how can we actually measure this? Surveillance rarely occurs in a vacuum, and can be used to enable future censorship. We knew from previous work how the surveillance of images and documents is used to employ censorship in an automated fashion on WeChat. The tricky part was that non-China-registered users were not under censorship, and so to test for whether they were under surveillance we had to use two different chat conversations: a first conversation between only non-China-registered accounts for triggering surveillance and a second conversation containing a China-registered account to measure changes in censorship. When we sent politically sensitive content in the first conversation, we observed an increase in censorship in the second, revealing that the first conversation was under surveillance despite being among only non-China-registered accounts.Think of it as a digital fingerprint. When files are run through the MD5 algorithm, the algorithm will generate a fingerprint, or “hash.” The hash is a short, fixed-size string of bits. In theory, it should be difficult to find or create files that will produce the same hash. However, there are vulnerabilities in the MD5 algorithm that make this reproduction easy, and we can exploit these vulnerabilities in our research. By creating two different images with the same hash — one politically sensitive and one benign — we can study how WeChat’s surveillance system works. When we send politically sensitive images between accounts registered outside China, politically benign images with the same hash are censored when sent between Chinese accounts. These benign images would not have usually been flagged as sensitive, proving that surveillance is happening in conversations between accounts registered outside China.",
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
        print(webURL.url as Any)
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
