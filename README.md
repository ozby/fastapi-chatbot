# Ozby's Chatbot

A modern, intelligent chatbot built with FastAPI and modern AI technologies.

## Features

- ⚡️ Fully async architecture
- 🤖 AI-powered responses
- 🔐 Secure authentication
- 🏬 Redis caching
- 🚦 Task queue with ARQ
- 🚚 Easy deployment with Docker
- ⚖️ NGINX for production
- ✅ Code quality checks with pre-commit hooks

## Prerequisites

- Docker and Docker Compose
- Git
- Python 3.8+ (for pre-commit hooks)

## Quick Start

1. Clone the repository:

```bash
git clone https://github.com/yourusername/ozbys-chatbot.git
cd ozbys-chatbot
```

2. Make the run script executable:

```bash
chmod +x run.sh
```

3. Set up pre-commit hooks (optional but recommended):

```bash
./setup-hooks.sh
```

## Available Commands

The project includes a convenient `run.sh` script for managing the application:

```bash
./run.sh [command]
```

Available commands:

- `start` - Start the application
- `stop` - Stop the application
- `restart` - Restart the application
- `logs` - Show application logs
- `rebuild` - Rebuild and restart the application (removes all volumes)
- `help` - Show this help message

## Code Quality

This project uses pre-commit hooks to ensure code quality. The following checks are performed before each commit:

- Code formatting (Black)
- Import sorting (isort)
- Code style (flake8)
- Type checking (mypy)
- YAML validation
- JSON validation
- Merge conflict detection
- Private key detection
- Large file detection

To set up the pre-commit hooks:

```bash
./setup-hooks.sh
```

To manually run the checks:

```bash
pre-commit run --all-files
```

## Environment Variables

The application requires a `.env` file in the `src` directory. The following variables are required:

```env
# App Settings
APP_NAME="Ozby's Chatbot"
APP_DESCRIPTION="An intelligent chatbot powered by FastAPI and modern AI"
APP_VERSION="0.1"
CONTACT_NAME="Ozby"
CONTACT_EMAIL="ozby@example.com"
LICENSE_NAME="MIT"

# Database
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="postgres"
POSTGRES_SERVER="db"
POSTGRES_PORT=5432
POSTGRES_DB="fastapi_chatbot"

# PGAdmin
PGADMIN_DEFAULT_EMAIL="admin@example.com"
PGADMIN_DEFAULT_PASSWORD="admin"
PGADMIN_LISTEN_PORT=80

# Security
SECRET_KEY="your-secret-key"  # Generate with: openssl rand -hex 32
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Admin User
ADMIN_NAME="Admin User"
ADMIN_EMAIL="admin@example.com"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"

# Redis
REDIS_CACHE_HOST="redis"
REDIS_CACHE_PORT=6379
CLIENT_CACHE_MAX_AGE=30
REDIS_QUEUE_HOST="redis"
REDIS_QUEUE_PORT=6379
```

## Development

1. Start the application:

```bash
./run.sh start
```

2. Access the API at http://localhost:8000
1. Access the API documentation at http://localhost:8000/docs

## Production Deployment

For production deployment, ensure:

1. All sensitive credentials are properly secured
1. Use separate Redis instances for caching and queue
1. Configure proper SSL/TLS certificates
1. Set up proper monitoring and logging

## License

MIT License
