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
    @Published var showAlert = false

    private var entitlementManager: EntitlementManager
    private var urlSession: URLSession?
    private var wsTask: URLSessionWebSocketTask?
    private var webURL: URLComponents
    private var wsURL: URLComponents

    static let shared = Websocket()
    
    private override init() {
        entitlementManager = EntitlementManager()
        webURL = URLComponents()
        wsURL = URLComponents()
        super.init()
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        configureURLs()
    }
    
    private func configureURLs() {
        webURL.scheme = "https"
        webURL.host = "secretari.leither.uk"
        wsURL.scheme = "wss"
        wsURL.host = "secretari.leither.uk"
    }
    
    // MARK: - URLSessionWebSocketDelegate Methods
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
    }
    
    // MARK: - WebSocket Methods
    /// Sends a JSON string message to the WebSocket server.
    func send(_ jsonString: String, errorWrapper: @escaping (_: Error) -> Void) {
        wsTask?.send(.string(jsonString)) { error in
            Task { @MainActor in
                if let error = error {
                    print("Websocket.send() failed", error)
                    self.alertItem = AlertContext.unableToComplete
                    self.showAlert = true
                }
            }
        }
    }
    /// Receives messages from the WebSocket server.
    func receive(action: @escaping (_: String) -> Void) {
        wsTask?.receive { result in
            Task { @MainActor in
                switch result {
                case .failure(let error):
                    self.handleWebSocketError(error)
                case .success(let message):
                    self.handleWebSocketMessage(message, action: action)
                }
            }
        }
    }
    
    private func handleWebSocketError(_ error: Error) {
        print("WebSocket failure: \(error)")
        self.alertItem = AlertContext.invalidResponse
        self.alertItem?.message = Text(error.localizedDescription)
        self.showAlert = true
        self.cancel()
    }
    /// Handles incoming WebSocket messages.
    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message, action: @escaping (_: String) -> Void) {
        switch message {
        case .string(let text):
            processWebSocketText(text, action: action)
        case .data(let data):
            print("Received data: \(data)")
            self.cancel()
        @unknown default:
            self.cancel()
            self.alertItem = AlertContext.invalidData
            self.showAlert = true
        }
    }
    /// Processes text messages received from the WebSocket.
    private func processWebSocketText(_ text: String, action: @escaping (_: String) -> Void) {
        if let data = text.data(using: .utf8) {
            do {
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any], let type = dict["type"] as? String {
                    handleWebSocketResponseType(type, dict: dict, action: action)
                }
            } catch {
                self.alertItem = AlertContext.invalidData
                self.showAlert = true
                self.cancel()
            }
        }
    }
    /// Handles different types of WebSocket responses.
    /// STREAM to give user instant response
    /// RESULT is the final result from AI
    private func handleWebSocketResponseType(_ type: String, dict: [String: Any], action: @escaping (_: String) -> Void) {
        switch type {
        case "result":
            handleResultType(dict, action: action)
        case "stream":
            handleStreamType(dict, action: action)
        case "error":
            handleErrorType(dict)
        default:
            self.cancel()
            self.alertItem = AlertContext.invalidData
            self.showAlert = true
        }
    }
    /// Handles the "result" type response from the WebSocket.
    private func handleResultType(_ dict: [String: Any], action: @escaping (_: String) -> Void) {
        if let answer = dict["answer"] as? String {
            print("Result from AI: ", dict)
            action(answer)
            updateUserAccount(dict)
            if let eof = dict["eof"] as? Bool, eof == true {
                self.cancel()
            } else {
                self.receive(action: action)
            }
        }
    }
    /// Handles the "stream" type response from the WebSocket.
    private func handleStreamType(_ dict: [String: Any], action: @escaping (_: String) -> Void) {
        if let s = dict["data"] as? String {
            self.streamedText += s
            self.receive(action: action)
        }
    }
    
    private func handleErrorType(_ dict: [String: Any]) {
        if let message = dict["message"] as? String {
            print("Message from ws: ", dict)
            self.alertItem = AlertContext.invalidData
            self.alertItem?.message = Text(LocalizedStringKey(message))
            self.showAlert = true
        }
        self.cancel()
    }
    /// Updates the user's balance and token count based on the response.
    private func updateUserAccount(_ dict: [String: Any]) {
        if let cost = dict["cost"] as? Double, let tokens = dict["tokens"] as? UInt {
            let userManager = UserManager.shared
            userManager.currentUser?.dollar_balance -= cost
            userManager.currentUser?.token_count += tokens
            userManager.persistCurrentUser()
        }
    }
    /// Resumes the WebSocket task and sets the streaming flag.
    func resume() {
        Task { @MainActor in
            self.isStreaming = true
        }
        wsTask?.resume()
    }
    /// Cancels the WebSocket task and resets streaming state.
    func cancel() {
        wsTask?.cancel(with: .normalClosure, reason: nil)
        Task { @MainActor in
            self.isStreaming = false
            self.streamedText = ""
        }
    }
    
    // MARK: - Send to AI
    /// Sends text to the AI for processing.
    @MainActor func sendToAI(_ rawText: String, prompt: String, action: @escaping (_ summary: String) -> Void) {
        let settings = SettingsManager.shared.getSettings()
        if let sprompt = settings.prompt[settings.promptType], let str = sprompt[settings.selectedLocale] ?? sprompt[RecognizerLocale.English] {
            let msg = createMessage(rawText: rawText, prompt: prompt, defaultPrompt: str, settings: settings)
            sendMessageToWebSocket(msg, action: action)
        }
    }
    /// Creates the message payload for sending to the AI.
    private func createMessage(rawText: String, prompt: String, defaultPrompt: String, settings: Settings) -> [String: Any] {
        return [
            "input": [
                "prompt": prompt.isEmpty ? defaultPrompt : prompt,
                "prompt_type": settings.promptType.rawValue,
                "rawtext": rawText,
                "subscription": entitlementManager.hasPro
            ],
            "parameters": [
                "llm": settings.llmParams["llm"] as Any,
                "temperature": settings.llmParams["temperature"] as Any,
            ]
        ]
    }
    /// Sends the message to the WebSocket server.
    private func sendMessageToWebSocket(_ msg: [String: Any], action: @escaping (_ summary: String) -> Void) {
        if let jsonString = try? JSONSerialization.data(withJSONObject: msg).string {
            print("Websocket sending: ", jsonString)
            if let activeTask = self.wsTask, activeTask.state != .running {
                self.wsTask?.cancel()
            }
            if let accessToken = UserManager.shared.userToken {
                self.wsURL.path = EndPoint.websocket.rawValue
                self.wsURL.query = "token=" + accessToken
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

// MARK: - HTTPStatusCode Enum

enum HTTPStatusCode: Int, Comparable {
    case success = 200
    case created = 201
    case accepted = 202
    case noContent = 204
    case failure = 400
    
    static func < (lhs: HTTPStatusCode, rhs: HTTPStatusCode) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - EndPoint Enum

enum EndPoint: String {
    case accessToken = "/secretari/token"
    case productIDs = "/secretari/productids"
    case notice = "/secretari/notice"
    case register = "/secretari/users/register"
    case updateUser = "/secretari/users"
    case temporaryUser = "/secretari/users/temp"
    case websocket = "/secretari/ws/"
}

// MARK: - HTTP Calls for User Account Management

extension Websocket {
    func registerUser(_ user: User) async throws -> [String: Any]? {
        self.webURL.path = EndPoint.register.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": user.username,
            "password": user.password,
            "family_name": user.family_name ?? "",
            "given_name": user.given_name ?? "",
            "email": user.email ?? "",
            "id": user.id
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            return nil
        }
    }
    
    func updateUser(_ user: User) async throws -> [String: Any]? {
        self.webURL.path = EndPoint.updateUser.rawValue
        guard let url = self.webURL.url else {
            print("Invalid URL")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "username": user.username,
            "password": user.password.trimmingCharacters(in: .whitespaces),
            "email": user.email ?? "",
            "family_name": user.family_name ?? "",
            "given_name": user.given_name ?? ""
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        guard let accessToken = UserManager.shared.userToken else {
            print("Access token is missing")
            return nil
        }
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            return nil
        }
    }
    
    func deleteUser() async throws -> [String: String]? {
        self.webURL.path = EndPoint.updateUser.rawValue
        guard let url = self.webURL.url else {
            print("Invalid URL")
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let accessToken = UserManager.shared.userToken else {
            print("Access token is missing")
            return nil
        }
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: String]
        } else {
            return nil
        }
    }
    /// Creates a temporary user account.
    /// Use the temp account for unregistered users, until they run out of bonus balance.
    func createTempUser(_ user: User) async throws -> [String: Any]? {
        self.webURL.path = EndPoint.temporaryUser.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": user.username,      // use DeviceId as temp user name
            "password": user.password,
            "id": user.id
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } else {
            return nil
        }
    }
    /// Get Id of a paid product, one-time purchase, or monthly subscription.
    /// productIDs ["Yearly.bunny0": 89.99, "monthly.bunny0": 8.99, "890842": 8.99]
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
        task.resume()   // execute the task
    }
    /// Get system notice to all users from server. It will be displayed on Settings screen.
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
    /// Fetches an access token for a user.
    func fetchToken(username: String, password: String, completion: @escaping ([String: Any]?, HTTPStatusCode?) -> Void) {
        self.webURL.path = EndPoint.accessToken.rawValue
        var request = URLRequest(url: self.webURL.url!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
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
    }
}

// MARK: - Extensions

private extension Data {
    var string: String? {
        return String(data: self, encoding: .utf8)
    }
}
