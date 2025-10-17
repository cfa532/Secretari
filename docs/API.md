# Secretari API Documentation

This document describes the API endpoints and communication protocols used by the Secretari iOS app to interact with the backend services.

## Base URL

- **HTTPS**: `https://secretari.leither.uk`
- **WebSocket**: `wss://secretari.leither.uk`

## Authentication

The API uses JWT token-based authentication. Tokens are obtained through login and included in subsequent requests.

### Token Usage
- **Header**: `Authorization: Bearer {token}`
- **WebSocket Query**: `?token={token}`
- **Storage**: Tokens are securely stored in iOS Keychain

## API Endpoints

### 1. Authentication

#### POST `/secretari/token`
Obtains an access token for user authentication.

**Request:**
```
Content-Type: application/x-www-form-urlencoded

username={username}&password={password}
```

**Response (200 OK):**
```json
{
  "access_token": "jwt_token_string",
  "token_type": "bearer",
  "expires_in": 3600
}
```

**Usage in App:**
```swift
websocket.fetchToken(username: username, password: password) { dict, statusCode in
    // Handle response
}
```

### 2. User Management

#### POST `/secretari/users/register`
Registers a new user account.

**Request:**
```json
{
  "username": "string",
  "password": "string",
  "family_name": "string",
  "given_name": "string",
  "email": "string",
  "id": "uuid_string"
}
```

**Response (200 OK):**
```json
{
  "user_id": "uuid_string",
  "username": "string",
  "balance": 0.0,
  "token_count": 0
}
```

#### PUT `/secretari/users`
Updates user account information.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "username": "string",
  "password": "string",
  "email": "string",
  "family_name": "string",
  "given_name": "string"
}
```

#### DELETE `/secretari/users`
Deletes user account.

**Headers:**
```
Authorization: Bearer {token}
```

#### POST `/secretari/users/temp`
Creates a temporary user account for unregistered users.

**Request:**
```json
{
  "username": "device_uuid",
  "password": "temp_password",
  "id": "device_uuid"
}
```

### 3. Product Information

#### GET `/secretari/productids`
Retrieves available in-app purchase product IDs and pricing.

**Response (200 OK):**
```json
{
  "ver0": {
    "productIDs": {
      "890842": 8.99,
      "Yearly.bunny0": 89.99,
      "monthly.bunny0": 8.99
    }
  }
}
```

**Usage in App:**
```swift
websocket.getProductIDs { dict, statusCode in
    // Parse product IDs and prices
}
```

### 4. System Information

#### GET `/secretari/notice`
Retrieves system-wide notices for users.

**Response (200 OK):**
```plaintext
System notice text content
```

## WebSocket Communication

### Connection
- **URL**: `wss://secretari.leither.uk/secretari/ws/?token={access_token}`
- **Protocol**: WebSocket with JSON message format
- **Authentication**: Token passed as query parameter

### Message Format

#### Outgoing Messages (Client to Server)
```json
{
  "input": {
    "prompt": "AI prompt text",
    "prompt_type": "summary|memo|subscription",
    "rawtext": "transcribed text to process",
    "subscription": true|false
  },
  "parameters": {
    "llm": "model_name",
    "temperature": 0.7
  }
}
```

#### Incoming Messages (Server to Client)

##### Result Type
```json
{
  "type": "result",
  "answer": "AI generated content",
  "cost": 0.05,
  "tokens": 150,
  "eof": true|false
}
```

##### Stream Type
```json
{
  "type": "stream",
  "data": "partial AI response chunk"
}
```

##### Error Type
```json
{
  "type": "error",
  "message": "Error description"
}
```

### WebSocket Usage in App

#### Sending AI Processing Request
```swift
websocket.sendToAI(rawText: transcript, prompt: customPrompt) { summary in
    // Handle AI response
    audioRecord.resultFromAI(taskType: .summarize, summary: summary)
}
```

#### Handling Responses
```swift
// Stream responses for real-time feedback
case "stream":
    if let data = dict["data"] as? String {
        self.streamedText += data
    }

// Final results
case "result":
    if let answer = dict["answer"] as? String {
        // Process final AI result
    }
    
    // Update user balance
    if let cost = dict["cost"] as? Double, let tokens = dict["tokens"] as? UInt {
        userManager.currentUser?.dollar_balance -= cost
        userManager.currentUser?.token_count += tokens
    }
```

## Error Handling

### HTTP Status Codes
- **200**: Success
- **201**: Created (for new resources)
- **400**: Bad Request
- **401**: Unauthorized
- **404**: Not Found
- **500**: Internal Server Error

### Error Response Format
```json
{
  "error": "error_code",
  "message": "Human readable error message",
  "details": "Additional error details"
}
```

### Common Error Scenarios
1. **Invalid Credentials**: 401 response during login
2. **Network Timeout**: WebSocket connection failures
3. **Insufficient Balance**: User lacks funds for AI processing
4. **Invalid Token**: Expired or malformed JWT tokens

## Rate Limiting

The API implements rate limiting to prevent abuse:
- **Speech Processing**: Limited by user balance/token count
- **Authentication**: Standard rate limiting on login attempts
- **WebSocket**: Connection limits per user

## Data Models

### User Balance Tracking
```json
{
  "dollar_balance": 10.50,
  "token_count": 1500,
  "monthly_usage": {
    "1": 5.25,
    "2": 3.10,
    // ... monthly usage by month number
  }
}
```

### AI Processing Parameters
- **LLM Models**: Configurable via settings
- **Temperature**: Controls AI creativity (0.0-1.0)
- **Prompt Types**: 
  - `summary`: General summary generation
  - `memo`: Actionable checklist creation
  - `subscription`: Premium feature prompts

## Security Considerations

### Data Protection
- All communication uses HTTPS/WSS encryption
- Sensitive data (passwords, tokens) never logged
- User data encrypted in transit
- No audio data transmitted (only text)

### Authentication Security
- JWT tokens with expiration
- Secure token storage in iOS Keychain
- Automatic token refresh handling
- Session management

### Privacy
- No audio recording or storage
- Only transcribed text sent to servers
- User data anonymized where possible
- GDPR compliance considerations

## Usage Examples

### Complete AI Processing Flow
1. User completes speech recognition
2. App sends transcript via WebSocket:
```json
{
  "input": {
    "prompt": "Summarize this meeting",
    "prompt_type": "summary",
    "rawtext": "Meeting transcript...",
    "subscription": true
  },
  "parameters": {
    "llm": "gpt-4",
    "temperature": 0.7
  }
}
```
3. Server streams response chunks
4. Final result updates user balance
5. App stores result locally

### User Registration Flow
1. Generate device UUID
2. Create temporary user account
3. Allow limited usage with bonus balance
4. Prompt for full registration when balance exhausted
5. Migrate data to full account upon registration

## Troubleshooting

### Common Issues
1. **WebSocket Connection Fails**: Check network connectivity and token validity
2. **AI Processing Errors**: Verify user balance and prompt format
3. **Authentication Issues**: Ensure token is valid and not expired
4. **Product Loading Fails**: Check network connection and server status

### Debug Information
- Enable verbose logging in development builds
- Monitor WebSocket message flow
- Track user balance changes
- Log authentication token status
