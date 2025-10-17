# Secretari Backend Server

Python backend server for the Secretari iOS application.

## Features

- WebSocket communication for real-time AI processing
- User authentication and account management
- AI integration for speech summarization and memo generation
- In-app purchase verification
- Multi-language support

## Setup

1. Create virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Configure environment variables (see `.env.example`)

4. Run the server:
```bash
python app.py
```

## Project Structure

```
server/
├── app.py                 # Main application entry point
├── requirements.txt       # Python dependencies
├── .env.example          # Environment variables template
├── config/               # Configuration files
├── models/               # Data models
├── routes/               # API routes
├── services/             # Business logic
├── utils/                # Utility functions
└── tests/                # Test files
```

## API Endpoints

- `POST /secretari/token` - User authentication
- `POST /secretari/users/register` - User registration
- `PUT /secretari/users` - Update user profile
- `DELETE /secretari/users` - Delete user account
- `POST /secretari/users/temp` - Create temporary user
- `GET /secretari/productids` - Get in-app purchase products
- `GET /secretari/notice` - Get system notices
- `WSS /secretari/ws/` - WebSocket for AI processing

## Environment Variables

Copy `.env.example` to `.env` and configure:

```
DATABASE_URL=sqlite:///secretari.db
OPENAI_API_KEY=your_openai_api_key
JWT_SECRET_KEY=your_jwt_secret
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

## Development

The server is designed to work with the Secretari iOS app at `secretari.leither.uk`.
