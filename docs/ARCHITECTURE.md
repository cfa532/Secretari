# Secretari App Architecture

This document describes the technical architecture and component structure of the Secretari iOS application.

## Overview

Secretari is built using SwiftUI with a clean, modular architecture that separates concerns across different layers. The app follows MVVM patterns with additional manager classes for specific functionality.

## Architecture Layers

### 1. Presentation Layer (SwiftUI Views)

#### Main Views
- **`ContentView`**: Entry point showing list of audio records
- **`DetailView`**: Detailed view for individual records with transcription and AI processing
- **`SettingsView`**: App configuration and preferences
- **`AccountView`**: User account management
- **`LoginView`**: User authentication
- **`RegistrationView`**: New user registration
- **`StoreFrontView`**: In-app purchase interface

#### Component Views
Located in `Components/` directory:
- **`CheckboxView`**: Custom checkbox component for memo items
- **`DotAnimationView`**: Loading animation indicator
- **`InputView`**: Reusable input field component
- **`LocalePicker`**: Language selection picker
- **`RecorderButton`**: Custom recording button with visual feedback
- **`SettingsRowView`**: Standardized settings row layout
- **`SummaryRowView`**: Display component for audio record summaries

### 2. Business Logic Layer (Managers)

#### Core Managers
- **`UserManager`**: 
  - User authentication and session management
  - Account balance tracking
  - User data persistence
  - Login status management

- **`SubscriptionsManager`**: 
  - StoreKit 2 integration
  - In-app purchase handling
  - Subscription verification
  - Product loading and management

- **`EntitlementManager`**: 
  - Premium feature access control
  - Subscription status validation

- **`SettingsManager`**: 
  - App preferences management
  - Language settings
  - AI prompt configuration
  - LLM parameter settings

#### Utility Managers
- **`KeychainManager`**: Secure storage for sensitive data
- **`UserDefaultsManager`**: Standard preferences storage
- **`IdentifierManager`**: Device identifier management

### 3. Data Layer

#### Models
- **`AudioRecord`**: 
  - Main data model using SwiftData
  - Stores transcription, summaries, and memos
  - Handles AI result processing
  - Supports multiple languages

- **`User`**: 
  - User account information
  - Balance and usage tracking
  - Profile data

- **`Item`**: Additional data model (usage unclear from current codebase)

#### Data Persistence
- **SwiftData**: Primary data persistence solution
- **Keychain**: Secure storage for tokens and sensitive data
- **UserDefaults**: App preferences and settings

### 4. Service Layer

#### Speech Recognition
- **`SpeechRecognizer`**: 
  - Apple Speech Framework integration
  - Real-time speech-to-text conversion
  - Audio level monitoring
  - Error handling and permissions

#### Networking
- **`Websocket`**: 
  - WebSocket communication with backend
  - AI service integration
  - Real-time streaming responses
  - User account API calls
  - Product information retrieval

#### Audio Processing
- **`RecorderTimer`**: Audio recording timing and management
- **`AudioRecord`**: Audio data model and processing

### 5. Error Handling

#### Error Management
- **`ErrorWrapper`**: Generic error handling wrapper
- **`APError`**: API-specific error types
- **`Alert`**: User-facing error display system

## Data Flow

### Speech Recognition Flow
1. User taps "Start" button
2. `SpeechRecognizer.setup()` initializes with selected locale
3. `SpeechRecognizer.startTranscribing()` begins audio capture
4. Real-time transcription updates `transcript` property
5. User taps "Stop" to end session
6. `AudioRecord` is created with transcription data

### AI Processing Flow
1. User initiates AI processing from `DetailView`
2. `Websocket.sendToAI()` sends transcription to backend
3. Backend processes with AI and streams response
4. Response is parsed and stored in `AudioRecord`
5. UI updates with AI-generated content

### User Authentication Flow
1. User enters credentials in `LoginView`
2. `Websocket.fetchToken()` authenticates with backend
3. Token stored securely in Keychain
4. `UserManager` updates login status
5. User data loaded and cached locally

## Key Design Patterns

### 1. MVVM (Model-View-ViewModel)
- Views are purely presentational
- Business logic contained in manager classes
- Models represent data structures

### 2. Singleton Pattern
- `UserManager.shared`
- `Websocket.shared`
- `KeychainManager.shared`

### 3. Observer Pattern
- `@Published` properties for reactive UI updates
- `@ObservableObject` for state management

### 4. Actor Pattern
- `SpeechRecognizer` uses actor for thread-safe speech processing

## Security Considerations

### Data Protection
- Sensitive data (tokens, passwords) stored in Keychain
- User data encrypted in transit via HTTPS/WSS
- No audio recording - only real-time processing

### Authentication
- JWT token-based authentication
- Automatic token refresh handling
- Secure credential storage

## Performance Optimizations

### Memory Management
- Weak references in closures to prevent retain cycles
- Proper cleanup of audio resources
- Efficient data model design with SwiftData

### Network Optimization
- WebSocket for real-time communication
- Efficient JSON serialization
- Background task handling for long operations

## Localization

### Multi-language Support
- 6 supported languages: English, Spanish, Chinese (Simplified & Traditional), Japanese, Korean
- Localized strings in `.lproj` directories
- Dynamic language switching
- AI prompts localized per language

## Dependencies

### Apple Frameworks
- **SwiftUI**: UI framework
- **SwiftData**: Data persistence
- **Speech**: Speech recognition
- **AVFoundation**: Audio processing
- **StoreKit**: In-app purchases
- **Security**: Keychain access

### External Services
- Backend AI service at `secretari.leither.uk`
- WebSocket communication for real-time AI processing
- HTTP APIs for user management and product information

## Future Considerations

### Scalability
- Modular architecture supports easy feature additions
- Manager pattern allows for easy testing and mocking
- Clean separation enables independent component updates

### Maintainability
- Clear naming conventions
- Comprehensive error handling
- Well-documented public interfaces
- Consistent code organization
