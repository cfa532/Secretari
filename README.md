# Secretari (Bounny) - Full Stack Project

This is the complete Secretari project including both the iOS app and Python backend server.

## Project Structure

```
Secretari/
├── Secretari/                 # iOS app source code
├── server/                    # Python backend server
├── docs/                      # Project documentation
├── Secretari.xcodeproj/       # Xcode project
└── README.md                  # This file
```

## Components

### iOS App
- **Location**: `Secretari/` directory
- **Technology**: SwiftUI + SwiftData
- **Features**: Speech recognition, AI processing, in-app purchases
- **Documentation**: See `docs/` folder for detailed documentation

### Backend Server
- **Location**: `server/` directory  
- **Technology**: Python + FastAPI
- **Features**: WebSocket communication, user management, AI integration
- **Setup**: See `server/README.md` for server setup instructions

## Quick Start

### iOS App Development
1. Open `Secretari.xcodeproj` in Xcode
2. Select your development team
3. Build and run on simulator or device

### Backend Server Development
1. Navigate to `server/` directory
2. Create virtual environment: `python -m venv venv`
3. Activate: `source venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Copy `env.example` to `.env` and configure
6. Run server: `python app.py`

## Documentation

Comprehensive documentation is available in the `docs/` folder:
- `README.md` - Project overview
- `ARCHITECTURE.md` - Technical architecture
- `API.md` - Backend API documentation
- `SETUP.md` - Development setup guide
- `USER_GUIDE.md` - End user documentation

## Support

For help and support, contact: service@leither.uk
