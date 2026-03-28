# Supabase Feedback Setup

Last updated: 2026-03-29

This project keeps the frontend integration intentionally simple:

- The web app submits feedback to `VITE_FEEDBACK_ENDPOINT`
- The backend endpoint stores feedback in Supabase
- The frontend does **not** use the Supabase SDK directly

That keeps the current implementation easy to migrate later.

## What is included in this repo

- SQL migration: [20260329070000_create_feedback_submissions.sql](/Volumes/data/Projects/Picsew/supabase/migrations/20260329070000_create_feedback_submissions.sql)
- Edge Function: [feedback/index.ts](/Volumes/data/Projects/Picsew/supabase/functions/feedback/index.ts)
- Client contract: [feedback-backend-contract.md](/Volumes/data/Projects/Picsew/docs/feedback-backend-contract.md)

## Recommended Supabase setup

1. Create a new Supabase project
2. Run the SQL migration
3. Deploy the `feedback` Edge Function
4. Expose the function without JWT verification
5. Point `VITE_FEEDBACK_ENDPOINT` to the function URL

## SQL schema

The schema stores common fields in top-level columns and category-specific fields inside `metadata`:

- `id`
- `created_at`
- `status`
- `source`
- `category`
- `platform`
- `app_version`
- `locale`
- `email`
- `message`
- `metadata`

This structure keeps the client payload close to the current web types while still making the key operational fields easy to query.

## Deploy steps

Assuming you have the Supabase CLI installed and authenticated:

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
supabase functions deploy feedback --no-verify-jwt
```

Why `--no-verify-jwt`:

- the current web app calls a plain HTTPS endpoint
- we are not yet issuing logged-in user tokens
- this keeps the frontend integration lightweight

## Environment variables

In the frontend `.env`:

```bash
VITE_FEEDBACK_ENDPOINT=https://YOUR_PROJECT_REF.supabase.co/functions/v1/feedback
VITE_FEEDBACK_ANON_KEY=YOUR_SUPABASE_ANON_KEY
VITE_APP_VERSION=0.1.0
```

The function itself uses Supabase-managed environment variables:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

These are available inside Supabase Edge Functions and should not be exposed to the browser.

The browser only needs the public `anon` key so it can call the JWT-protected function endpoint.

## Query examples

Newest feedback first:

```sql
select id, created_at, category, platform, status, message
from public.feedback_submissions
order by created_at desc
limit 100;
```

Processing failures only:

```sql
select
  id,
  created_at,
  message,
  metadata->>'errorMessage' as error_message,
  metadata->>'stage' as stage
from public.feedback_submissions
where category = 'processing_failure'
order by created_at desc;
```

## Why this is migration-friendly

- The frontend only knows about `VITE_FEEDBACK_ENDPOINT`
- The payload shape is defined in app code, not in a vendor SDK
- Supabase is acting as a storage provider, not as the app boundary

If you later move away from Supabase, you can keep:

- the same frontend feedback form
- the same payload schema
- the same endpoint contract

and only replace the backend implementation.
