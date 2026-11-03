# Connect AccessWay AI to Supabase

This setup enables email/password accounts, a profile row for each account, and cloud submission of barrier reports.

## 1. Create the Supabase project

1. Open [Supabase](https://supabase.com/dashboard) and create a new project.
2. Give it a name such as `accessway-ai`.
3. Choose a strong database password and keep it private.
4. Select the nearest available region for your users.
5. Wait until the project finishes provisioning.

## 2. Create the database and security policies

1. Open the project in Supabase.
2. Go to **SQL Editor** and create a new query.
3. Open this repository file: [supabase/schema.sql](./schema.sql).
4. Copy the complete SQL into the editor and run it.
5. Confirm that the `profiles`, `places`, `accessibility_features`, and `barrier_reports` tables exist.

The schema enables Row Level Security (RLS). Users can read and update only their own profile, and can read and submit only their own barrier reports. Public users can read only published place and feature records. Community observations stay labelled as community-reported; this schema does not certify accessibility.

## 3. Enable email authentication

1. In Supabase, open **Authentication → Providers**.
2. Enable **Email**.
3. Keep email confirmation enabled for a real deployment. New accounts may need to confirm their email before signing in.
4. Configure the project's site URL and allowed redirect URLs if you later add password-reset or email-link flows.

## 4. Add build configuration to GitHub

In the GitHub repository, open **Settings → Secrets and variables → Actions**. Add these repository secrets:

| Secret name | Value |
|---|---|
| `SUPABASE_URL` | The Project URL shown in Supabase project API settings |
| `SUPABASE_PUBLISHABLE_KEY` | The project's publishable key |

The publishable key is designed for use in client apps and is protected by RLS. **Never add a Supabase secret key or `service_role` key to Flutter, GitHub build variables, or the app.** Do not send either secret to anyone in chat.

## 5. Build Android and Windows apps

1. Open the repository's **Actions** tab.
2. Select **Build AccessWay AI**.
3. Choose **Run workflow** on the `main` branch.
4. Wait for both jobs to pass.
5. Download the `accessway-ai-android-apk` and `accessway-ai-windows` artifacts from that run.

The workflow passes the two values to Flutter as build-time defines. If the secrets are not present yet, the app remains in local demo mode.

## Current implementation boundary

- Supabase email sign-up and sign-in are wired into the app.
- The Settings screen can sign out.
- Authenticated barrier reports are inserted into `barrier_reports`; RLS keeps each report private to its reporter.
- The existing sample places and accessibility passports are still demo records. The public map uses OpenStreetMap data; it is not yet backed by the Supabase `places` table.
- AI obstacle recognition, accessible route scoring, institution review tools, photo upload, and AccessWay Scout BLE are not implemented by this setup.
