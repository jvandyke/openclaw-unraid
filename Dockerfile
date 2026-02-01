# Start from the official Node image
FROM node:22-bookworm

# Install necessary system tools
RUN apt-get update && apt-get install -y openssl git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Copy Manifests & Scripts
COPY package.json pnpm-lock.yaml ./
COPY pnpm-workspace.yaml .npmrc ./
COPY scripts ./scripts
COPY ui/package.json ./ui/package.json

# 2. Install Dependencies
# We use --frozen-lockfile to ensure reproducible builds
RUN corepack enable && pnpm install --frozen-lockfile

# 3. Copy Source Code
COPY . .

# 4. Build the UI
# This is required for the web interface to work
RUN pnpm ui:build

# 5. Build the Backend
# We set this variable to 1 so the build doesn't fail 
# if the optional A2UI submodule is missing or incomplete.
RUN OPENCLAW_A2UI_SKIP_MISSING=1 pnpm build

# --- ENTRYPOINT SETUP ---
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["node", "dist/index.js", "gateway", "--host", "0.0.0.0"]
