# Proflie Architecture Documentation

## Overview

Proflie is a multi-tenant profile platform where users can create customizable public profiles composed of modular widgets. The architecture is designed for scalability, service isolation, and extensibility.

## Domain Strategy

### Core Domains

```
proflie.com              → Main landing/marketing site
app.proflie.com          → Authentication and CMS panel
username.proflie.com     → Public user profile pages (wildcard subdomain)
w-*.proflie.com          → Widget microservices (wildcard subdomain)
```

### Domain Routing Details

#### `proflie.com` - Landing Site
- Marketing pages
- Static files (robots.txt, sitemap.xml, favicon.ico)
- About, features, pricing, contact pages
- SEO-optimized content

#### `app.proflie.com` - Application Platform
Handles all authenticated user interactions:
- `/signup` - User registration
- `/login` - Authentication
- `/logout` - Session termination
- `/forgot-password` - Password reset flow
- `/verify-email` - Email verification
- `/cms` - Profile configuration panel
- `/cms/widgets` - Widget management
- `/cms/settings` - User settings

#### `username.proflie.com` - User Profiles
Each user gets their own subdomain for their public profile:
- `john.proflie.com` → John's profile
- `jane.proflie.com` → Jane's profile
- Fully customizable layout and widgets
- Server-side rendered for SEO
- Hydrated with client-side interactivity

#### `w-*.proflie.com` - Widget Services
Isolated microservices for profile widgets:
- `w-calendar.proflie.com` → Calendar widget
- `w-gallery.proflie.com` → Photo gallery widget
- `w-blog.proflie.com` → Blog widget
- `w-links.proflie.com` → Social links widget
- Future widgets can be added without DNS changes

## Widget Architecture

### Microservices Design

Each widget is a **completely isolated service** with:

1. **Independent Codebase**: Separate repository or monorepo subdirectory
2. **Own Database**: Dedicated PostgreSQL schema or separate DB instance
3. **Own API**: RESTful or GraphQL endpoints
4. **Own Frontend**: Micro-frontend for rendering
5. **Own Deployment**: Separate Docker container

### Widget Service Structure

Each widget service exposes two main endpoints:

```
w-calendar.proflie.com/render?user=john
  → Returns HTML fragment for server-side rendering
  
w-calendar.proflie.com/api/*
  → RESTful API for browser-side interactions
```

#### Example Widget Service Endpoints

**Calendar Widget (`w-calendar.proflie.com`)**
```
GET  /render?user=john              → HTML fragment for SSR
GET  /api/events?user=john          → JSON events list
POST /api/events                    → Create new event
PUT  /api/events/:id                → Update event
DELETE /api/events/:id              → Delete event
GET  /cms?user=john                 → CMS configuration form
```

**Gallery Widget (`w-gallery.proflie.com`)**
```
GET  /render?user=jane              → HTML fragment for gallery
GET  /api/photos?user=jane          → JSON photo list
POST /api/photos/upload             → Upload new photo
DELETE /api/photos/:id              → Delete photo
GET  /cms?user=jane                 → Gallery settings form
```

### Profile Composition Flow

When a user visits `john.proflie.com`:

1. **Main app** receives request at `john.proflie.com`
2. **Database query** fetches John's profile configuration:
   ```json
   {
     "username": "john",
     "widgets": [
       {"type": "calendar", "order": 1, "config": {...}},
       {"type": "gallery", "order": 2, "config": {...}},
       {"type": "blog", "order": 3, "config": {...}}
     ]
   }
   ```
3. **Server-side widget fetching** (parallel HTTP requests):
   ```rust
   let calendar_html = fetch("w-calendar.proflie.com/render?user=john").await;
   let gallery_html = fetch("w-gallery.proflie.com/render?user=john").await;
   let blog_html = fetch("w-blog.proflie.com/render?user=john").await;
   ```
4. **HTML composition** combines widget fragments into full page
5. **Response** sent to browser with embedded JavaScript for interactivity
6. **Client-side hydration** enables dynamic features

### Browser-to-Widget Communication

After initial page load, widgets can communicate directly with their services:

```javascript
// Browser makes API calls directly to widget services
// Example: Calendar widget updates events in real-time

fetch('https://w-calendar.proflie.com/api/events', {
  method: 'POST',
  credentials: 'include',  // Auth cookies
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    title: 'Meeting',
    date: '2025-11-26'
  })
})
```

**CORS Configuration**: Each widget service must configure CORS to allow:
- `https://username.proflie.com` (wildcard: `*.proflie.com`)
- `https://app.proflie.com` (for CMS previews)

