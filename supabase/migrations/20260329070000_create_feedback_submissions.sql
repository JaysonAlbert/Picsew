create extension if not exists pgcrypto;

create table if not exists public.feedback_submissions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default timezone('utc'::text, now()),
  status text not null default 'new',
  source text not null,
  category text not null,
  platform text not null,
  app_version text not null,
  locale text not null,
  email text,
  message text not null,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists feedback_submissions_created_at_idx
  on public.feedback_submissions (created_at desc);

create index if not exists feedback_submissions_category_idx
  on public.feedback_submissions (category);

create index if not exists feedback_submissions_status_idx
  on public.feedback_submissions (status);

alter table public.feedback_submissions
  add constraint feedback_submissions_status_check
  check (status in ('new', 'triaged', 'closed'));

alter table public.feedback_submissions
  add constraint feedback_submissions_category_check
  check (category in ('bug_report', 'feature_request', 'processing_failure'));

alter table public.feedback_submissions
  add constraint feedback_submissions_platform_check
  check (platform in ('web', 'ios'));

alter table public.feedback_submissions
  enable row level security;

create policy "feedback_submissions_no_direct_client_access"
  on public.feedback_submissions
  for all
  using (false)
  with check (false);

comment on table public.feedback_submissions is
  'Structured feedback submissions from Picsew web and iOS clients.';

comment on column public.feedback_submissions.metadata is
  'Category-specific payload fields such as stage, severity, error_message, and video metadata.';
