#!/bin/bash
set -e

echo "Starting Medusa server on Digital Ocean..."

# Set environment variables for runtime
export NODE_TLS_REJECT_UNAUTHORIZED=0

echo "Environment configured:"
echo "HOST: 0.0.0.0"
echo "PORT: $PORT"
echo "NODE_ENV: $NODE_ENV"
echo "DATABASE_URL: ${DATABASE_URL:0:50}..." # Only show first 50 chars for security

# Create .env file for Medusa CLI commands since they require it
echo "Creating .env file for Medusa CLI..."
cat > .env << EOF
DATABASE_URL=$DATABASE_URL
JWT_SECRET=$JWT_SECRET
COOKIE_SECRET=$COOKIE_SECRET
NODE_ENV=$NODE_ENV
STORE_CORS=$STORE_CORS
ADMIN_CORS=$ADMIN_CORS
AUTH_CORS=$AUTH_CORS
EOF

# Test database connection with detailed error handling
echo "Testing database connection..."
if ! npx medusa db:create; then
    echo "Warning: Database creation failed or database already exists"
fi

# Always build since files don't persist from build phase to runtime
echo "Building admin dashboard..."
export NODE_OPTIONS='--max-old-space-size=768'
npx medusa build

echo "Verifying build output..."
ls -la .medusa/server/public/admin/ || echo "Admin directory not found after build"

# Run database migrations with detailed error handling
echo "Running database migrations..."
echo "Attempting to create database tables..."

# Try different migration approaches
if ! npx medusa db:migrate; then
    echo "Standard migration failed, trying alternative approaches..."
    
    # Try creating database first
    echo "Trying to create database..."
    npx medusa db:create || true
    
    # Try migration again
    echo "Retrying migration..."
    if ! npx medusa db:migrate; then
        echo "ERROR: All migration attempts failed!"
        echo "Database URL: ${DATABASE_URL:0:50}..."
        echo "Attempting to test database connection..."
        
        # Last resort - try to see what's wrong
        npx medusa db:create || echo "Database creation also failed"
        exit 1
    fi
fi

echo "Migration completed successfully!"

# Seed the database if it's empty (for new Digital Ocean database)
echo "Checking if database needs seeding..."
if ! npx medusa exec --file ./src/scripts/seed.ts; then
    echo "Warning: Seeding failed or database already seeded"
fi

# Start the server with explicit host and port
echo "Starting server on 0.0.0.0:${PORT:-9000}..."
npx medusa start --host 0.0.0.0 --port ${PORT:-9000}