.PHONY: setup dev test lint clean help
.PHONY: backend-install backend-dev backend-test backend-lint
.PHONY: frontend-install frontend-dev frontend-test frontend-lint
.PHONY: db-migrate db-reset db-version

# Default target
.DEFAULT_GOAL := help

## help: Display this help message
help:
	@echo "401kViz - Development Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          Install all dependencies (backend + frontend)"
	@echo ""
	@echo "Development:"
	@echo "  make dev            Run both servers (use separate terminals)"
	@echo "  make backend-dev    Run backend server on port 4567"
	@echo "  make frontend-dev   Run frontend server on port 5173"
	@echo ""
	@echo "Testing:"
	@echo "  make test           Run all tests"
	@echo "  make backend-test   Run backend tests"
	@echo "  make frontend-test  Run frontend tests"
	@echo ""
	@echo "Linting:"
	@echo "  make lint           Run all linters"
	@echo "  make backend-lint   Run rubocop"
	@echo "  make frontend-lint  Run eslint"
	@echo ""
	@echo "Database:"
	@echo "  make db-migrate     Run database migrations"
	@echo "  make db-reset       Reset database and re-migrate"
	@echo "  make db-version     Show current schema version"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean          Clean build artifacts"

## setup: Install all dependencies
setup: backend-install frontend-install
	@echo "✓ Setup complete! Run 'make dev' to start development"

## dev: Show instructions to run both servers
dev:
	@echo "To run the development environment:"
	@echo ""
	@echo "Terminal 1: make backend-dev"
	@echo "Terminal 2: make frontend-dev"
	@echo ""
	@echo "Then visit: http://localhost:5173"

## Backend targets
backend-install:
	@echo "Installing backend dependencies..."
	cd backend && bundle install

backend-dev:
	@echo "Starting backend server on http://localhost:4567"
	cd backend && bundle exec rerun --pattern '**/*.rb' 'rackup -o 0.0.0.0 -p 4567'

backend-test:
	@echo "Running backend tests..."
	cd backend && bundle exec rspec

backend-lint:
	@echo "Running rubocop..."
	cd backend && bundle exec rubocop

backend-lint-fix:
	@echo "Auto-fixing rubocop issues..."
	cd backend && bundle exec rubocop -A

## Frontend targets
frontend-install:
	@echo "Installing frontend dependencies..."
	cd frontend && npm install

frontend-dev:
	@echo "Starting frontend server on http://localhost:5173"
	cd frontend && npm run dev

frontend-test:
	@echo "Frontend tests not yet implemented (Section 11)"

frontend-lint:
	@echo "Running eslint..."
	cd frontend && npm run lint

frontend-lint-fix:
	@echo "Auto-fixing eslint issues..."
	cd frontend && npm run lint -- --fix

## Combined targets
test: backend-test frontend-test

lint: backend-lint frontend-lint

## Database targets
db-migrate:
	@echo "Running database migrations..."
	cd backend && bundle exec rake db:migrate

db-reset:
	@echo "Resetting database..."
	cd backend && bundle exec rake db:reset

db-version:
	@echo "Checking database version..."
	cd backend && bundle exec rake db:version

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf backend/db/*.db
	rm -rf frontend/dist
	rm -rf frontend/node_modules/.vite
	@echo "✓ Clean complete"
