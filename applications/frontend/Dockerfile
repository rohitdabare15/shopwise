# ── Stage 1: Build the React app ──────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first — layer caching means npm install
# only reruns when package.json changes, not on every code change
COPY package*.json ./
RUN npm ci --silent

# Copy source and build
COPY . .
RUN npm run build
# Output is in /app/dist — a folder of static HTML/CSS/JS files

# ── Stage 2: Serve with Nginx ─────────────────────────────────
# The final image has NO Node.js, NO npm, NO source code.
# Just Nginx + the compiled static files. ~25MB total.
FROM nginx:alpine AS runtime

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy our custom nginx config
COPY nginx.conf /etc/nginx/conf.d/

# Copy built React app from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD wget -q -O /dev/null http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
