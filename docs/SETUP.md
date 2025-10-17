# Secretari Development Setup Guide

This guide covers the setup and development environment configuration for the Secretari iOS application.

## Prerequisites

### Development Environment
- **macOS**: Latest version recommended
- **Xcode**: Version 15.0 or later
- **iOS Deployment Target**: iOS 17.0+
- **Swift**: Version 5.9+

### Apple Developer Account
- Active Apple Developer Program membership
- App Store Connect access for testing and distribution
- Certificates and provisioning profiles configured

### Required Frameworks & Services
- **Speech Framework**: For speech recognition
- **AVFoundation**: For audio processing
- **StoreKit**: For in-app purchases
- **SwiftData**: For data persistence
- **WebSocket**: For backend communication

## Project Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd Secretari
```

### 2. Open in Xcode
```bash
open Secretari.xcodeproj
```

### 3. Configure Bundle Identifier
Update the bundle identifier in project settings:
- **Current**: `secretari.leither.uk`
- **Development**: Use your own identifier (e.g., `com.yourcompany.secretari.dev`)

### 4. Configure Team and Signing
1. Select the project in Xcode navigator
2. Go to "Signing & Capabilities"
3. Select your development team
4. Enable "Automatically manage signing"
5. Verify bundle identifier is unique

## Configuration

### 1. Backend Configuration

#### Update API Endpoints
If using a different backend server, update the URLs in `Websocket.swift`:

```swift
private func configureURLs() {
    webURL.scheme = "https"
    webURL.host = "your-backend-domain.com"  // Update this
    wsURL.scheme = "wss"
    wsURL.host = "your-backend-domain.com"   // Update this
}
```

#### API Keys and Secrets
- Backend API keys should be configured server-side
- No hardcoded secrets in the iOS app
- Authentication handled via JWT tokens

### 2. Speech Recognition Setup

#### Privacy Permissions
Ensure the following permissions are configured in `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Use microphone to recognize user speech. The app does not record anything.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Generate transcript of user speech and create summary of it with OpenAI.</string>
```

#### Supported Languages
The app supports the following languages for speech recognition:
- English (en-US)
- Spanish (es-419)
- Chinese Simplified (zh-Hans)
- Chinese Traditional (zh-Hant)
- Japanese (ja)
- Korean (ko)

### 3. In-App Purchase Configuration

#### StoreKit Configuration
1. Create a `StoreKit` configuration file in Xcode
2. Add your product IDs:
   - `890842` (Consumable)
   - `Yearly.bunny0` (Annual subscription)
   - `monthly.bunny0` (Monthly subscription)

#### App Store Connect Setup
1. Create your app in App Store Connect
2. Configure in-app purchases:
   - Set up subscription groups
   - Configure pricing tiers
   - Add product descriptions and screenshots

#### Testing
- Use StoreKit testing in Xcode for development
- Test with sandbox Apple ID accounts
- Verify receipt validation on backend

### 4. Data Persistence Setup

#### SwiftData Models
The app uses SwiftData for local storage. Models are defined in:
- `AudioRecord.swift`: Main data model
- `Item.swift`: Additional data model
- `User.swift`: User account data

#### Database Schema
```swift
let schema = Schema([AudioRecord.self, Item.self])
let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
```

## Development Workflow

### 1. Running the App

#### Simulator
```bash
# Select target device in Xcode
# Press Cmd+R to build and run
```

#### Physical Device
1. Connect iOS device via USB
2. Trust the developer certificate on device
3. Select device as target in Xcode
4. Build and run

### 2. Debugging

#### Speech Recognition Issues
- Test with different languages
- Verify microphone permissions
- Check audio session configuration
- Monitor speech recognition errors

#### Network Issues
- Enable network logging
- Test WebSocket connections
- Verify backend server status
- Check authentication tokens

#### Data Persistence Issues
- Monitor SwiftData operations
- Check model relationships
- Verify data migrations
- Test on device vs simulator

### 3. Testing

#### Unit Tests
```bash
# Run unit tests
Cmd+U in Xcode
```

#### UI Tests
```bash
# Run UI tests
Cmd+U in Xcode (with UI test target selected)
```

#### Manual Testing Checklist
- [ ] Speech recognition in all supported languages
- [ ] AI processing and response handling
- [ ] User registration and login
- [ ] In-app purchase flow
- [ ] Data persistence and retrieval
- [ ] Settings and preferences
- [ ] Error handling and recovery

## Build Configuration

### 1. Debug Configuration
- Enable debug logging
- Use development backend URLs
- Include debug symbols
- Enable runtime checks

### 2. Release Configuration
- Disable debug logging
- Use production backend URLs
- Optimize for size and performance
- Enable App Store compliance

### 3. Archive Configuration
```bash
# Create archive for distribution
Product → Archive in Xcode
```

## Deployment

### 1. TestFlight Distribution
1. Archive the app in Xcode
2. Upload to App Store Connect
3. Configure TestFlight testing
4. Invite beta testers

### 2. App Store Submission
1. Complete app metadata in App Store Connect
2. Add screenshots and app preview
3. Submit for review
4. Monitor review status

### 3. Release Management
- Use semantic versioning
- Update version numbers in project settings
- Tag releases in Git
- Maintain release notes

## Testing Configuration

### Temporarily Disable Balance Checks
For development and testing purposes, you may need to disable account balance checks:

#### Client-Side Balance Check Disabled
- **File**: `Secretari/View/Settings/SettingsView.swift`
- **Function**: `allowedPromptType()` - Always returns `false` to allow all prompt types
- **Purpose**: Removes client-side restrictions for users with low balance

#### High Balance Testing Function
- **File**: `Secretari/Utilities/UserManager.swift`
- **Function**: `setHighBalanceForTesting()` - Sets user balance to $1000.00
- **Usage**: Call this method to give test users sufficient balance

#### Debug UI Controls
- **Location**: Settings → "DEBUG - Testing Only" section
- **Features**:
  - "Set High Balance for Testing" button
  - Current balance display
- **Purpose**: Easy access to testing controls from within the app

#### To Re-enable Balance Checks
1. Uncomment the balance check code in `allowedPromptType()` function
2. Remove the debug section from SettingsView
3. Remove the `setHighBalanceForTesting()` method from UserManager

**Note**: These are temporary changes marked with "TEMPORARY" or "DEBUG" comments.

## Troubleshooting

### Common Build Issues

#### Code Signing Errors
```
Solution: Check team selection and provisioning profiles
```

#### Missing Frameworks
```
Solution: Ensure all required frameworks are linked
```

#### Deployment Target Issues
```
Solution: Verify iOS 17.0+ deployment target
```

### Runtime Issues

#### Speech Recognition Fails
- Check microphone permissions
- Verify language settings
- Test with different devices
- Check audio session conflicts

#### WebSocket Connection Issues
- Verify network connectivity
- Check backend server status
- Validate authentication tokens
- Monitor connection logs

#### Data Persistence Problems
- Check SwiftData model definitions
- Verify database migrations
- Test data retrieval operations
- Monitor memory usage

### Performance Issues

#### Memory Leaks
- Use Instruments to profile memory usage
- Check for retain cycles in closures
- Monitor SwiftData operations
- Verify proper cleanup of resources

#### Slow Speech Recognition
- Optimize audio session configuration
- Check device performance
- Monitor background processes
- Test with different audio qualities

## Environment Variables

### Development
```bash
# Backend URLs
BACKEND_URL=https://dev.secretari.leither.uk
WEBSOCKET_URL=wss://dev.secretari.leither.uk

# Logging
DEBUG_LOGGING=true
VERBOSE_NETWORK_LOGGING=true
```

### Production
```bash
# Backend URLs
BACKEND_URL=https://secretari.leither.uk
WEBSOCKET_URL=wss://secretari.leither.uk

# Logging
DEBUG_LOGGING=false
VERBOSE_NETWORK_LOGGING=false
```

## Security Considerations

### Code Signing
- Use proper certificates and provisioning profiles
- Enable App Transport Security (ATS)
- Validate all network connections

### Data Protection
- Store sensitive data in Keychain
- Use secure communication protocols
- Implement proper authentication

### Privacy Compliance
- Include privacy policy
- Implement data deletion features
- Follow App Store privacy guidelines

## Support and Resources

### Documentation
- [Apple Speech Framework Documentation](https://developer.apple.com/documentation/speech)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)

### Community
- iOS Developer Forums
- SwiftUI Community
- Speech Recognition Best Practices

### Contact
- Development Team: [Contact Information]
- Backend Support: service@leither.uk
- Technical Issues: [Support Channel]
