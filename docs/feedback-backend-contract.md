# Feedback Backend Contract

Last updated: 2026-03-29

Picsew's web feedback form submits a validated JSON payload to the endpoint in `VITE_FEEDBACK_ENDPOINT`.

If `VITE_FEEDBACK_ENDPOINT` is not configured, the app stores submissions locally in `localStorage` under `picsew_feedback_queue`.

## Request

- Method: `POST`
- Header: `Content-Type: application/json`
- Body: one validated feedback record

## Payload shape

The payload follows the union defined in [src/lib/feedback.ts](/Volumes/data/Projects/Picsew/src/lib/feedback.ts).

Common fields:

- `id`
- `createdAt`
- `status`
- `source`
- `category`
- `platform`
- `appVersion`
- `locale`
- `email`
- `message`

Category-specific fields depend on:

- `bug_report`
- `feature_request`
- `processing_failure`

## Response

Recommended:

- `200 OK` or `201 Created` for success
- a short JSON body such as `{ "ok": true }`

Any non-2xx response is treated as a submission failure by the client.

## Suggested first backend options

- Supabase Edge Function
- Firebase HTTPS Function
- Minimal Node/Express endpoint

For the current Picsew setup, the recommended first implementation is the Supabase Edge Function described in [supabase-feedback-setup.md](/Volumes/data/Projects/Picsew/docs/supabase-feedback-setup.md).

## Environment variable

```bash
VITE_FEEDBACK_ENDPOINT=https://your-domain.example.com/api/feedback
```

Supabase example:

```bash
VITE_FEEDBACK_ENDPOINT=https://YOUR_PROJECT_REF.supabase.co/functions/v1/feedback
VITE_FEEDBACK_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```
