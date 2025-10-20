// medusa-config.js

const { loadEnv, defineConfig } = require("@medusajs/framework/utils");

loadEnv(process.env.NODE_ENV || "development", process.cwd());

module.exports = defineConfig({
  admin: {
    path: "/app",
    disable: false
  },
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL,
    databaseDriverOptions: process.env.NODE_ENV === "production"
      ? {
          connection: {
            ssl: { rejectUnauthorized: false }
          }
        }
      : {},
    http: {
      storeCors: process.env.STORE_CORS,
      adminCors: process.env.ADMIN_CORS,
      authCors: process.env.AUTH_CORS,
      jwtSecret: process.env.JWT_SECRET || "supersecret",
      cookieSecret: process.env.COOKIE_SECRET || "supersecret"
    }
  },
  modules: {
    notification: {
      resolve: "@medusajs/notification",
      options: {
        provider_id: "resend",
        providers: [
          {
            id: "resend",
            resolve: "./src/modules/notification/providers/resend",
            options: {
              api_key: process.env.RESEND_API_KEY,
              from: process.env.RESEND_FROM || "onboarding@resend.dev",
              channels: ["email"]
            }
          }
        ]
      }
    }
    // Add more modules as needed, in the same object form!
  }
});
