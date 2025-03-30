#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${BLUE}[Ozby's Chatbot]${NC} $1"
}

print_error() {
    echo -e "${RED}[Error]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Success]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to check if required files exist
check_requirements() {
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found!"
        exit 1
    fi
    if [ ! -f "src/.env" ]; then
        print_error "src/.env not found!"
        exit 1
    fi
}

# Function to wait for Redis to be ready
wait_for_redis() {
    local max_attempts=30
    local attempt=1
    local wait_seconds=2

    print_message "Waiting for Redis to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if docker compose exec redis redis-cli ping 2>/dev/null | grep -q 'PONG'; then
            print_success "Redis is ready!"
            return 0
        else
            print_message "Redis not ready yet. Waiting... (Attempt $attempt/$max_attempts)"
            sleep $wait_seconds
            ((attempt++))
        fi
    done

    print_error "Redis did not become ready within the timeout period."
    return 1
}

# Function to wait for database to be ready
wait_for_db() {
    local max_attempts=30
    local attempt=1
    local wait_seconds=2

    print_message "Waiting for database to be ready..."

    while [ $attempt -le $max_attempts ]; do
        if docker compose exec db pg_isready -U postgres 2>/dev/null | grep -q 'accepting connections'; then
            print_success "Database is ready!"
            return 0
        else
            print_message "Database not ready yet. Waiting... (Attempt $attempt/$max_attempts)"
            sleep $wait_seconds
            ((attempt++))
        fi
    done

    print_error "Database did not become ready within the timeout period."
    return 1
}

# Function to start the application
start_app() {
    print_message "Starting Ozby's Chatbot..."
    docker compose up -d

    # Wait for services to be ready
    wait_for_db || { print_error "Failed to start the application due to database timeout."; exit 1; }
    wait_for_redis || { print_error "Failed to start the application due to Redis timeout."; exit 1; }

    # Initialize database tables
    print_message "Creating database tables..."
    docker compose exec web python -c "import asyncio; from app.core.setup import create_tables; asyncio.run(create_tables())"

    print_success "Application started! You can access it at http://localhost:8000"
}

# Function to stop the application
stop_app() {
    print_message "Stopping Ozby's Chatbot..."
    docker compose down
    print_success "Application stopped!"
}

# Function to restart the application
restart_app() {
    stop_app
    start_app
}

# Function to show logs
show_logs() {
    print_message "Showing logs..."
    docker compose logs -f
}

# Function to rebuild the application
rebuild_app() {
    print_message "Rebuilding Ozby's Chatbot..."
    print_message "Stopping containers and removing volumes..."
    docker compose down -v
    print_message "Building fresh images..."
    docker compose build --no-cache
    start_app
}

# Function to run tests
run_tests() {
    print_message "Running tests..."
    wait_for_redis || { print_error "Failed to start the application due to Redis timeout."; exit 1; }
    wait_for_db || { print_error "Failed to start the application due to database timeout."; exit 1; }
    docker compose run --rm pytest

    # Check the exit code
    if [ $? -eq 0 ]; then
        print_success "All tests passed!"
    else
        print_error "Some tests failed."
    fi
}

# Function to show help
show_help() {
    echo "Usage: ./run.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start     Start the application"
    echo "  stop      Stop the application"
    echo "  restart   Restart the application"
    echo "  logs      Show application logs"
    echo "  rebuild   Rebuild and restart the application (removes all volumes)"
    echo "  test      Run tests (optionally specify test path: ./run.sh test tests/test_api.py)"
    echo "  help      Show this help message"
}

# Main script
check_docker
check_requirements

case "$1" in
    "start")
        start_app
        ;;
    "stop")
        stop_app
        ;;
    "restart")
        restart_app
        ;;
    "logs")
        show_logs
        ;;
    "rebuild")
        rebuild_app
        ;;
    "test")
        run_tests "$2"
        ;;
    "help"|"")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
