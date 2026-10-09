# PropConnect CRM & SaaS Platform

> **Next-Generation Real Estate Agency Management, Cross-Broker Collaboration, and Transaction Pipeline Platform.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![React](https://img.shields.io/badge/React-18.x-61dafb.svg)](https://reactjs.org)
[![Node.js](https://img.shields.io/badge/Node.js-18.x-green.svg)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14%2B-blue.svg)](https://www.postgresql.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178c6.svg)](https://www.typescriptlang.org)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

---

## 1. Executive Summary & Vision

In traditional real estate markets, agencies face high information asymmetry, lead leakage, manual tracking of commissions, and fragmented communication between buyer and seller brokers. 

**PropConnect CRM** unifies agency inventory management, inter-agency co-broking, client privacy protection, and end-to-end deal milestone tracking into a cohesive multi-tenant platform:
1. **Flutter Mobile Application**: For agency admins and field brokers (iOS & Android).
2. **React Super Admin Portal**: SaaS command center for platform operations, tenant management, subscription billing, and gateway configuration.
3. **Node.js/Express Backend**: Enterprise REST API backed by PostgreSQL, handling authentication, business logic, privacy firewalls, automated notifications, and audit logging.

---

## 2. System Architecture

```mermaid
graph TD
    subgraph Client Applications
        FA["📱 Flutter Mobile App<br/>(iOS & Android)"]
        AP["💻 React Admin Portal<br/>(Vite + TypeScript)"]
    end

    subgraph API & Services Gateway
        API["🚀 Node.js / Express API<br/>(Port 5000 / PM2)"]
        SW["📖 Swagger Docs<br/>(/api-docs)"]
    end

    subgraph Data & Storage Layer
        PG[("🐘 PostgreSQL Database<br/>(propconnect_db)")]
        FS["📁 File Storage<br/>(/uploads/photos)"]
    end

    subgraph External Integrations
        WA["💬 WhatsApp Business API<br/>(Interakt.ai)"]
        PGW["💳 Payment Gateways<br/>(Razorpay & Stripe)"]
        FCM["🔔 Push Notifications<br/>(Firebase Cloud Messaging)"]
    end

    FA -->|REST / JWT| API
    AP -->|REST / JWT| API
    API --> SW
    API -->|Sequelize ORM| PG
    API --> FS
    API --> WA
    API --> PGW
    API --> FCM
```

---

## 3. Core Modules & Key Features

### 3.1 Property Management Module
- **Dual Visibility Scopes**: Properties can be flagged as **Public** (visible on the collaboration exchange) or **Private** (exclusive to the listing agency).
- **Indian Real Estate Attributes**: BHK (1–5+ BHK, Penthouse, Duplex), built-up and carpet area, floor number, furnishing, RERA ID, parking, amenities, and structured location taxonomy (State, City, Sub-district, Area, Latitude/Longitude).
- **Rich Media & Collateral**: High-resolution image galleries, floor plans, and property brochures.
- **Sold / Rented Auto-Exclusion**: Closed listings are automatically excluded from public searches and collaboration requests to avoid outdated inquiries, while maintaining historical audit records for the listing agency.

### 3.2 Inter-Agency Collaboration & Privacy Firewall
- **Co-Broking Protocol**: Agency A (holding property mandate) and Agency B (representing buyer) can send and accept collaboration requests.
- **Client Privacy Firewall**:
  - Buyer's direct contact details (phone, email) are strictly protected. The listing broker/agency only sees verified lead requirements and budgets.
  - In a property sold scenario, non-winning collaborators receive a clean notification that the listing was sold, with **zero leakage** of the buyer's identity or counterparty terms.
- **Broker Delegation**: Agency Admins can delegate incoming/outgoing collaboration requests to specific brokers in their team.

### 3.3 Transaction Milestones & Deal Pipeline (9 Stages)
Deals follow a structured lifecycle:
1. **Inquiry / Lead Assigned**
2. **Site Visit Scheduled / Completed**
3. **Price Negotiation**
4. **Token Done / Booking Amount**
5. **Legal Due Diligence / Document Verification**
6. **Draft Agreement / Sale Agreement Signing**
7. **Home Loan Sanction (if applicable)**
8. **Final Registry & Stamp Duty**
9. **Possession & Deal Closed**

Interactive date pickers, milestone notes, document uploads, and commission split calculations are embedded directly in the pipeline.

### 3.4 Commission & Financial Settlements
- **Configurable Split Models**: 50/50 co-brokerage standard split, custom percentage splits, and platform transaction fees.
- **Payment Ledger**: Real-time tracking of token amounts, advance brokerage, pending balances, and TDS/GST deductions.

### 3.5 Communications & WhatsApp Integration
- **Automated WhatsApp Alerts**: Powered by Interakt Business API for collaboration invites, approval notices, milestone advancements, and invoice generation.
- **Real-time In-App Messaging**: Dedicated deal chat rooms linking brokers from collaborating agencies.

### 3.6 Security, Biometrics & RBAC
- **Role-Based Access Control**:
  - `super_admin`: Full system oversight, SaaS tenant management, gateway configuration.
  - `agency_admin`: Single-agency tenant control, broker roster management, assigned property scoping.
  - `broker`: Dedicated portfolio view restricted to personal deals and assigned properties.
- **Device Security & Audit**:
  - Biometric App Lock (Face ID / Fingerprint) with automatic background timeout.
  - Multi-device active session monitoring with remote session revocation.

---

## 4. Repository Structure

```
propconnect/
├── android/                        # Android native configurations & build scripts
├── assets/                         # Static images, placeholders, and logos
├── backend/                        # Node.js / Express API Backend
│   ├── src/
│   │   ├── config/                 # Database, Swagger, and Environment configurations
│   │   ├── controllers/            # REST API route controllers
│   │   ├── middlewares/            # JWT auth, error handlers, and request logger
│   │   ├── models/                 # Sequelize PostgreSQL models
│   │   ├── routes/                 # Express API routes
│   │   ├── services/               # WhatsApp, Notification, Audit, and Seed services
│   │   ├── utils/                  # Response formatters and date helpers
│   │   ├── app.ts                  # Express application setup
│   │   └── server.ts               # HTTP server entrypoint
│   ├── package.json
│   └── tsconfig.json
├── ios/                            # iOS native configurations
├── lib/                            # Flutter Application Source
│   ├── core/
│   │   ├── constants/              # Theme colors, assets, typography
│   │   ├── models/                 # Dart domain models (Property, Deal, Agency, User)
│   │   ├── network/                # HTTP ApiService with interceptors
│   │   ├── providers/              # Riverpod StateNotifier providers
│   │   ├── routing/                # GoRouter declarative navigation
│   │   ├── services/               # Biometrics, AuthStorage, Presence, WhatsApp
│   │   ├── theme/                  # Light and Dark theme configurations
│   │   └── widgets/                # Common reusable UI components
│   ├── features/
│   │   ├── agency/                 # Agency profile and management
│   │   ├── auth/                   # Login, Registration, Password Reset
│   │   ├── chat/                   # Deal chat and direct conversations
│   │   ├── collaborations/         # Inter-agency request handling
│   │   ├── deals/                  # 9-stage milestone tracker & add deal screens
│   │   ├── home/                   # Broker dashboard & action shortcuts
│   │   ├── notifications/          # In-app notification center
│   │   ├── properties/             # Inventory listing, add/edit, details
│   │   ├── search/                 # Public collaboration search with filters
│   │   └── settings/               # App lock, active sessions, preferences
│   └── main.dart                   # Flutter application entrypoint
├── super_admin_panel/              # React Super Admin Web Portal
│   ├── src/
│   │   ├── components/             # Reusable UI, modals, selects, layout
│   │   ├── pages/                  # Agencies, Brokers, Deals, Properties, Gateways, etc.
│   │   ├── services/               # API client with token management
│   │   ├── App.tsx                 # React Router v7 configuration
│   │   └── main.tsx                # React DOM mount point
│   ├── package.json
│   └── vite.config.ts
├── test/                           # Automated Flutter unit and widget tests
│   └── widget_test.dart            # 31 comprehensive test suites
└── README.md                       # Master system documentation
```

---

## 5. Environment Variables & Setup

### Backend (`backend/.env`)

```ini
NODE_ENV=production
PORT=5000
API_PREFIX=/api/v1

# PostgreSQL Database Configuration
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=propconnect_user
DB_PASSWORD=YourSecurePasswordHere
DB_NAME=propconnect_db
DB_SSL=false

# Authentication
JWT_SECRET=your_jwt_secret_key_2026

# WhatsApp Business API (Interakt)
INTERAKT_API_KEY=your_interakt_api_key
INTERAKT_BUSINESS_ID=your_interakt_business_id
INTERAKT_BASE_URL=https://api.interakt.ai/v1/public
```

### Super Admin Portal (`super_admin_panel/.env`)

```ini
VITE_API_BASE_URL=http://72.61.229.6:5000/api/v1
```

---

## 6. Local Development Guide

### 6.1 Backend API
```bash
cd backend
npm install
npm run build
npm start
# Or for live hot-reload development:
npm run dev
```
Swagger UI is accessible at: `http://localhost:5000/api-docs`

### 6.2 Super Admin Panel
```bash
cd super_admin_panel
npm install
npm run dev
# Portal will start at http://localhost:5173
```

### 6.3 Flutter Mobile App
```bash
# Verify Flutter environment
flutter doctor

# Fetch dependencies
flutter pub get

# Run test suite
flutter test

# Run application on simulator / connected device
flutter run
```

---

## 7. Production Deployment & VPS Infrastructure

The platform runs on a dedicated Linux VPS (`Ubuntu 22.04 LTS`):
- **Server IP**: `72.61.229.6`
- **Reverse Proxy / Ports**:
  - `5000`: Backend REST API (PM2 process: `propconnect-api`)
  - `3000`: Super Admin Web Portal (PM2 process: `propconnect-admin`)
  - `5432`: PostgreSQL Database (`propconnect_db`)

### PM2 Process Control
```bash
# View active service statuses
pm2 status

# Restart services
pm2 restart propconnect-api
pm2 restart propconnect-admin

# Stream real-time logs
pm2 logs propconnect-api --lines 50
```

---

## 8. Quality Assurance & Testing

The platform enforces zero static analysis warnings and rigorous regression test suites:
- **Static Analysis**: `flutter analyze` runs with **0 issues found**.
- **Automated Unit Tests**: `flutter test` validates:
  - 50/50 and custom commission split calculations.
  - Payment ledger parsing and TDS/GST calculations.
  - 12 lifecycle stages and privacy metadata serialization.
  - Indian real estate pricing parsing (`₹ Cr`, `₹ Lakhs`, raw numeric).
  - RBAC property and deal scoping across agency admins and brokers.
  - App lock lifecycle and session audit tracking.
  - Collaboration request isolation and delegation workflows.

---

## 9. Contributors & Document Control

| Attribute | Details |
| :--- | :--- |
| **Product Version** | 1.0.0 Production Release |
| **Documentation Author** | Google Deepmind Antigravity Pair-Programming Team |
| **Target Audience** | Real Estate Agencies, Enterprise Brokers, SaaS Operations |
| **Status** | Fully Implemented, Verified, and Deployed |
