# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- **Development server**: `yarn dev` - Start Medusa development server
- **Build**: `yarn build` - Build the application 
- **Production server**: `yarn start` - Start production server
- **Database migrations**: `npx medusa db:migrate` - Apply database migrations
- **Database seeding**: `yarn seed` - Seed database with initial data

## Testing Commands

- **Unit tests**: `yarn test:unit` - Run unit tests
- **Integration tests (HTTP)**: `yarn test:integration:http` - Test API endpoints
- **Integration tests (Modules)**: `yarn test:integration:modules` - Test module integration

## Environment Setup

### Local Development
1. PostgreSQL is already installed locally
2. Database: `gottofrotto_dev` (already exists and migrated)
3. Run `yarn dev` to start development server
4. Admin UI: http://localhost:9000/app

### Production Deployment (Neon Database)
- Uses Neon PostgreSQL database with SSL configuration
- Environment variables set in DigitalOcean:
  - `DATABASE_URL` (with ?sslmode=require)
  - `NODE_ENV=production`
  - CORS settings for store/admin
- SSL handled automatically in production
- App binds to PORT environment variable (set by DigitalOcean)

## Architecture Overview

This is a clean Medusa v2 e-commerce backend application with:
- PostgreSQL database (local: gottofrotto_dev, production: Neon)
- Default Medusa v2 configuration
- SSL support for production
- Admin dashboard built-in
- REST APIs for store and admin operations

### Key Features
- **Store API**: `/store/*` - Customer-facing e-commerce endpoints
- **Admin API**: `/admin/*` - Management and dashboard endpoints  
- **Admin UI**: `/app` - Built-in admin dashboard
- **Database**: Automatic migrations and schema management
- **Authentication**: JWT-based auth with secure cookies