## Folder Structure

### Main Application (`proflie-rust/`)

```
proflie-rust/
├── docs/
│   ├── architecture.md           # This file
│   ├── deployment.md             # Deployment guide
│   └── widget-development.md     # Widget creation guide
├── src/
│   ├── main.rs                   # Server setup, host routing
│   ├── config.rs                 # Environment configuration
│   ├── routes/
│   │   ├── mod.rs
│   │   ├── landing.rs            # Landing page routes
│   │   ├── auth.rs               # Authentication routes
│   │   ├── cms.rs                # CMS panel routes
│   │   └── profile.rs            # Profile rendering routes
│   ├── handlers/
│   │   ├── mod.rs
│   │   ├── landing_handler.rs
│   │   ├── auth_handler.rs
│   │   ├── cms_handler.rs
│   │   └── profile_handler.rs
│   ├── middleware/
│   │   ├── mod.rs
│   │   ├── host_router.rs        # Host-based routing logic
│   │   ├── auth.rs               # JWT/session validation
│   │   └── cors.rs               # CORS configuration
│   ├── services/
│   │   ├── mod.rs
│   │   ├── widget_fetcher.rs     # Fetches widget HTML/data
│   │   └── profile_composer.rs   # Composes profile pages
│   ├── models/
│   │   ├── mod.rs
│   │   ├── user.rs
│   │   ├── profile.rs
│   │   └── widget.rs
│   └── db/
│       ├── mod.rs
│       ├── connection.rs
│       └── queries.rs
├── static/                       # Static assets
│   ├── robots.txt
│   ├── favicon.ico
│   ├── css/
│   └── js/
├── templates/                    # HTML templates
│   ├── landing.html
│   ├── auth/
│   ├── cms/
│   └── profile/
├── migrations/                   # Database migrations
├── Cargo.toml
├── Dockerfile
└── compose.yml
```

### Widget Services (`proflie-widgets/`)

**Recommended**: Separate repository for widget microservices

```
proflie-widgets/
├── docs/
│   └── widget-api-spec.md
├── shared/
│   └── auth-client/              # Shared authentication library
├── calendar/
│   ├── src/
│   │   ├── main.rs
│   │   ├── render.rs             # HTML rendering logic
│   │   ├── api.rs                # API endpoints
│   │   └── db.rs                 # Database queries
│   ├── templates/
│   │   ├── widget.html
│   │   └── cms-form.html
│   ├── Cargo.toml
│   ├── Dockerfile
│   └── README.md
├── gallery/
│   ├── src/
│   ├── templates/
│   ├── Cargo.toml
│   ├── Dockerfile
│   └── README.md
├── blog/
│   ├── src/
│   ├── templates/
│   ├── Cargo.toml
│   ├── Dockerfile
│   └── README.md
└── docker-compose.yml            # Local development
```

## Routing Logic

### Host-Based Router

The main application uses Axum's `Host` extractor to route requests:

```rust
async fn host_based_router(Host(hostname): Host, uri: Uri) -> impl IntoResponse {
    let base_domain = std::env::var("BASE_DOMAIN")
        .unwrap_or_else(|_| "proflie.com".to_string());
    
    match hostname.as_str() {
        // Landing page
        h if h == base_domain => {
            landing_router(uri).await
        }
        
        // App subdomain (auth + CMS)
        h if h == format!("app.{}", base_domain) => {
            app_router(uri).await
        }
        
        // User profile subdomains
        h if h.ends_with(&format!(".{}", base_domain)) 
             && !h.starts_with("app.")
             && !h.starts_with("w-") => {
            let username = h.strip_suffix(&format!(".{}", base_domain)).unwrap();
            profile_router(username, uri).await
        }
        
        // Widget services (handled by separate deployments)
        h if h.starts_with("w-") && h.ends_with(&format!(".{}", base_domain)) => {
            // This won't be hit in production (separate containers)
            // Useful for local development routing
            widget_service_router(h, uri).await
        }
        
        _ => {
            (StatusCode::NOT_FOUND, Html("<h1>Domain not found</h1>")).into_response()
        }
    }
}
```

## Infrastructure & Deployment

### DNS Configuration

**Required DNS Records**:
```
proflie.com               A      123.45.67.89
app.proflie.com           A      123.45.67.89
*.proflie.com             A      123.45.67.89  (wildcard for user subdomains)
w-*.proflie.com           A      123.45.67.90  (OR same IP with reverse proxy routing)
```

### Reverse Proxy (Caddy/Nginx)

**Distributed Architecture** - Widgets on separate servers for scaling

