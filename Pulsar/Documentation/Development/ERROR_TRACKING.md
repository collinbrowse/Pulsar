# 📊 Error Tracking & Product Analytics

**Last Updated:** October 28, 2025  
**For:** Product Team, Analytics Team, Engineering Team

---

## 🎯 Overview

**ALL errors** in the Pulsar app are automatically tracked and sent to:
1. ✅ **PostHog** - For product analytics and insights
2. ✅ **Firebase Crashlytics** - For crash reporting
3. ✅ **Console Logs** - For development debugging

This document explains what data is captured and how your product team can use it.

---

## 📈 What Gets Tracked in PostHog

### Event: `error_detailed`

Every error generates a `error_detailed` event in PostHog with the following properties:

| Property | Description | Example |
|----------|-------------|---------|
| `error_type` | Type of error encountered | `userAlreadyExists`, `invalidCredentials` |
| `user_message` | What the user sees | "An account with this email already exists..." |
| `technical_details` | Technical description for engineering | "User already exists (422: user_already_exists)" |
| `context` | Where the error occurred | "Sign Up", "Sign In", "Profile Creation" |
| `severity` | Impact level | `low`, `medium`, `high`, `critical` |
| `recoverable` | Can the app auto-recover? | `true` (auto sign-in), `false` (show error) |
| `platform` | Always `iOS` | `iOS` |
| `app_version` | App version number | `1.0.0` |

### Event: `error_occurred`

Basic error event for simple tracking:

| Property | Description |
|----------|-------------|
| `error_type` | Swift error type |
| `error_description` | Error description |
| Any additional context | Varies by error |

---

## 🚨 Error Severity Levels

Understanding error impact for prioritization:

### Critical (🔴 Requires Immediate Fix)
- **Impact:** App-breaking, blocks core functionality
- **Examples:**
  - Authentication service down
  - Server errors (5xx)
  - Database connection failures
- **User Experience:** Cannot use app at all
- **SLA:** Fix within 1 hour

### High (🟠 Priority Fix)
- **Impact:** Blocks key features but app partially usable
- **Examples:**
  - Sign-up failures
  - Invalid credentials
  - Network errors
  - User already exists
- **User Experience:** Core flows blocked
- **SLA:** Fix within 4 hours

### Medium (🟡 Standard Fix)
- **Impact:** Impacts UX but workarounds exist
- **Examples:**
  - Email not confirmed
  - Weak password
  - Invalid email format
  - Invalid username format
- **User Experience:** Minor inconvenience
- **SLA:** Fix within 1 day

### Low (🟢 Nice to Fix)
- **Impact:** Cosmetic, user can easily correct
- **Examples:**
  - Form validation errors
  - User-correctable input errors
- **User Experience:** Minimal impact
- **SLA:** Fix within 1 week

---

## 📊 PostHog Dashboards

### Recommended Views for Product Team

**1. Error Rate Dashboard**
```
Event: error_detailed
Group by: error_type
Time range: Last 7 days
```

**2. Critical Errors Only**
```
Event: error_detailed
Filter: severity = "critical"
Alert: > 10 in 1 hour
```

**3. User Impact Analysis**
```
Event: error_detailed
Group by: context
Filter: severity IN ["high", "critical"]
```

**4. Recovery Success Rate**
```
Event: error_detailed
Filter: recoverable = true
Group by: error_type
```

**5. Error Trends**
```
Event: error_detailed
Visualization: Line chart
Group by: severity
Time range: Last 30 days
```

---

## 🔍 Common Error Patterns

### Authentication Errors

**`userAlreadyExists` (High Severity, Recoverable)**
- **Trigger:** User tries to sign up with existing email
- **User Message:** "An account with this email already exists. Signing you in..."
- **Action:** App automatically signs user in
- **Product Insight:** Track conversion funnel - users may have forgotten they signed up

**`invalidCredentials` (High Severity)**
- **Trigger:** Wrong email/password combination
- **User Message:** "Incorrect email or password. Please try again."
- **Action:** User must correct credentials
- **Product Insight:** High rate may indicate UX confusion or password reset needed

**`emailNotConfirmed` (Medium Severity)**
- **Trigger:** User hasn't verified email
- **User Message:** "Please confirm your email address before signing in."
- **Action:** User must check email
- **Product Insight:** Track email confirmation rates

### Network Errors

**`networkError` (High Severity)**
- **Trigger:** No internet connection or network failure
- **User Message:** "Unable to connect. Please check your internet connection."
- **Action:** User must check connectivity
- **Product Insight:** Track by geography, may indicate infrastructure issues

**`serverError` (Critical Severity)**
- **Trigger:** Backend 5xx errors
- **User Message:** "Our servers are experiencing issues. Please try again later."
- **Action:** None - requires backend fix
- **Product Insight:** IMMEDIATE alert to engineering

### Validation Errors

**`weakPassword` (Medium Severity)**
- **Trigger:** Password < 8 characters
- **User Message:** "Password must be at least 8 characters long."
- **Action:** User must choose stronger password
- **Product Insight:** Track to improve password UX

