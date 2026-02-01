# Start from the official Node image
FROM node:22-bookworm

# Install system tools
RUN apt-get update && apt-get install -y openssl git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Copy Manifests & Scripts
# We copy the 'scripts' folder early because 'postinstall' hooks need it.
COPY package.json pnpm-lock.yaml ./
COPY pnpm-workspace.yaml .npmrc ./
COPY scripts ./scripts
COPY ui/package.json ./ui/package.json

# 2. Install Dependencies
# We use --frozen-lockfile to ensure reproducible builds
RUN corepack enable && pnpm install --frozen-lockfile

# 3. Copy Source Code (Includes the 'ui' folder and submodules)
COPY . .

# 4. [CRITICAL FIX] Build the UI
# This compiles the frontend assets required by the main build
RUN pnpm ui:build

# 5. Build the Backend
RUN pnpm build

# --- ENTRYPOINT SETUP ---
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["node", "dist/index.js"]
