# Danger Automation Guide

Danger is a tool that automates common code review tasks and enforces project standards in pull requests.

## Overview

Danger runs automatically on every pull request and performs various checks to ensure code quality and consistency.

## Rules and Checks

### PR Title Format

**Requirement**: PR titles must follow one of these formats:
- **Conventional Commits**: `feat: add feature`, `fix: bug fix`, `docs: update docs`
- **Milestone Format**: `milestone-2-auth`, `milestone-3-activity-import`

**Examples**:
- ✅ `feat: add activity import feature`
- ✅ `fix: resolve authentication bug`
- ✅ `milestone-2-auth-profiles`
- ❌ `Update code`
- ❌ `Fixes`

### Changelog Entry

**Requirement**: User-facing changes should include a CHANGELOG entry.

**Exceptions**: 
- Documentation-only changes (`docs:`)
- Chore changes (`chore:`)

**How to Fix**:
1. Edit `CHANGELOG.md`
2. Add entry under "Unreleased" section
3. Follow existing changelog format

### Documentation

**Requirement**: Public APIs (classes, structs, enums, protocols) should have documentation.

**Example**:
```swift
// Good
/// Service for managing user activities
public class ActivityService {
    // ...
}

// Bad
public class ActivityService {
    // ...
}
```

**How to Fix**:
Add documentation comments using `///` or `/** */` above public declarations.

### TODO/FIXME Comments

**Rules**:
- **TODO**: Warning (should be addressed)
- **FIXME**: Warning (should be addressed before merging)

**How to Fix**:
1. Address the TODO/FIXME
2. Create an issue and reference it
3. Remove the comment if no longer needed

### File Size Limits

**Requirement**: Files should not exceed 1MB.

**How to Fix**:
- Split large files into smaller modules
- Extract functionality into separate files
- Optimize assets (images, data files)

### UI Changes

**Requirement**: UI changes should include screenshots.

**How to Fix**:
1. Take screenshots of the new/changed UI
2. Add screenshots to PR description or comments
3. Or add screenshots to `docs/screenshots/` directory

### Test Coverage

**Requirement**: New functionality should include tests.

**Note**: Actual coverage enforcement is done in `ci-coverage.yml`. This is just a reminder.

**How to Fix**:
1. Add unit tests for new functionality
2. Add UI tests for UI changes
3. Ensure tests pass in CI

### Breaking Changes

**Requirement**: Breaking changes must be documented in CHANGELOG.md.

**How to Fix**:
1. Add entry to CHANGELOG.md under "Breaking Changes"
2. Clearly describe what changed and migration steps
3. Update version number if needed

### Hardcoded Secrets

**Requirement**: No hardcoded secrets in code.

**Patterns Checked**:
- `SUPABASE_ANON_KEY = "..."`
- `API_KEY = "..."`
- `SECRET = "..."`
- `PASSWORD = "..."`

**How to Fix**:
1. Remove hardcoded values
2. Use environment variables
3. Load from `.env` file or secure configuration

## Common Issues and Solutions

### Issue: PR Title Format Error

**Error**: "PR title should follow conventional commits format"

**Solution**:
```bash
# Update PR title to follow format
git commit --amend -m "feat: your feature description"
git push --force-with-lease
```

### Issue: Missing Changelog Entry

**Error**: "Consider adding a changelog entry"

**Solution**:
1. Edit `CHANGELOG.md`
2. Add entry:
```markdown
## [Unreleased]

### Added
- Your new feature description
```

### Issue: Missing Documentation

**Error**: "Public class should have documentation"

**Solution**:
```swift
/// Brief description of the class
/// 
/// Additional details if needed
public class MyClass {
    // ...
}
```

### Issue: Hardcoded Secret Detected

**Error**: "Potential hardcoded secret detected"

**Solution**:
```swift
// Bad
let apiKey = "hardcoded-key"

// Good
let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
```

## Disabling Danger Checks

Danger checks should not be disabled unless absolutely necessary. If you need to bypass a check:

1. **Discuss with team** - Explain why the check should be bypassed
2. **Update Dangerfile** - Add exception logic if appropriate
3. **Document decision** - Add comment explaining the exception

## Configuration

Danger configuration is in:
- **Dangerfile** - Main configuration file
- **.github/workflows/ci-danger.yml** - CI workflow

## Related Documentation

- [CI Overview](ci_overview.md) - CI/CD setup
- [Style Guide](style_guide.md) - Code style rules
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow




