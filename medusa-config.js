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
            // Accepted security finding — DO NOT change without a Railway CA cert in hand.
            // Railway's internal Postgres is reached over the private *.railway.internal
            // mesh and uses a self-signed cert that no public CA chain can verify.
            // Setting rejectUnauthorized: true here would break the connection entirely.
            // The connection is still TLS-encrypted; only chain verification is skipped,
            // and traffic never leaves Railway's private network. This is the documented
            // pattern for Railway-managed Postgres. Re-evaluate only if Railway ships a
            // public internal CA, or if this app moves off Railway-internal Postgres.
            ssl: { rejectUnauthorized: false }
          },
          // Cap the knex pool for Railway's 1 vCPU box. Default max:10 is too
          // generous — under bursty load it can saturate Postgres' connection
          // limit before saturating CPU. min:1 avoids idle-connection cost.
          pool: { min: 1, max: 5 }
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
