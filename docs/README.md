# Secretari (Bounny) - AI Personal Assistant

An AI-powered personal assistant that listens to your speech and creates intelligent memos and summaries to help you remember what you said.

## Overview

Secretari (branded as "Bounny") is a productivity app designed for busy professionals who give many instructions and need to track their conversations and decisions. The app uses advanced speech recognition and AI to automatically transcribe your speech and generate helpful summaries or actionable checklists.

### Key Features

- **Real-time Speech Recognition**: Uses Apple's SFSpeechRecognizer for accurate transcription
- **AI-Powered Summaries**: Generates intelligent summaries and actionable checklists
- **Multi-language Support**: Supports English, Spanish, Chinese (Simplified & Traditional), Japanese, and Korean
- **In-App Purchases**: Subscription and one-time purchase options for premium features
- **User Account Management**: Registration, login, and account management
- **Cloud Integration**: WebSocket-based communication with backend AI services
- **Local Data Storage**: SwiftData for persistent local storage of records

## Target Users

- Business managers and executives
- Project managers
- Anyone who gives frequent instructions and needs to track conversations
- People who want an AI assistant to help organize their thoughts and decisions

## App Architecture

The app follows a clean SwiftUI architecture with the following main components:

### Core Models
- **AudioRecord**: Main data model for storing transcription and AI-generated content
- **User**: User account information and balance tracking
- **SpeechRecognizer**: Handles speech-to-text conversion
- **Websocket**: Manages communication with backend AI services

### Key Managers
- **UserManager**: Handles user authentication and account management
- **SubscriptionsManager**: Manages in-app purchases and subscriptions
- **EntitlementManager**: Controls access to premium features
- **SettingsManager**: Manages app settings and preferences

### Views
- **ContentView**: Main interface showing list of records
- **DetailView**: Detailed view for individual records with transcription and AI summaries
- **SettingsView**: App configuration and preferences
- **PurchaseView**: In-app purchase interface

## Technical Stack

- **Framework**: SwiftUI with SwiftData
- **Minimum iOS Version**: iOS 17.0
- **Speech Recognition**: Apple Speech Framework
- **Data Persistence**: SwiftData
- **Networking**: URLSession with WebSocket support
- **In-App Purchases**: StoreKit 2
- **Localization**: Multi-language support for 6 languages

## Backend Integration

The app communicates with a backend service at `secretari.leither.uk` that provides:
- AI processing for summarization and memo generation
- User account management
- Subscription verification
- Product information for in-app purchases

## Privacy & Permissions

The app requires:
- **Microphone Access**: For speech recognition
- **Speech Recognition Permission**: For converting speech to text

**Important**: The app does not record audio - it only processes speech in real-time for transcription.

## Getting Started

1. **Language Setup**: First, configure your preferred language in Settings for accurate speech recognition
2. **Permissions**: Grant microphone and speech recognition permissions when prompted
3. **Start Recording**: Tap the "Start" button to begin speech recognition
4. **Stop Recording**: Tap "Stop" to end the session and generate AI summaries


## Support

For help and support, contact: service@leither.uk

## License

This is a commercial iOS application. See the app store for licensing terms.
