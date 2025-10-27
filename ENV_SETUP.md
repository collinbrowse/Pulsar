# Environment Variable Setup Guide

This document explains how to configure environment variables for the Pulsar app.

## Overview

Pulsar uses environment variables for configuration to keep secrets out of source code. This follows security best practices and makes it easy to configure different environments (development, staging, production).

## Files

- `.env.example` - Template with all available variables (committed to Git)
- `.env.local` - Your local configuration (NOT committed to Git)
- `.gitignore` - Ensures `.env.local` is never committed

## Setup Instructions

### 1. Create Local Environment File

```bash
cp .env.example .env.local
```

### 2. Configure Supabase (Required)

Sign up for a free Supabase account at https://supabase.com and create a project.

Add your Supabase credentials to `.env.local`:

```bash
SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Find these values in your Supabase project:
- Go to **Settings → API**
- Copy **Project URL** → `SUPABASE_URL`
- Copy **anon/public key** → `SUPABASE_ANON_KEY`

### 3. Configure Analytics (Optional)

#### PostHog

Sign up at https://posthog.com (free tier available).

```bash
POSTHOG_API_KEY=phc_xxxxxxxxxxxxxxxxxxxxx
ENABLE_ANALYTICS=true
```

Find your API key:
- Go to **Project Settings → Project API Key**

#### Firebase Crashlytics

Follow Firebase setup guide at https://firebase.google.com/docs/crashlytics/get-started

```bash
ENABLE_CRASHLYTICS=true
```

Note: Firebase configuration also requires adding `GoogleService-Info.plist` to your Xcode project.

### 4. Configure Mapbox (Optional)

Sign up at https://mapbox.com (free tier available).

```bash
MAPBOX_TOKEN=pk.xxxxxxxxxxxxxxxxxxxxx
USE_MAPBOX=true
```

Find your access token:
- Go to **Account → Tokens**
- Copy your **default public token**

## Using Environment Variables in Xcode

### Method 1: Xcode Scheme (Recommended for Development)

1. Open your Xcode project
2. Go to **Product → Scheme → Edit Scheme**
3. Select **Run → Arguments**
4. Add environment variables under **Environment Variables**:
   ```
   Name: SUPABASE_URL
   Value: https://xxxxxxxxxxxxx.supabase.co
   
   Name: SUPABASE_ANON_KEY
   Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```
5. Check ✅ next to each variable to enable it

### Method 2: xcconfig File (Recommended for CI/CD)

Create `Pulsar/Config.xcconfig`:

```
SUPABASE_URL = https:/$()/xxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Add to your Xcode project and set in **Project → Info → Configurations**.

**Important**: Add `Config.xcconfig` to `.gitignore` if it contains secrets!

### Method 3: Info.plist + Build Settings (Recommended for Production)

1. Add placeholders to `Info.plist`:
   ```xml
   <key>SUPABASE_URL</key>
   <string>$(SUPABASE_URL)</string>
   ```

2. Set actual values in **Build Settings → User-Defined Settings**
3. For production builds, use Xcode Cloud or CI/CD secrets

## CI/CD Configuration

### GitHub Actions

Add secrets to your repository:
1. Go to **Settings → Secrets and variables → Actions**
2. Add **New repository secret**:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `POSTHOG_API_KEY` (if using analytics)

These will be available as environment variables in CI workflows.

## Security Best Practices

✅ **DO**:
- Use `.env.local` for local development (not committed)
- Use Xcode schemes for development environment variables
- Use CI/CD secrets for production keys
- Rotate keys regularly
- Use different keys for development, staging, and production

❌ **DON'T**:
- Commit `.env.local` or any file with secrets to Git
- Hardcode API keys in Swift code
- Share API keys in Slack, email, or other channels
- Use production keys in development
- Push debug builds with production keys to TestFlight

## Verification

### Check Environment Configuration

Run the app in Xcode. Check the console for:

```
✅ Environment configured successfully
```

If you see:
```
⚠️ Environment not fully configured - check API keys
```

This means `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing or empty.

### Verify Feature Flags

Feature flags will log their status:
```
Analytics disabled via feature flag
Crashlytics disabled via feature flag
```

To enable:
```bash
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
```

## Troubleshooting

### "Environment not fully configured"

**Solution**: Make sure you've set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in Xcode scheme or `.env.local`.

### "PostHog API key not configured"

**Solution**: This is expected if you haven't set up PostHog. Set `POSTHOG_API_KEY` to enable analytics, or leave `ENABLE_ANALYTICS=false`.

### Environment variables not loading

**Solution**: 
1. Check Xcode scheme: **Product → Scheme → Edit Scheme → Run → Arguments**
2. Verify environment variables are checked (✅)
3. Clean build folder: **Product → Clean Build Folder**
4. Rebuild and run

### CI/CD build failing

**Solution**:
1. Verify secrets are set in GitHub repository settings
2. Check workflow file (`.github/workflows/ci.yml`) is using correct secret names
3. Ensure secrets are not empty or contain whitespace

## Example Configuration

### Development (Local)

```bash
# .env.local (not committed)
SUPABASE_URL=https://dev-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dev_key
POSTHOG_API_KEY=phc_dev_key
ENABLE_ANALYTICS=false
ENABLE_CRASHLYTICS=false
USE_MAPBOX=false
```

### Production (CI/CD)

Stored as GitHub Secrets:
```
SUPABASE_URL=https://prod-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.prod_key
POSTHOG_API_KEY=phc_prod_key
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
USE_MAPBOX=false
```

## Further Reading

- [Supabase Documentation](https://supabase.com/docs)
- [PostHog iOS SDK](https://posthog.com/docs/integrate/client/ios)
- [Firebase Crashlytics iOS](https://firebase.google.com/docs/crashlytics/get-started?platform=ios)
- [Mapbox iOS SDK](https://docs.mapbox.com/ios/)

