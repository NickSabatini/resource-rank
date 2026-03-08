# ResourceRank — PROJECT.md

## 1. Project Overview

ResourceRank is a community-curated directory of the best learning resources for any
topic. Users can create topics (e.g., skiing, coding, sales) and submit useful resources
such as articles, books, videos, or courses. The community votes on resources so the
most valuable ones rise to the top, forming a clean ranked "knowledge board" per topic.

Unlike Reddit or forums, ResourceRank is not for discussion — it is specifically designed
to surface the highest quality educational resources through community voting while
preventing spam and duplicate links.

Current stage: early MVP. Focus is data model and API foundation, not UI polish.

---

## 2. Tech Stack & Architecture

| Layer          | Choice                          | Why                                                              |
|----------------|---------------------------------|------------------------------------------------------------------|
| Framework      | Next.js 14 (App Router)         | Frontend + backend in one; Server Components for performance     |
| Language       | TypeScript (strict)             | Safer code, easier refactoring, no `any`                         |
| Database       | PostgreSQL                      | Relational model; unique constraints for deduplication           |
| Auth           | Supabase Auth                   | OAuth (Google/GitHub); integrated with DB, RLS, session handling |
| Styling        | Tailwind CSS                    | Utility-first; no context switching to CSS files                 |
| UI Components  | shadcn/ui                       | Pre-built accessible components; code lives in your project      |
| Spam prevention| Cloudflare Turnstile            | CAPTCHA at signup and suspicious activity points                 |
| Hosting        | Vercel                          | Zero-config Next.js deployment, preview environments            |
| Database host  | Supabase                        | Managed Postgres, generous free tier, good DX                   |

> **Auth decision:** Supabase Auth is used over Clerk or NextAuth because auth and
> the database are on the same platform — sessions integrate directly with Postgres
> and row-level security. Do not suggest switching to Clerk or NextAuth.

> **DB host decision:** Supabase is preferred for its managed Postgres, generous
> free tier, and good developer experience. Do not suggest Neon or Railway.

**Architecture: simple monolith — do not suggest microservices.**

```
Next.js UI (Server + Client Components)
            │
Next.js API Route Handlers
            │
     Supabase Client
            │
  PostgreSQL (Supabase)
```

---

## 3. Project Structure

```
/resource-rank-app
├── app/                          # Next.js App Router
│   ├── layout.tsx                # Root layout — fonts, providers, global nav
│   ├── page.tsx                  # Homepage — topic discovery
│   ├── (auth)/                   # Auth pages — Clerk-handled
│   │   ├── login/page.tsx
│   │   └── signup/page.tsx
│   ├── topics/
│   │   └── [slug]/
│   │       └── page.tsx          # Topic page — ranked resource list
│   └── api/                      # API route handlers (thin — logic stays in /lib)
│       ├── topics/route.ts       # GET all topics, POST new topic
│       ├── resources/route.ts    # POST new resource
│       └── resources/[id]/
│           ├── vote/route.ts     # POST vote (up/down/remove)
│           └── report/route.ts   # POST spam report
│
├── components/
│   ├── ui/                       # Primitives — shadcn/ui lives here
│   └── features/
│       ├── topics/
│       │   └── TopicList.tsx
│       └── resources/
│           ├── ResourceList.tsx
│           └── VoteButtons.tsx
│
├── lib/                          # All business logic lives here
│   ├── supabase/
│   │   ├── server.ts             # Supabase client for server components + auth
│   │   └── client.ts             # Supabase client for browser
│   ├── canonicalizeUrl.ts        # URL normalization + hashing
│   └── ranking.ts                # Wilson score (top) + time-decay (hot) algorithms
│
├── types/
│   ├── database.ts               # Auto-generated types from Supabase CLI
│   └── index.ts                  # Shared app-wide types
│
├── scripts/
│   └── seed.ts
│
├── middleware.ts                 # Supabase auth — protects all non-public routes
├── .env.local                    # Secrets — never commit
├── next.config.ts
├── tailwind.config.ts
└── tsconfig.json
```

**Key principle:** API routes are thin wrappers. All logic goes in `/lib`. Components
contain no business logic.

---

## 4. Conventions & Preferences

**TypeScript**
- Strict mode always on
- No `any`, no `// @ts-ignore`
- All API response shapes must be typed
- Database types are auto-generated via Supabase CLI — do not hand-write them
- Regenerate types after any schema change: `npx supabase gen-types typescript --project-id your-project-id > types/database.ts`

