// Create a Medusa admin user from a script-runnable command.
//
// Usage (inside the container or via `railway ssh`):
//   npx medusa exec ./scripts/create-admin.js -- -e admin@example.com -p YourSecret
//
// Or via env vars (works when medusa exec swallows positional args):
//   ADMIN_EMAIL=... ADMIN_PASSWORD=... npx medusa exec ./scripts/create-admin.js
//
// Medusa ships an equivalent `medusa user -e <email> -p <password>` command.
// This script stays because it is idempotent (no-ops on an existing user)
// and reads env vars, which the built-in command does not.

const { ContainerRegistrationKeys, FeatureFlag, Modules } = require("@medusajs/framework/utils")

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

async function createAdmin({ container, args }) {
  const logger = container.resolve(ContainerRegistrationKeys.LOGGER)

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
  const workflowEngine = container.resolve(Modules.WORKFLOW_ENGINE)

  const existingUsers = await userModule.listUsers({ email })
  if (existingUsers.length > 0) {
    logger.info(`User ${email} already exists (id=${existingUsers[0].id}). No-op.`)
    return
  }

  // Mirror the built-in `medusa user` command: when the rbac feature flag is
  // on, a user created without the super-admin role can sign in but sees
  // nothing, which looks like a broken account.
  let userRoles = []
  if (FeatureFlag.isFeatureEnabled("rbac")) {
    const rbacService = container.resolve(Modules.RBAC)
    const superAdminRoles = await rbacService.listRbacRoles({ id: "role_super_admin" })
    if (superAdminRoles.length > 0) {
      userRoles = [superAdminRoles[0].id]
    }
  }

  const { result: users } = await workflowEngine.run("create-users-workflow", {
    input: { users: [{ email, roles: userRoles }] },
  })
  const user = users[0]

  // Use the auth module's `register` flow so the emailpass provider's
  // `hashPassword` (scrypt-kdf) runs against the raw password. Calling
  // `createAuthIdentities` directly would skip the provider hook and
  // persist plaintext into provider_metadata.
  const { authIdentity, error } = await authModule.register("emailpass", {
    body: { email, password },
  })

  if (error || !authIdentity) {
    logger.error(`Failed to register auth identity for ${email}: ${error || "unknown error"}`)
    process.exit(1)
  }

  // Medusa 2.19+ resolves the admin user from the auth identity's
  // `app_metadata.user_id`. The old `remoteLink.create()` pairing of
  // auth_identity_id <-> user_id no longer has a registered link module
  // and throws at runtime.
  await authModule.updateAuthIdentities({
    id: authIdentity.id,
    app_metadata: { user_id: user.id },
  })

  logger.info(
    `Admin user created: ${email} (id=${user.id})` +
      (userRoles.length > 0 ? " — super admin role assigned." : "")
  )
}

exports.default = createAdmin
