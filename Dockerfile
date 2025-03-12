# Stage 1: Builder
FROM node:22.12-alpine AS builder

# Set working directory
WORKDIR /app

# Copy necessary files
COPY . .
COPY tsconfig.json tsconfig.json

# Install dependencies with better compatibility
RUN --mount=type=cache,target=/root/.npm npm install --legacy-peer-deps

# Ensure TypeScript builds successfully
RUN npx tsc --noEmit

# Build TypeScript files
RUN npm run build

# Stage 2: Release
FROM node:22-alpine AS release

# Set working directory
WORKDIR /app

# Copy built files and package files
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/package.json /app/package.json
COPY --from=builder /app/package-lock.json /app/package-lock.json
COPY replace_open.sh /replace_open.sh

# Set environment variable
ENV NODE_ENV=production

# Install only production dependencies
RUN npm ci --ignore-scripts --omit-dev

# Run the script and clean up
RUN sh /replace_open.sh && rm /replace_open.sh

# Define the entry point
ENTRYPOINT ["node", "dist/index.js"]
