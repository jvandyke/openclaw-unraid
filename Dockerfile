# Start from the official Node image
FROM node:22-bookworm

# Install necessary system tools
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 1. Copy Manifest Files
COPY package.json pnpm-lock.yaml ./
COPY pnpm-workspace.yaml .npmrc ./

# 2. [FIX] Copy the scripts folder and UI manifest BEFORE install
# The 'postinstall' script in package.json needs these files to exist
COPY scripts ./scripts
COPY ui/package.json ./ui/package.json

# 3. Install dependencies
# We use --ignore-scripts to prevent other potential failures, 
# but if the postinstall is critical (likely is for the database/UI), 
# having the scripts folder present fixes the original error.
RUN corepack enable && pnpm install --frozen-lockfile

# 4. Copy the rest of the application code
COPY . .

# 5. Build the application
RUN pnpm build

# --- ENTRYPOINT SETUP ---
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["node", "dist/index.js"]
