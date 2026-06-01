import { defineMiddlewares } from "@medusajs/framework/http"
import type { MedusaNextFunction, MedusaRequest, MedusaResponse } from "@medusajs/framework/http"
import rateLimit from "express-rate-limit"

// Strip framework banner + add baseline security headers on every response.
const securityHeaders = (
  _req: MedusaRequest,
  res: MedusaResponse,
  next: MedusaNextFunction
) => {
  res.removeHeader?.("X-Powered-By")
  res.setHeader("X-Content-Type-Options", "nosniff")
  res.setHeader("X-Frame-Options", "DENY")
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin")
  res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
  // CSP targets the bundled admin SPA at /app — same-origin scripts only.
  // 'unsafe-inline' on style-src is required by the admin's Tailwind/CSS-in-JS
  // build; we accept it because the admin is authenticated and the script-src
  // remains locked down. Adjust `img-src` if the admin loads images from
  // additional CDNs (e.g. product thumbnails on S3).
  res.setHeader(
    "Content-Security-Policy",
    [
      "default-src 'self'",
      "script-src 'self'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "connect-src 'self'",
      "font-src 'self' data:",
      "frame-src 'none'",
      "object-src 'none'",
      "base-uri 'self'",
    ].join("; ")
  )
  if (process.env.NODE_ENV === "production") {
    res.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload")
  }
  next()
}

// Tight limit on every auth endpoint — covers /auth/user/emailpass,
// /auth/customer/emailpass, /auth/*/reset-password, etc. Keyed by IP.
// 10 requests / 15 min is enough for legitimate use (login, retry,
// password reset) and shuts down credential-stuffing bots fast.
const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: "draft-7",
  legacyHeaders: false,
  message: { message: "Too many auth attempts. Try again in 15 minutes." },
  // Trust the X-Forwarded-For Railway sets; the IP behind the proxy
  // is what we actually want to rate-limit on, not the proxy itself.
  validate: { trustProxy: false },
})

// Cheaper limiter for the store password-reset trigger — still bursts allowed
// for legitimate use but blocks email-bombing.
const passwordResetRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  limit: 5,
  standardHeaders: "draft-7",
  legacyHeaders: false,
  message: { message: "Too many password reset requests. Try again in an hour." },
  validate: { trustProxy: false },
})

export default defineMiddlewares({
  routes: [
    {
      matcher: "/*",
      middlewares: [securityHeaders],
    },
    {
      matcher: "/auth/*",
      middlewares: [authRateLimit],
    },
    {
      matcher: "/store/customers/me/password-token",
      middlewares: [passwordResetRateLimit],
    },
    {
      matcher: "/auth/*/reset-password",
      middlewares: [passwordResetRateLimit],
    },
  ],
})
