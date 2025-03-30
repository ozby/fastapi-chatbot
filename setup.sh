#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}[Setup]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Success]${NC} $1"
}

# Check if .env file exists and if PINECONE_ENDPOINT is already set
PINECONE_ENDPOINT=""
if [ -f src/.env ] && grep -q "PINECONE_ENDPOINT=" src/.env; then
    PINECONE_ENDPOINT=$(grep "PINECONE_ENDPOINT=" src/.env | cut -d'"' -f2)
    print_message "PINECONE_ENDPOINT already set to: $PINECONE_ENDPOINT"
else
    # Ask user for Pinecone endpoint
    print_message "Please enter your Pinecone endpoint:"
    read -p "PINECONE_ENDPOINT: " PINECONE_ENDPOINT
fi

# Check if PINECONE_TOKEN is already set
PINECONE_TOKEN=""
if [ -f src/.env ] && grep -q "PINECONE_TOKEN=" src/.env; then
    PINECONE_TOKEN=$(grep "PINECONE_TOKEN=" src/.env | cut -d'"' -f2)
    print_message "PINECONE_TOKEN already set"
else
    # Ask user for Pinecone token
    print_message "Please enter your Pinecone token:"
    read -p "PINECONE_TOKEN: " PINECONE_TOKEN
fi

# Check if .env file exists in src directory and create it if it doesn't
if [ ! -f src/.env ]; then
    print_message "Creating .env file in src directory..."
    cat > src/.env << EOF
# App Settings
APP_NAME="Ozby's Chatbot"
APP_DESCRIPTION="An intelligent chatbot powered by FastAPI and modern AI"
APP_VERSION="0.1"
CONTACT_NAME="Ozberk Ercin"
CONTACT_EMAIL="ozberk@gmail.com"
LICENSE_NAME="MIT"

# Database
POSTGRES_USER="postgres"
POSTGRES_PASSWORD="postgres"
POSTGRES_SERVER="localhost"
POSTGRES_PORT=5432
POSTGRES_DB="fastapi_chatbot"

# PGAdmin
PGADMIN_DEFAULT_EMAIL="ozberk@gmail.com"
PGADMIN_DEFAULT_PASSWORD="admin"
PGADMIN_LISTEN_PORT=80

# Security
SECRET_KEY="$(openssl rand -hex 32)"
ALGORITHM="HS256"
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Admin User
ADMIN_NAME="Admin User"
ADMIN_EMAIL="ozberk@gmail.com"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"

# Redis
REDIS_CACHE_HOST="localhost"
REDIS_CACHE_PORT=6379
CLIENT_CACHE_MAX_AGE=30
REDIS_QUEUE_HOST="localhost"
REDIS_QUEUE_PORT=6379

# Pinecone Vector Database
PINECONE_ENDPOINT="${PINECONE_ENDPOINT}"
PINECONE_TOKEN="${PINECONE_TOKEN}"
EOF
    print_success ".env file created successfully in src directory!"
else
    print_message ".env file already exists in src directory. Adding/updating Pinecone credentials..."
    # Append Pinecone credentials to existing .env file if they don't exist
    if ! grep -q "PINECONE_ENDPOINT" src/.env; then
        echo "" >> src/.env
        echo "# Pinecone Vector Database" >> src/.env
        echo "PINECONE_ENDPOINT=\"${PINECONE_ENDPOINT}\"" >> src/.env
        echo "PINECONE_TOKEN=\"${PINECONE_TOKEN}\"" >> src/.env
        print_success "Pinecone credentials added to existing .env file!"
    else
        print_message "Pinecone credentials already exist in .env file, updating values..."
        sed -i "s|PINECONE_ENDPOINT=.*|PINECONE_ENDPOINT=\"${PINECONE_ENDPOINT}\"|g" src/.env
        sed -i "s|PINECONE_TOKEN=.*|PINECONE_TOKEN=\"${PINECONE_TOKEN}\"|g" src/.env
        print_success "Pinecone credentials updated in .env file!"
    fi
fi

# Create Python virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    print_message "Creating Python virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created successfully!"
else
    print_message "Virtual environment already exists, skipping creation."
fi

print_message "Activating virtual environment..."
source venv/bin/activate
print_success "Virtual environment activated!"

print_message "Installing dependencies and pre-commit hooks..."

# Install poetry if not already installed
if ! command -v poetry &> /dev/null; then
    print_message "Installing poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
fi

# Install dependencies including pre-commit
poetry install --with dev

# Install the git hooks
poetry run pre-commit install

# Run pre-commit on all files
poetry run pre-commit run --all-files

print_success "Pre-commit hooks installed successfully!"
