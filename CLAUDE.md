# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- **Development server**: `yarn dev` or `npm run dev` - Start Medusa development server
- **Build**: `yarn build` or `npm run build` - Build the application
- **Production server**: `yarn start` or `npm start` - Start production server
- **Database seeding**: `yarn seed` or `npm run seed` - Seed database with initial data

## Testing Commands

- **Unit tests**: `yarn test:unit` - Run unit tests
- **Integration tests (HTTP)**: `yarn test:integration:http` - Test API endpoints
- **Integration tests (Modules)**: `yarn test:integration:modules` - Test module integration
- **All tests run with Jest in silent mode by default**

## Database Commands

- **Generate migrations**: `npx medusa db:generate [module-name]` - Generate migrations for a module
- **Run migrations**: `npx medusa db:migrate` - Apply database migrations
- **Create local dev database**: `createdb gottofrotto_dev` - Create PostgreSQL development database
- **Connect to local dev database**: `psql -d gottofrotto_dev` - Connect to development database

## Environment Setup

### Local Development (Recommended)
1. Install PostgreSQL locally (already installed via Homebrew)
2. Create development database: `createdb gottofrotto_dev`  
3. Use `DATABASE_URL=postgresql://localhost/gottofrotto_dev` in your .env
4. Run `npm run dev` to start development server

### Production Deployment (DigitalOcean)
- The app uses MikroORM with specialized SSL configuration for DigitalOcean PostgreSQL
- SSL settings are automatically applied in production (NODE_ENV=production)
- Use clean DATABASE_URL format without SSL parameters in environment variables
- SSL configuration is handled in medusa-config.ts with rejectUnauthorized=false

## Architecture Overview

This is a Medusa v2 e-commerce backend application with PostgreSQL database support.

### Core Directory Structure

- **`src/api/`** - Custom API routes using file-based routing
  - Routes are created as `route.ts` files with HTTP method exports (GET, POST, etc.)
  - Path parameters use `[param]` directory naming convention
  - Access Medusa container via `req.scope.resolve()`

- **`src/modules/`** - Custom business logic modules
  - Each module has: data models, service class, and index.ts export
  - Models defined using `model.define()` from Medusa framework
  - Services extend `MedusaService` with model relationships

- **`src/workflows/`** - Multi-step business processes
  - Created using `createStep()` and `createWorkflow()` from workflows-sdk
  - Executed via `.run()` method with input parameters

- **`src/admin/`** - Admin dashboard customizations
- **`src/jobs/`** - Background job definitions  
- **`src/subscribers/`** - Event subscribers
- **`src/scripts/`** - Utility scripts like database seeding

### Configuration

- **`medusa-config.ts`** - Main configuration file
  - Database connection with SSL handling for production
  - Module registration and provider configuration
  - Environment-based conditional loading (DO Spaces, PostHog)

- **Database**: PostgreSQL with MikroORM
- **Analytics**: PostHog integration (configurable)
- **File Storage**: DigitalOcean Spaces (production only, when env vars set)
- **Payment**: Stripe integration available

### Key Integration Points

- **Container Access**: Use `req.scope.resolve("service-name")` in API routes
- **Module Registration**: Add modules to `medusa-config.ts` modules array
- **Workflow Execution**: Import and call workflows with `workflow(req.scope).run()`

### Environment Requirements

- Node.js >= 20
- PostgreSQL database
- Required env vars: `DATABASE_URL`, `JWT_SECRET`, `COOKIE_SECRET`
- CORS configuration: `STORE_CORS`, `ADMIN_CORS`, `AUTH_CORS`