**`invalidEmail` (Medium Severity)**
- **Trigger:** Malformed email address
- **User Message:** "Please enter a valid email address."
- **Action:** User must correct email
- **Product Insight:** Track common typos

---

## 📉 Monitoring & Alerts

### Recommended Alerts (PostHog)

**1. Critical Error Spike**
```
Event: error_detailed
Filter: severity = "critical"
Threshold: > 10 in 1 hour
Action: Notify #engineering-alerts Slack
```

**2. High Error Rate**
```
Event: error_detailed
Filter: severity IN ["high", "critical"]
Threshold: > 50 in 1 hour
Action: Notify #product-team Slack
```

**3. Specific Error Surge**
```
Event: error_detailed
Filter: error_type = "serverError"
Threshold: > 5 in 15 minutes
Action: Notify #ops-team Slack
```

**4. User Impact**
```
Event: error_detailed
Filter: recoverable = false AND severity = "high"
Threshold: > 100 unique users in 1 day
Action: Create Jira ticket automatically
```

---

## 🎯 Product Insights from Error Data

### Conversion Funnel Analysis
```
1. Track "Sign Up" button taps
2. Track error_detailed (context: "Sign Up")
3. Calculate: (Successful sign-ups) / (Sign-up attempts)
4. Identify drop-off points
```

### Feature Health Score
```
Feature Health = 1 - (Error Rate / Total Events)

Healthy: > 99% (< 1% errors)
Warning: 95-99% (1-5% errors)
Critical: < 95% (> 5% errors)
```

### User Experience Impact
```
Group errors by user_id (when available)
Identify: Users encountering multiple errors
Action: Proactive outreach, improve UX
```

---

## 🔧 Technical Implementation

### How Errors Are Logged

**1. Error Occurs in App**
```swift
// User tries to sign up with existing email
try await authService.signUp(...)
```

**2. ErrorManager Parses Error**
```swift
ErrorManager.shared.logError(error, context: "Sign Up")
```

**3. Categorized and Enriched**
```swift
AppError.userAlreadyExists
  ↓
severity: .high
recoverable: true
userMessage: "Account exists. Signing you in..."
technicalDetails: "user_already_exists (422)"
```

**4. Sent to PostHog**
```swift
ObservabilityManager.shared.reportErrorDetailed(
    error,
    errorType: "userAlreadyExists",
    userMessage: "...",
    technicalDetails: "...",
    context: "Sign Up",
    severity: .high,
    recoverable: true
)
```

**5. Tracked as Event**
```javascript
posthog.capture('error_detailed', {
    error_type: 'userAlreadyExists',
    user_message: 'Account exists...',
    severity: 'high',
    recoverable: true,
    // ... more properties
})
```

---

## 📱 User-Facing Messages

**All errors show user-friendly messages:**

| Technical Error | User Sees |
|----------------|-----------|
| `HTTP Error: 422` | ❌ NEVER SHOWN |
| `user_already_exists` | "Account exists. Signing you in..." |
| `invalid_credentials` | "Incorrect email or password." |
| `email_not_confirmed` | "Please confirm your email address." |
| `network_error` | "Check your internet connection." |
| `server_error` | "Our servers are experiencing issues." |

**Key Principle:** Users NEVER see technical errors, status codes, or JSON.

---

## 🎓 How to Use This Data

### For Product Managers
1. **Monitor error rates** in PostHog dashboard
2. **Identify pain points** in user flows
3. **Prioritize fixes** based on severity + frequency
4. **Track improvements** after deployments

### For Analytics Team
1. **Create dashboards** for error trends
2. **Set up alerts** for anomalies
3. **Correlate errors** with user cohorts
4. **Generate reports** for stakeholders

### For Customer Success
1. **Proactive outreach** to affected users
2. **Identify common issues** for FAQ
3. **Track resolution time** for support tickets
4. **Monitor user satisfaction** post-error

### For Engineering
1. **Debug with technical_details** field
2. **Reproduce errors** with context
3. **Validate fixes** with before/after metrics
4. **Prevent regressions** with alerts

---

## 📋 Checklist for New Features

When adding new features, ensure error tracking:

- [ ] All API calls wrapped in try/catch
- [ ] Errors passed to `ErrorManager.logError(error, context: "Feature Name")`
- [ ] User-friendly messages defined in `ErrorManager`
- [ ] Severity level assigned
- [ ] Recoverable flag set correctly
- [ ] PostHog dashboard updated
- [ ] Alerts configured for critical errors

---

## 🔗 Related Documentation

- `ErrorManager.swift` - Centralized error handling
- `ObservabilityManager.swift` - Analytics & crash reporting
- `AppError` enum - All error types
- `ErrorSeverity` enum - Severity levels

---

## 📞 Support

**Questions about error tracking?**
- Engineering: See `ErrorManager.swift` source code
- Product: Contact #product-team Slack
- Analytics: Contact #analytics-team Slack

**PostHog Access:**
- Dashboard: [Your PostHog URL]
- API Key: See `.env` file (secure)

---

**Document Version:** 1.0  
**Last Review:** October 28, 2025  
**Next Review:** November 28, 2025 (monthly)

