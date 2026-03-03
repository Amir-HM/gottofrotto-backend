FROM node:20-slim AS base
RUN corepack enable

# --- Dependencies ---
FROM base AS deps
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
RUN yarn install --immutable

# --- Build ---
FROM deps AS build
WORKDIR /app
COPY . .
ENV NODE_ENV=production
RUN NODE_OPTIONS='--max-old-space-size=1536' yarn build

# --- Production ---
FROM base AS production
WORKDIR /app
ENV NODE_ENV=production

COPY --from=build /app/.medusa .medusa
COPY --from=build /app/node_modules node_modules
COPY --from=build /app/package.json .
COPY --from=build /app/yarn.lock .
COPY --from=build /app/.yarnrc.yml .
COPY --from=build /app/medusa-config.mjs .
COPY --from=build /app/tsconfig.json .
COPY --from=build /app/src src

# Symlink public assets
RUN ln -sf .medusa/server/public public

EXPOSE 9000

CMD ["yarn", "start:prod"]
