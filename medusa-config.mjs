import { loadEnv, defineConfig } from "@medusajs/framework/utils"

loadEnv(process.env.NODE_ENV || "development", process.cwd())

export default defineConfig({
  admin: {
    path: "/app",
    disable: false
  },
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL,
    databaseDriverOptions: process.env.DATABASE_URL?.includes("sslmode=require")
      ? {
          connection: {
            ssl: { rejectUnauthorized: true }
          }
        }
      : {},
    http: {
      storeCors: process.env.STORE_CORS,
      adminCors: process.env.ADMIN_CORS,
      authCors: process.env.AUTH_CORS,
      jwtSecret: process.env.JWT_SECRET || (process.env.NODE_ENV !== "production" ? "supersecret" : undefined),
      cookieSecret: process.env.COOKIE_SECRET || (process.env.NODE_ENV !== "production" ? "supersecret" : undefined)
    }
  },
  modules: {
    notification: {
      resolve: "@medusajs/notification",
      options: {
        providers: [
          {
            id: "resend",
            resolve: "./src/modules/notification/providers/resend",
            options: {
              api_key: process.env.RESEND_API_KEY,
              from: process.env.RESEND_FROM || "onboarding@resend.dev",
              channels: ["email"],
            },
          }
        ]
      }
    }
  }
})
