// medusa-config.js

const { loadEnv, defineConfig } = require("@medusajs/framework/utils");

loadEnv(process.env.NODE_ENV || "development", process.cwd());

const isProduction = process.env.NODE_ENV === "production";

const requireEnv = (name) => {
  const value = process.env[name];
  if (!value) {
    throw new Error(
      `${name} environment variable is required. Refusing to start with an insecure default.`
    );
  }
  return value;
};

const jwtSecret = isProduction
  ? requireEnv("JWT_SECRET")
  : process.env.JWT_SECRET || "dev-only-jwt-secret-do-not-use-in-prod";
const cookieSecret = isProduction
  ? requireEnv("COOKIE_SECRET")
  : process.env.COOKIE_SECRET || "dev-only-cookie-secret-do-not-use-in-prod";

if (isProduction && !process.env.RESEND_API_KEY) {
  // eslint-disable-next-line no-console
  console.warn(
    "[notification] RESEND_API_KEY not set — notification module disabled. Password reset and other transactional emails will NOT send."
  );
}

module.exports = defineConfig({
  admin: {
    path: "/app",
    disable: false
  },
  projectConfig: {
    databaseUrl: process.env.DATABASE_URL,
    redisUrl: process.env.REDIS_URL,
    databaseDriverOptions: isProduction
      ? {
          connection: {
            // Railway/Neon managed Postgres terminates TLS at the proxy with
            // a cert chain that the pg client can't verify. This is the
            // documented approach for Railway internal Postgres — the
            // connection is still encrypted; only the cert chain is not
            // validated. Replace with a CA cert if/when one is available.
            ssl: { rejectUnauthorized: false }
          }
        }
      : {},
    http: {
      storeCors: process.env.STORE_CORS,
      adminCors: process.env.ADMIN_CORS,
      authCors: process.env.AUTH_CORS,
      jwtSecret,
      cookieSecret
    }
  },
  modules: {
    ...(process.env.RESEND_API_KEY
      ? {
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
        }
      : {})
  }
});
