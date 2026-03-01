FROM node:18 AS builder

WORKDIR /calcom

# Install build tools and dependencies for building native modules
RUN apt-get update && apt-get install -y --no-install-recommends build-essential python3 libvips-dev

# Set up environment variables (as before)
# Define build-time arguments

COPY package.json yarn.lock .yarnrc.yml playwright.config.ts turbo.json i18n.json ./
COPY .yarn ./.yarn
COPY apps/web ./apps/web
COPY apps/api/v2 ./apps/api/v2
COPY packages ./packages

# Clean Yarn cache before installing dependencies
RUN yarn cache clean
RUN yarn config set httpTimeout 1200000
RUN npx turbo prune --scope=@calcom/web --scope=@calcom/trpc --docker

# Install dependencies and run builds
RUN yarn install

# Handle the Prisma and other build steps
RUN yarn workspace @calcom/trpc run build
RUN yarn --cwd packages/embeds/embed-core workspace @calcom/embed-core run build
RUN yarn --cwd apps/web workspace @calcom/web run copy-app-store-static
RUN yarn --cwd apps/web workspace @calcom/web run build
RUN rm -rf node_modules/.cache .yarn/cache apps/web/.next/cache
