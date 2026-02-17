// Create an admin user via Medusa v2 API
// Usage: ADMIN_EMAIL=admin@example.com ADMIN_PASSWORD=pass123 npx medusa exec ./scripts/create-admin.js
//
// This follows the same pattern as the built-in `medusa user` CLI command.

module.exports = async ({ container }) => {
  const logger = container.resolve("logger")

  const email = process.env.ADMIN_EMAIL || process.env.EMAIL
  const password = process.env.ADMIN_PASSWORD || process.env.PASSWORD

  if (!email || !password) {
    logger.error(
      "No admin credentials provided. Set ADMIN_EMAIL and ADMIN_PASSWORD environment variables."
    )
    process.exit(1)
  }

  logger.info(`Creating admin user ${email}...`)

  try {
    const { Modules } = await import("@medusajs/framework/utils")

    const userService = container.resolve(Modules.USER)
    const authService = container.resolve(Modules.AUTH)

    const user = await userService.createUsers({ email })

    const { authIdentity, error } = await authService.register("emailpass", {
      body: { email, password },
    })

    if (error) {
      logger.error(error)
      process.exit(1)
    }

    await authService.updateAuthIdentities({
      id: authIdentity.id,
      app_metadata: {
        user_id: user.id,
      },
    })

    logger.info(`Admin user created: ${user.id}`)
  } catch (err) {
    if (err.message?.includes("already exists") || err.message?.includes("duplicate")) {
      logger.info(`User ${email} already exists.`)
      return
    }
    logger.error("Failed to create admin user", err)
    process.exit(1)
  }
}
