# Changelog

All notable changes to the Secretari (Bounny) project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive project documentation
- Architecture documentation
- API documentation
- Setup and development guide
- User guide
- Changelog

### Development Features
- Temporary balance check bypass for testing
- High balance testing function in UserManager
- Debug UI controls in Settings for testing
- Testing configuration documentation

## [1.0.4] - Current Version

### Features
- AI-powered speech recognition and transcription
- Multi-language support (6 languages)
- Real-time speech-to-text conversion
- AI-generated summaries and actionable checklists
- In-app purchase system with subscriptions
- User account management and authentication
- Local data persistence with SwiftData
- WebSocket communication with backend AI services

### Technical Implementation
- SwiftUI-based user interface
- SwiftData for local data storage
- Apple Speech Framework integration
- StoreKit 2 for in-app purchases
- WebSocket communication for real-time AI processing
- JWT token-based authentication
- Keychain storage for sensitive data
- Multi-language localization support

### Supported Platforms
- iOS 17.0+
- iPhone and iPad compatibility
- Universal app design

### Languages Supported
- English (en-US)
- Spanish - Latin America (es-419)
- Chinese Simplified (zh-Hans)
- Chinese Traditional (zh-Hant)
- Japanese (ja)
- Korean (ko)

## [Previous Versions]

### Version History
- **1.0.0**: Initial release with basic speech recognition
- **1.0.1**: Added AI processing capabilities
- **1.0.2**: Implemented user account system
- **1.0.3**: Added in-app purchases and subscriptions
- **1.0.4**: Enhanced UI and multi-language support

## Development Notes

### Architecture Decisions
- Chose SwiftUI over UIKit for modern iOS development
- Implemented SwiftData for robust local data persistence
- Used WebSocket for real-time AI communication
- Adopted StoreKit 2 for modern in-app purchase handling

### Security Considerations
- No audio recording or storage
- Encrypted communication with backend
- Secure token storage in iOS Keychain
- Privacy-focused design

### Performance Optimizations
- Efficient speech recognition with minimal battery impact
- Optimized WebSocket communication
- Smart caching of user data
- Background processing for AI requests

## Known Issues

### Current Limitations
- Requires internet connection for AI processing
- Speech recognition accuracy varies by language
- Limited offline functionality
- No audio playback of recordings

### Planned Improvements
- Enhanced offline capabilities
- Additional language support
- Improved AI processing options
- Data export functionality
- Cloud synchronization

## Contributing

### Development Setup
1. Follow the setup guide in `docs/SETUP.md`
2. Ensure iOS 17.0+ development environment
3. Configure backend endpoints for testing
4. Set up StoreKit testing environment

### Code Standards
- Follow Swift coding conventions
- Use SwiftUI best practices
- Implement proper error handling
- Include comprehensive documentation

### Testing Requirements
- Test on multiple iOS versions
- Verify all supported languages
- Test in-app purchase flow
- Validate speech recognition accuracy

## Support

### Contact Information
- **Email**: service@leither.uk
- **Website**: [Project Website]
- **Documentation**: See `docs/` folder for detailed guides

### Bug Reports
When reporting bugs, please include:
- iOS version and device model
- App version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

### Feature Requests
For feature requests, please provide:
- Detailed description of the feature
- Use case and benefits
- Any relevant mockups or examples
- Priority level

## License

This project is proprietary software. See the main project license for details.

---

*This changelog is maintained as part of the project documentation and should be updated with each release.*
