# Multi-stage build for IRS React App
# Stage 1: Dependencies installation with Bun
FROM oven/bun:1.2.15-alpine AS deps
WORKDIR /app

# Install dependencies only when needed
COPY package.json package-lock.json* bun.lockb* ./
RUN bun install --frozen-lockfile

# Stage 2: Build stage with Node.js
FROM node:20-alpine AS builder
WORKDIR /app

# Set environment variables
ARG VITE_AWS_REGION
ARG VITE_DYNAMODB_TABLE_NAME
ARG VITE_USE_MOCK_DATA

ENV VITE_AWS_REGION=us-east-1
ENV VITE_DYNAMODB_TABLE_NAME=incident
ENV VITE_USE_MOCK_DATA=false

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Stage 3: Production stage with nginx
FROM nginx:alpine AS production
WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy static assets from builder stage
COPY --from=builder /app/dist .

# Copy nginx configuration
COPY docker/config/nginx.conf /etc/nginx/nginx.conf

# Set permissions
RUN chmod -R 755 /usr/share/nginx/html

# Expose port 8080
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]