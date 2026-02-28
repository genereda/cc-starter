# CLAUDE.md

## Project Overview

This is a Next.js web app for [brief description]. It uses TypeScript, Tailwind CSS, and Prisma for database access.

## Architecture

- `src/app/` — Next.js App Router pages and layouts
- `src/components/` — Shared React components
- `src/lib/` — Utility functions and API clients
- `src/db/` — Prisma schema and database utilities
- `tests/` — Jest test files mirroring src/ structure

## Development

- **Package manager:** pnpm
- **Dev server:** `pnpm dev` (port 3000)
- **Tests:** `pnpm test` (Jest + React Testing Library)
- **Lint:** `pnpm lint` (ESLint + Prettier)
- **Database:** PostgreSQL via Prisma (`pnpm db:push` to sync schema)

## Conventions

- All components use TypeScript with strict mode
- API routes return standardized `{ data, error }` response shapes
- Database queries go through `src/lib/db.ts`, never directly in components
- Tests are required for all API routes and utility functions
- Feature branches off `main`, squash merge PRs

## Current Focus

<!-- Update this section each sprint/cycle -->
- Building user authentication flow (OAuth + email/password)
- Migrating from Pages Router to App Router
