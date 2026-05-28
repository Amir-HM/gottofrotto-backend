// Create (or update) a Medusa admin user from a script-runnable command.
//
// Usage (inside the container or via `railway ssh`):
//   npx medusa exec ./scripts/create-admin.js -- -e admin@example.com -p YourSecret
//
// Or via env vars (works when medusa exec swallows positional args):
//   ADMIN_EMAIL=... ADMIN_PASSWORD=... npx medusa exec ./scripts/create-admin.js
//
// Equivalent to the built-in `npx medusa user -e ... -p ...` command but kept
// here so deployment runbooks have a stable script path.

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
  const email = cli.email || process.env.ADMIN_EMAIL || process.env.EMAIL
  const password = cli.password || process.env.ADMIN_PASSWORD || process.env.PASSWORD

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

  // Create the auth identity first. The emailpass provider hashes the password
  // when stored in provider_metadata.
  const authIdentities = await authModule.createAuthIdentities([
    {
      provider_identities: [
        {
          provider: "emailpass",
          entity_id: email,
          provider_metadata: { password },
        },
      ],
    },
  ])

  const users = await userModule.createUsers([{ email }])

  // Link the user record to the auth identity so the login flow can resolve
  // one from the other.
  const remoteLink = container.resolve("remoteLink")
  await remoteLink.create([
    {
      [Modules.AUTH]: { auth_identity_id: authIdentities[0].id },
      [Modules.USER]: { user_id: users[0].id },
    },
  ])

  logger.info(`Admin user created: ${email} (id=${users[0].id})`)
}
