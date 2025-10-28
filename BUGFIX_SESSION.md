# 🐛 Bug Fix Session - Profile & Authentication Issues

**Date:** October 28, 2025  
**Session:** Post-Milestone 4 Testing  
**Reporter:** User Testing  

---

## 🎯 Issues Reported

### Issue #1: Sign-In Creates New Accounts ❌ **NOT YET FIXED**
**Status:** Deferred - Needs further investigation  
**Severity:** Medium (UX issue)

**Description:**  
When user taps "Sign In" on the welcome screen, it appears to create a new account instead of showing an error for non-existent accounts.

**Console Message:**  
```
"it allows me to sign in even though the console says it created a new user"
```

**Expected Behavior:**  
- Sign-in should only work for existing accounts
- If account doesn't exist, show clear error: "No account found. Please sign up first."
- Optional: Offer to navigate to sign-up screen with pre-filled email

**Root Cause:** TBD - Need to investigate Supabase Auth API response  

**Action Items:**
- [ ] Add unit test: `testSignInWithNonExistentAccount()`
- [ ] Add UI test: `testSignInErrorHandling()`
- [ ] Improve error messaging in SignInView
- [ ] Consider adding "Don't have an account?" link

---

### Issue #2: Haptic Feedback Warning Cluttering Console ⚠️ **DOCUMENTED**
**Status:** Known Simulator Issue - No Code Fix Required  
**Severity:** Low (cosmetic only)

**Error Message:**  
```
<_UIKBFeedbackGenerator: 0x600003519ad0>: Error creating CHHapticPattern: 
Error Domain=NSCocoaErrorDomain Code=260 
"The file "hapticpatternlibrary.plist" couldn't be opened because there is no such file."
```

**Root Cause:**  
iOS 26 Simulator bug - haptic library files not present in simulator environment.

**Impact:**  
- Cosmetic only - doesn't affect functionality
- Only appears in simulator, not on real devices
- Clutters console during development

**Workaround:**  
- Ignore warning during simulator testing
- Test haptics on real device if needed

**Alternative Solutions (not implemented):**
1. Add custom console filtering
2. Add scheme launch argument (would require manual Xcode config)
3. Wait for Apple to fix in future Xcode/iOS Simulator release

**Decision:** No action needed - simulator-only cosmetic issue

---

### Issue #3: Profile Not Found After Sign-In ✅ **FIXED**
**Status:** Fixed  
**Severity:** Critical (blocking feature)

**Description:**  
After signing in for the second time, user is sent to "Complete Profile" screen despite profile existing in database.

**Console Logs:**  
```
✅ SignIn Success: userID=14bb222f-e47c-47c9-ae90-a8fb3070d3cb
Fetching profiles for user: 14bb222f-e47c-47c9-ae90-a8fb3070d3cb
📤 Fetch Request: GET .../profiles?...user_id=eq.14bb222f...
✅ Fetch Success: 2 bytes received  <-- Empty array []
No profile found - navigating to profile creation
```

**Root Cause:**  
1. Auto-trigger (`on_auth_user_created`) not reliably creating profile rows
2. Profile completion used UPDATE instead of UPSERT
3. UPDATE on non-existent row returns 200 OK but doesn't create the row
4. Fetch returns empty array `[]` because no profile row exists

**The Fix:**  
✅ **Added UPSERT functionality to SupabaseClient**
```swift
func upsert<T: Encodable>(
    table: String,
    data: T,
    accessToken: String
) async throws
```

✅ **Changed AuthenticationService.updateProfile() to use UPSERT**
- Now uses POST with `Prefer: resolution=merge-duplicates` header
- Creates profile if doesn't exist
- Updates profile if exists
- Guaranteed to succeed if data is valid

✅ **Enhanced Logging**
- Fetch now logs actual response JSON
- Fetch logs decoded item count
- Update logs response to verify rows were affected
- Warns if update returns empty response

**Testing:**
- [x] Build passes
- [ ] Unit test: `testUpsertCreatesNewProfile()`
- [ ] Unit test: `testUpsertUpdatesExistingProfile()`
- [ ] UI test: `testSignInWithExistingProfile()`
- [ ] UI test: `testCompleteProfileFlow()`

---

## 📊 Impact Summary

