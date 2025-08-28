import { loadEnv, defineConfig } from '@medusajs/framework/utils'

loadEnv(process.env.NODE_ENV || 'development', process.cwd())

module.exports = defineConfig({
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    http: {
      storeCors: process.env.STORE_CORS!,
      adminCors: process.env.ADMIN_CORS!,
      authCors: process.env.AUTH_CORS!,
      jwtSecret: process.env.JWT_SECRET || "supersecret",
      cookieSecret: process.env.COOKIE_SECRET || "supersecret",
    }
  },
  modules: [
    {
      resolve: "@medusajs/medusa/analytics",
      options: {
        providers: [
          {
            resolve: "@medusajs/analytics-posthog",
            id: "posthog",
            options: {
              posthogEventsKey: process.env.POSTHOG_EVENTS_API_KEY,
              posthogHost: process.env.POSTHOG_HOST || "https://app.posthog.com",
            },
          },
        ],
      },
    },
    // Only add DO Spaces in production when environment variables are set
    ...(process.env.DO_SPACES_BUCKET && process.env.DO_SPACES_KEY ? [{
      resolve: "@medusajs/file-s3",
      options: {
        file_url: process.env.DO_SPACES_URL,
        access_key_id: process.env.DO_SPACES_KEY,
        secret_access_key: process.env.DO_SPACES_SECRET,
        region: process.env.DO_SPACES_REGION,
        bucket: process.env.DO_SPACES_BUCKET,
        endpoint: process.env.DO_SPACES_ENDPOINT,
        s3_force_path_style: true,
      },
    }] : []),
  ]
})
