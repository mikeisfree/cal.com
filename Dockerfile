FROM node:20 AS builder

WORKDIR /calcom

# Install build tools and dependencies for building native modules
RUN apt-get update && apt-get install -y --no-install-recommends build-essential python3 libvips-dev

# Define build-time arguments required by next.config.ts and the build process
ARG NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
ARG NEXT_PUBLIC_API_V2_URL
ARG NEXT_PUBLIC_LICENSE_CONSENT
ARG NEXT_PUBLIC_WEBSITE_TERMS_URL
ARG NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL
ARG NEXT_PUBLIC_SINGLE_ORG_SLUG
ARG ORGANIZATIONS_ENABLED
ARG CALCOM_TELEMETRY_DISABLED
ARG NEXTAUTH_SECRET=secret
ARG CALENDSO_ENCRYPTION_KEY=secret
ARG DATABASE_URL
ARG DATABASE_DIRECT_URL
ARG CSP_POLICY
ARG NODE_ENV=production

# Set them as ENV so they're available during RUN steps (next.config.ts reads process.env)
ENV NEXT_PUBLIC_WEBAPP_URL=${NEXT_PUBLIC_WEBAPP_URL} \
    NEXT_PUBLIC_API_V2_URL=${NEXT_PUBLIC_API_V2_URL} \
    NEXT_PUBLIC_LICENSE_CONSENT=${NEXT_PUBLIC_LICENSE_CONSENT} \
    NEXT_PUBLIC_WEBSITE_TERMS_URL=${NEXT_PUBLIC_WEBSITE_TERMS_URL} \
    NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL=${NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL} \
    NEXT_PUBLIC_SINGLE_ORG_SLUG=${NEXT_PUBLIC_SINGLE_ORG_SLUG} \
    ORGANIZATIONS_ENABLED=${ORGANIZATIONS_ENABLED} \
    CALCOM_TELEMETRY_DISABLED=${CALCOM_TELEMETRY_DISABLED} \
    NEXTAUTH_SECRET=${NEXTAUTH_SECRET} \
    CALENDSO_ENCRYPTION_KEY=${CALENDSO_ENCRYPTION_KEY} \
    DATABASE_URL=${DATABASE_URL} \
    DATABASE_DIRECT_URL=${DATABASE_DIRECT_URL} \
    CSP_POLICY=${CSP_POLICY} \
    NODE_ENV=${NODE_ENV}

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
