// Create an admin user via Medusa v2 CLI
// Usage: npx medusa user -e admin@example.com -p password123
//
// This script is kept as a convenience wrapper.
// It uses Medusa v2's built-in user management workflows.

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
    const { createUserAccountWorkflow } = await import(
      "@medusajs/medusa/core-flows"
    )

    const { result } = await createUserAccountWorkflow(container).run({
      input: {
        authIdentityId: undefined,
        userData: {
          email,
        },
      },
    })

    logger.info(`Admin user created: ${result.id}`)
  } catch (err) {
    if (err.message?.includes("already exists") || err.message?.includes("duplicate")) {
      logger.info(`User ${email} already exists.`)
      return
    }
    logger.error("Failed to create admin user", err)
    process.exit(1)
  }
}