Each widget service runs on its own server/cluster with dedicated resources:

```
# Main application server (123.45.67.89)
proflie.com               → main_app:3000
app.proflie.com           → main_app:3000
*.proflie.com             → main_app:3000

# Widget cluster (different server - 123.45.67.90)
w-calendar.proflie.com    → calendar_widget_cluster (load balanced)
w-gallery.proflie.com     → gallery_widget_cluster (load balanced)
w-blog.proflie.com        → blog_widget_cluster (load balanced)
```

**Benefits of Distributed Approach:**
- Independent scaling based on widget popularity
- Fault isolation (widget failure doesn't affect main app)
- Dedicated resources per widget service
- Separate deployment pipelines
- Geographic distribution possible
- Cost optimization (scale expensive widgets independently)

**DNS Configuration for Distributed Setup:**
```dns
proflie.com               A      123.45.67.89
app.proflie.com           A      123.45.67.89
*.proflie.com             A      123.45.67.89
w-calendar.proflie.com    A      123.45.67.90
w-gallery.proflie.com     A      123.45.67.91
w-blog.proflie.com        A      123.45.67.92
```

Each widget can have its own load balancer and auto-scaling configuration.

### Docker Compose (Local Development)

```yaml
version: '3.8'

services:
  main_app:
    build: ./proflie-rust
    ports:
      - "3000:3000"
    environment:
      - BASE_DOMAIN=proflie.local
      - DATABASE_URL=postgres://user:pass@db:5432/proflie
    depends_on:
      - db

  calendar_widget:
    build: ./proflie-widgets/calendar
    ports:
      - "3001:3000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/proflie_calendar

  gallery_widget:
    build: ./proflie-widgets/gallery
    ports:
      - "3002:3000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/proflie_gallery

  db:
    image: postgres:16
    environment:
      - POSTGRES_PASSWORD=password
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### Local Development Hosts File

```
# /etc/hosts
127.0.0.1 proflie.local
127.0.0.1 app.proflie.local
127.0.0.1 john.proflie.local
127.0.0.1 jane.proflie.local
127.0.0.1 w-calendar.proflie.local
127.0.0.1 w-gallery.proflie.local
127.0.0.1 w-blog.proflie.local
```

## Security Considerations

### Authentication Flow

1. User logs in at `app.proflie.com/login`
2. Server sets HTTP-only cookie with JWT
3. Cookie domain set to `.proflie.com` (allows all subdomains)
4. User navigates to `app.proflie.com/cms` - authenticated
5. Widget services validate token with main app's auth service

### Widget Service Authentication

Widgets must validate that requests are authenticated:

```rust
// Widget service validates auth token
async fn validate_auth(headers: &HeaderMap) -> Result<User, AuthError> {
    let token = headers
        .get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or(AuthError::MissingToken)?;
    
    // Call main app's auth validation endpoint
    let client = reqwest::Client::new();
    let response = client
        .get("https://app.proflie.com/api/validate-token")
        .header("Authorization", token)
        .send()
        .await?;
    
    if response.status().is_success() {
        Ok(response.json().await?)
    } else {
        Err(AuthError::InvalidToken)
    }
}
```

### CORS Policy

Each widget service configures CORS:

```rust
use tower_http::cors::{CorsLayer, Any};

let cors = CorsLayer::new()
    .allow_origin("https://app.proflie.com".parse::<HeaderValue>().unwrap())
    .allow_origin(/* regex for *.proflie.com */)
    .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
    .allow_credentials(true)
    .allow_headers(Any);
```

## Benefits of This Architecture

### Scalability
- Scale popular widgets independently of main app
- Add new widgets without touching core codebase
- Horizontal scaling per service

### Development Velocity
- Teams can work on widgets independently
- Deploy widgets without main app deployment
- Clear boundaries and contracts (API specs)

### User Experience
- Each user gets their own branded subdomain
- Fast server-side rendering for SEO
- Progressive enhancement with client-side features
- Customizable profile composition

### Maintainability
- Service isolation prevents cascade failures
- Clear separation of concerns
- Easier testing and debugging
- Independent versioning per widget

## Future Considerations

### Widget Marketplace
- Third-party widget development
- Widget store in CMS panel
- Widget versioning and updates
- Widget permissions and data access controls

### Performance Optimizations
- Widget response caching (Redis)
- CDN for static widget assets
- Edge rendering for profile pages
- Widget lazy-loading

### Advanced Features
- Real-time widget updates (WebSockets)
- Widget-to-widget communication
- Shared widget state
- Widget analytics and monitoring
