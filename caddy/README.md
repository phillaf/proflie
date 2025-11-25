# Caddy Reverse Proxy

This directory contains the Caddy reverse proxy configuration for proflie.com.

## Purpose

Caddy acts as a reverse proxy in front of the Rust web application, providing:

- **Automatic HTTPS** - Let's Encrypt SSL certificates with automatic renewal
- **HTTP caching** - Response caching to reduce backend load (production only)
- **Access logging** - JSON-formatted request logs with rotation

## Variants

The Dockerfile builds two variants using multi-stage targets:

- **`cache`** - Production build with caching enabled (`Caddyfile.cache`)
- **`nocache`** - Development build with HTTP only, no cache (`Caddyfile.nocache`)

## Building

```bash
# Production
docker build --target cache -t phillaf/proflie-caddy:cache .

# Development
docker build --target nocache -t phillaf/proflie-caddy:nocache .
```