| Issue | Status | Impact | User Experience |
|-------|--------|--------|-----------------|
| #1: Sign-in UX | Deferred | Medium | Confusing for users |
| #2: Haptic Warning | Documented | Low | Console clutter only |
| #3: Profile Not Found | ✅ Fixed | Critical | Blocking authentication |

---

## 🧪 Test Coverage Required

### Unit Tests to Add

**Authentication Tests:**
```swift
@Test("Sign-in with non-existent account should throw error")
func testSignInWithNonExistentAccount()

@Test("Upsert should create new profile")
func testUpsertCreatesNewProfile()

@Test("Upsert should update existing profile")
func testUpsertUpdatesExistingProfile()

@Test("Profile fetch after upsert should succeed")
func testProfilePersistence()
```

**Integration Tests:**
```swift
@Test("Complete profile flow end-to-end")
func testCompleteProfileFlow()

@Test("Sign in with existing profile bypasses creation")
func testSignInWithExistingProfile()
```

### UI Tests to Add

**AuthenticationUITests.swift:**
```swift
func testSignInWithInvalidCredentials()
func testSignInWithNonExistentAccount()
func testCompleteSignUpAndProfileFlow()
func testSignOutAndSignInAgain()
func testProfileDataPersistsAcrossSignIns()
```

---

## 🔧 Technical Details

### UPSERT Implementation

**PostgREST Upsert Syntax:**
```http
POST /profiles
Prefer: resolution=merge-duplicates
Content-Profile: public
Content-Type: application/json

{
  "user_id": "14bb222f...",
  "username": "collinbrowse",
  "full_name": "Collin Browse",
  ...
}
```

**How it Works:**
1. Tries to INSERT the row
2. If conflict on PRIMARY KEY (`user_id`), merges with existing row
3. Returns the created/updated row
4. Guarantees row exists after operation

**Advantages:**
- No more silent failures
- Works for new AND existing users
- Atomic operation
- Single API call

---

## 📈 Next Steps

1. **Immediate (Critical):**
   - [x] Commit UPSERT fix
   - [ ] User testing to confirm profile persistence works
   - [ ] Add comprehensive test coverage

2. **Short-term (High Priority):**
   - [ ] Fix Issue #1 (sign-in UX)
   - [ ] Add error handling for all auth flows
   - [ ] Improve error messages for users

3. **Medium-term (Nice to Have):**
   - [ ] Add retry logic for network failures
   - [ ] Add offline support for profile data
   - [ ] Implement profile caching

---

## 🎯 Success Criteria

**For Issue #3 (Profile Persistence):**
- ✅ Build passes
- ⏳ User can complete profile once
- ⏳ User can sign out and sign in
- ⏳ User goes directly to main app (no profile creation)
- ⏳ Profile data persists correctly
- ⏳ All unit tests pass
- ⏳ All UI tests pass

**Testing Checklist:**
1. Sign up with new account
2. Complete profile
3. Verify main app loads
4. Sign out
5. Sign in again
6. Verify main app loads (no profile creation)
7. Verify profile data is correct

---

## 📝 Lessons Learned

1. **Always use UPSERT for user-specific data**
   - Can't rely on triggers to create rows
   - UPDATE on missing row is silent failure
   - UPSERT guarantees consistency

2. **Log response data, not just status codes**
   - 200 OK doesn't mean success
   - Empty response `[]` vs populated response is critical
   - Helps debug silent failures

3. **Test the entire flow, not just happy path**
   - Sign-up works, but sign-in with existing user failed
   - Multiple sign-ins revealed the bug
   - User testing is invaluable

4. **Simulator warnings can be misleading**
   - Haptic feedback warning is not our bug
   - Document known simulator issues
   - Don't waste time fixing platform bugs

---

## 🚀 Deployment Notes

**Before deploying to production:**
- [ ] All tests passing
- [ ] User testing complete
- [ ] Issue #1 addressed
- [ ] Error handling comprehensive
- [ ] Analytics tracking profile creation success rate
- [ ] Crashlytics monitoring auth failures

**Monitoring:**
- Track "profile_created" events
- Monitor "profile_updated" events
- Alert on high auth failure rates
- Log all UPSERT operations

---

**Session End:** In Progress  
**Next Review:** After user testing confirmation