**Async style**
- Always `async/await` — never `.then()` chains

**Naming**
- Database tables: `snake_case` plural (`users`, `topics`, `resources`)
- Database columns: `snake_case`
- TypeScript variables: `camelCase`
- React components: `PascalCase`
- Files: `camelCase.ts` for utilities, `PascalCase.tsx` for components

**API responses — all routes return this shape:**
```typescript
{
  success: boolean
  data?: object
  error?: string
}
```

**HTTP status codes:**
- `200` OK
- `400` Bad Request
- `401` Unauthorized
- `403` Forbidden
- `409` Conflict (duplicate resource)
- `500` Server Error

**Styling**
- Tailwind utility classes only — no CSS modules, no inline styles, no styled-components
- For complex or repeated class strings, extract into a component rather than using `@apply`
- shadcn/ui is the component library — do not install Material UI or Chakra
- shadcn components live in `components/ui/` and can be freely edited
- Add new shadcn components via CLI: `npx shadcn@latest add [component]`

> **UI component decision:** shadcn/ui is chosen over Material UI or Chakra because
> it ships source code directly into your project, works natively with Tailwind, and
> has no version lock-in. Do not suggest alternative component libraries.

**Error handling**
- Never throw raw errors out of lib functions
- Return `{ data, error }` result objects instead
- API routes handle the HTTP status mapping

---

## 5. Core Data Model

### Users
```
id, email, display_name, created_at, trust_level, is_banned
```

### Topics
```
id, slug, name, description, created_by, created_at
```

### Resources
```
id, topic_id, title, url, canonical_url, canonical_url_hash,
description, resource_type, created_by, created_at,
score, up_count, down_count, report_count, status
```

### Votes
```
id, user_id, resource_id, value, created_at
UNIQUE CONSTRAINT: (user_id, resource_id)
```

### Reports
```
id, user_id, resource_id, reason, created_at
```

**Resource uniqueness is enforced by:**
```
UNIQUE CONSTRAINT: (topic_id, canonical_url_hash)
```
This is a database-level constraint, not application logic. Do not remove it.

---

## 6. Key Decisions Already Made (Don't Relitigate)

**No comments or discussions**
This is not Reddit. The only entities are topics, resources, and votes. Do not add
comment systems, reply threads, or discussion features.

**Voting model**
- One vote per user per resource (+1 or -1)
- Users can change or remove their vote
- Vote counts (`up_count`, `down_count`, `score`) are stored denormalized on the
  resource and updated atomically — this avoids expensive aggregation queries
- Do not move votes back to pure aggregation

**URL deduplication via canonical hash**
All submitted URLs go through canonicalization before insertion:
1. Normalize scheme + host
2. Remove tracking params
3. Remove fragments
4. Normalize trailing slash
5. Sort query parameters
6. Compute `sha256(canonical_url)` → stored as `canonical_url_hash`

**Ranking algorithms**
- `Top` → Wilson score lower bound
- `Hot` → time-decay weighted score
- `New` → created_at descending

**CAPTCHA strategy**
Turnstile is used at signup and suspicious activity points only — not on every action.

**Spam protection stays simple**
Auth + rate limits + CAPTCHA + reporting. Do not introduce ML-based spam detection.

---

## 7. What NOT To Do

- Do not add new dependencies without asking
- Do not change the database schema without discussing first
- Do not run destructive migrations
- Do not remove uniqueness constraints from the database
- Do not store votes inside resource objects (votes table must stay normalized)
- Do not add Redux, GraphQL, Prisma, or any additional data layer
- Do not use raw SQL — use the Supabase client
- Do not suggest microservices or splitting into separate services
- Do not add comment or discussion features
- Do not suggest switching auth providers (Supabase Auth is decided)
- Do not suggest switching database host (Supabase is decided)

---

## 8. Current State / Active Context

*Update this section at the start/end of each working session.*

**Immediate next steps (in order):**
1. Create database schema in Supabase dashboard
2. `lib/canonicalizeUrl.ts` — URL normalization + hashing
3. `app/api/resources/route.ts` — POST endpoint with duplicate protection

**Not started yet:**
- Ranking algorithm implementation
- Spam reporting endpoint
- Rate limiting
- Captcha integration
- Any UI work