// One-off script to create an admin user via Medusa container
// Usage: npx medusa exec ./scripts/create-admin.js -- -e admin@example.com -p password123

const yargs = require('yargs/yargs');

const argv = yargs(process.argv.slice(2))
  .options({
    email: { type: 'string', alias: 'e', demandOption: true },
    password: { type: 'string', alias: 'p', demandOption: true },
  })
  .help(false)
  .parse();

module.exports = async ({ container }) => {
  const logger = container.resolve('logger');
  let userService;

  try {
    userService = container.resolve('userService');
  } catch (err) {
    logger.error('userService not available in container', err);
    process.exit(1);
  }

  // Support reading credentials from env vars when medusa exec strips CLI args
  const email = argv.email || process.env.ADMIN_EMAIL || process.env.EMAIL;
  const password = argv.password || process.env.ADMIN_PASSWORD || process.env.PASSWORD;

  if (!email || !password) {
    logger.error('No admin credentials provided. Set -- -e <email> -p <password> or ADMIN_EMAIL/ADMIN_PASSWORD env vars.');
    process.exit(1);
  }

  logger.info(`Creating admin user ${email}...`);
  try {
    const existing = await userService.retrieveByEmail(email).catch(() => null);
    if (existing) {
      logger.info(`User ${email} already exists. Updating role to admin.`);
      await userService.update(existing.id, { is_admin: true });
      logger.info('Updated existing user to admin.');
      return;
    }

    const user = await userService.create({
      email,
      password,
      is_admin: true,
    });

    logger.info(`Admin user created: ${user.id}`);
  } catch (err) {
    logger.error('Failed to create admin user', err);
    process.exit(1);
  }
};
