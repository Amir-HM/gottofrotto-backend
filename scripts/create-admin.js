// Create (or update) a Medusa admin user from a script-runnable command.
//
// Usage (inside the container or via `railway ssh`):
//   npx medusa exec ./scripts/create-admin.js -- -e admin@example.com -p YourSecret
//
// Or via env vars (works when medusa exec swallows positional args):
//   ADMIN_EMAIL=... ADMIN_PASSWORD=... npx medusa exec ./scripts/create-admin.js

const { Modules } = require("@medusajs/framework/utils")

const parseArgs = (rest) => {
  const out = {}
  for (let i = 0; i < rest.length; i++) {
    const token = rest[i]
    if (token === "-e" || token === "--email") {
      out.email = rest[++i]
    } else if (token === "-p" || token === "--password") {
      out.password = rest[++i]
    }
  }
  return out
}

module.exports = async function createAdmin({ container, args }) {
  const logger = container.resolve("logger")

  const cli = parseArgs(args || [])
  // Only accept namespaced env vars. Generic PASSWORD / EMAIL fallbacks
  // were removed because they collide with unrelated env on Railway/CI.
  const email = cli.email || process.env.ADMIN_EMAIL
  const password = cli.password || process.env.ADMIN_PASSWORD

  if (!email || !password) {
    logger.error(
      "Missing credentials. Pass `-- -e <email> -p <password>` or set ADMIN_EMAIL / ADMIN_PASSWORD env vars."
    )
    process.exit(1)
  }

  const userModule = container.resolve(Modules.USER)
  const authModule = container.resolve(Modules.AUTH)

  const existingUsers = await userModule.listUsers({ email })
  if (existingUsers.length > 0) {
    logger.info(`User ${email} already exists (id=${existingUsers[0].id}). No-op.`)
    return
  }

  // Use the auth module's `register` flow so the emailpass provider's
  // `hashPassword` (scrypt-kdf) runs against the raw password. Calling
  // `createAuthIdentities` directly would skip the provider hook and
  // persist plaintext into provider_metadata — verified by reading
  // node_modules/@medusajs/auth-emailpass/dist/services/emailpass.js.
  const result = await authModule.register("emailpass", {
    body: { email, password },
  })

  if (!result.success || !result.authIdentity) {
    logger.error(
      `Failed to register auth identity for ${email}: ${result.error || "unknown error"}`
    )
    process.exit(1)
  }

  const users = await userModule.createUsers([{ email }])

  // Link the user record to the auth identity so the login flow can resolve
  // one from the other.
  const remoteLink = container.resolve("remoteLink")
  await remoteLink.create([
    {
      [Modules.AUTH]: { auth_identity_id: result.authIdentity.id },
      [Modules.USER]: { user_id: users[0].id },
    },
  ])

  logger.info(`Admin user created: ${email} (id=${users[0].id})`)
}
