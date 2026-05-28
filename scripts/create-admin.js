// One-off ops script — kept as a thin shim around Medusa v2's built-in
// `medusa user` CLI. The old version called `userService.create({ password,
// is_admin: true })` which is the v1 API; in v2 identity and user are
// separate models and the call silently no-ops.
//
// Usage (run inside the container or via `railway ssh`):
//   npx medusa user -e admin@example.com -p YourSecretPassword
//
// This file remains so existing docs/runbooks that reference
// `scripts/create-admin.js` print a helpful pointer instead of failing
// confusingly.

/* eslint-disable no-console */
console.log(
  "[create-admin] This script is deprecated for Medusa 2.x.\n" +
    "  Use the built-in CLI instead:\n" +
    "    npx medusa user -e <email> -p <password>\n" +
    "  Run it inside the Railway service via `railway ssh` or locally\n" +
    "  with DATABASE_URL pointed at the target environment."
);
process.exit(0);
