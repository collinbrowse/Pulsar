# Release Process

This document outlines the release process for Pulsar iOS application.

## Release Types

### Patch Release (PATCH)

**When**: Bug fixes, minor improvements

**Process**:
1. Create release branch: `release/v1.0.1`
2. Fix bugs
3. Update CHANGELOG.md
4. Update version to `1.0.1`
5. Merge to `main`
6. Tag release: `v1.0.1`
7. Deploy to TestFlight
8. Deploy to App Store (after testing)

### Minor Release (MINOR)

**When**: New features (backward compatible)

**Process**:
1. Create release branch: `release/v1.1.0`
2. Implement features
3. Update CHANGELOG.md
4. Update version to `1.1.0`
5. Merge to `main`
6. Tag release: `v1.1.0`
7. Deploy to TestFlight
8. Deploy to App Store (after testing)

### Major Release (MAJOR)

**When**: Breaking changes

**Process**:
1. Create release branch: `release/v2.0.0`
2. Implement breaking changes
3. Update CHANGELOG.md with migration guide
4. Update version to `2.0.0`
5. Merge to `main`
6. Tag release: `v2.0.0`
7. Deploy to TestFlight
8. Deploy to App Store (after extended testing)

## Release Workflow

### 1. Preparation

```bash
# Create release branch
git checkout -b release/v1.0.1 main

# Update version in Xcode
# Marketing Version: 1.0.1
# Current Project Version: Increment build number
```

### 2. Update Documentation

```bash
# Update CHANGELOG.md
# Add entries under [Unreleased] or new version section
```

### 3. Final Testing

```bash
# Run all tests
xcodebuild test -project Pulsar.xcodeproj -scheme PulsarTests

# Run UI tests
xcodebuild test -project Pulsar.xcodeproj -scheme PulsarUITests

# Check linting
./scripts/run-lint.sh
./scripts/run-format.sh
```

### 4. Commit and Tag

```bash
# Commit changes
git add .
git commit -m "chore: release v1.0.1"

# Merge to main
git checkout main
git merge release/v1.0.1

# Create tag
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin main --tags
```

### 5. Deploy

#### TestFlight

1. Open Xcode
2. Product → Archive
3. Distribute App → TestFlight
4. Upload build
5. Notify beta testers

#### App Store

1. Open Xcode
2. Product → Archive
3. Distribute App → App Store Connect
4. Submit for review
5. Wait for approval

## CHANGELOG Format

```markdown
## [1.0.1] - 2025-01-15

### Fixed
- Fixed crash when importing malformed GPX files
- Resolved authentication token refresh issue

### Changed
- Improved error messages for file import failures

## [1.0.0] - 2025-01-01

### Added
- Initial release
- Activity import (GPX, TCX, FIT)
- Social feed
- User authentication
```

## Release Notes Template

```markdown
# Pulsar v1.0.1

## What's New
- Bug fixes and improvements

## Bug Fixes
- Fixed crash when importing malformed GPX files
- Resolved authentication token refresh issue

## Improvements
- Improved error messages for file import failures

## Known Issues
- None

## Upgrade Notes
No special upgrade steps required.
```

## Post-Release

### 1. Monitor

- Check App Store Connect for crash reports
- Monitor analytics for issues
- Review user feedback

### 2. Hotfix (if needed)

If critical bugs are found:

```bash
# Create hotfix branch from release tag
git checkout -b hotfix/v1.0.2 v1.0.1

# Fix bugs
# Update CHANGELOG.md
# Update version to 1.0.2

# Merge to main and release
git checkout main
git merge hotfix/v1.0.2
git tag -a v1.0.2 -m "Hotfix v1.0.2"
git push origin main --tags
```

### 3. Documentation

- Update release notes
- Update version in README.md
- Archive release branch

## Related Documentation

- [Deployment Guide](deployment.md) - Deployment process
- [CI Overview](ci_overview.md) - CI/CD setup
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow
