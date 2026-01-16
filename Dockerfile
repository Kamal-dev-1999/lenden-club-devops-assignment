# Use Alpine Linux as base image
FROM node:18-alpine

# SECURITY: Create non-root user for running the application
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001 -G nodejs

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install --production && \
    chown -R nodeuser:nodejs /app

# Copy application files
COPY --chown=nodeuser:nodejs app.js .

# SECURITY: Switch to non-root user (fixes AVD-DS-0002)
USER nodeuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application
CMD ["npm", "start"]
