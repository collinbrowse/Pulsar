# Team Workflow Guide

This document outlines the development workflow and best practices for the Pulsar iOS project.

## Branch Strategy

### Main Branches

- **`main`**: Production-ready code
  - Protected branch
  - Requires PR approval
  - All CI checks must pass

- **`milestone-*-*`**: Feature branches
  - Example: `milestone-2-auth-profiles`
  - Created for each milestone
  - Merged to `main` when complete

### Branch Naming

- **Features**: `feature/description` or `milestone-N-feature`
- **Bugs**: `fix/description` or `bugfix/description`
- **CI/CD**: `ci/description`
- **Docs**: `docs/description`

## Development Workflow

### 0. Initial Setup (First Time Only)

```bash
# Clone the repository
git clone <repository-url>
cd pulsar

# Install git hooks (runs SwiftLint before commits)
./scripts/setup-git-hooks.sh
```

### 1. Start New Feature

```bash
# Create feature branch
git checkout -b milestone-3-activity-import main

# Or for smaller features
git checkout -b feature/add-activity-filter main
```

### 2. Make Changes

- Write code following [Style Guide](style_guide.md)
- Write tests for new functionality
- Update documentation if needed

### 3. Pre-Commit Checks

**Automatic (via pre-commit hook)**:
The hook runs automatically when you commit. If violations are found, the commit is blocked.

**Manual (optional)**:
```bash
# Run linting
./scripts/run-lint.sh

# Run formatting check
./scripts/run-format.sh

# Run tests
xcodebuild test -project Pulsar.xcodeproj -scheme PulsarTests

# Fix any issues
swiftlint --fix
./scripts/run-format-fix.sh
```

### 4. Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional commit message
# Pre-commit hook runs automatically here
git commit -m "feat: add activity import feature"

# If hook finds violations:
# 1. Fix issues (or run: swiftlint --fix)
# 2. Stage fixes: git add .
# 3. Commit again: git commit -m "feat: add activity import feature"

# Push to remote
git push origin milestone-3-activity-import
```

### 5. Create Pull Request

1. **Create PR** on GitHub
2. **Fill out PR template**:
   - Description of changes
   - Test plan
   - Screenshots (if UI changes)
   - Checklist

3. **Wait for CI**:
   - Build & test
   - Linting
   - Coverage
   - Danger checks

4. **Address feedback**:
   - Fix CI failures
   - Address code review comments
   - Update PR as needed

### 6. Merge to Main

- **Requires**: All CI checks passing
- **Requires**: At least one approval
- **After merge**: Delete feature branch

## Code Review Process

### For Authors

1. **Self-review** before requesting review
2. **Write clear PR description**
3. **Add screenshots** for UI changes
4. **Respond to feedback** promptly
5. **Keep PR focused** (one feature/bug fix)

### For Reviewers

1. **Review within 24 hours** if possible
2. **Be constructive** in feedback
3. **Approve** when satisfied
4. **Request changes** with clear explanations

## Testing Workflow

### Unit Tests

- **Write tests** for all new functionality
- **Run tests locally** before committing
- **Ensure tests pass** in CI

### UI Tests

- **Write UI tests** for user flows
- **Test on multiple devices** if possible
- **Capture screenshots** for visual regression

### Test Coverage

- **Target**: 80% coverage
- **Enforcement**: PR fails if below threshold
- **Review coverage reports** regularly

## Documentation Workflow

### Code Documentation

- **Document public APIs** with `///` comments
- **Update documentation** when changing APIs
- **Follow Swift documentation conventions**

### Project Documentation

- **Update README** for major changes
- **Update CHANGELOG.md** for user-facing changes
- **Keep documentation** in sync with code

## Release Workflow

### Preparing Release

1. **Create release branch**: `release/v1.0.1`
2. **Update version** in Xcode
3. **Update CHANGELOG.md**
4. **Run final tests**
5. **Merge to main**
6. **Tag release**: `v1.0.1`

### Deploying Release

1. **Build archive** in Xcode
2. **Distribute to TestFlight**
3. **Test in TestFlight**
4. **Distribute to App Store**
5. **Submit for review**

See [Release Process](release_process.md) for details.

## Daily Workflow

### Morning

1. **Pull latest changes**: `git pull origin main`
2. **Check CI status** for your branches
3. **Review PRs** assigned to you

### During Development

1. **Work on feature branch**
2. **Commit frequently** with clear messages
3. **Push regularly** to backup work
4. **Run tests** before committing

### End of Day

1. **Commit and push** current work
2. **Update PR** if needed
3. **Check CI status**

## Best Practices

### Git

- **Commit often** with clear messages
- **Use conventional commits** format
- **Keep commits focused** (one change per commit)
- **Write descriptive commit messages**

### Code

- **Follow style guide** ([Style Guide](style_guide.md))
- **Write tests** for new code
- **Keep functions small** (< 50 lines)
- **Keep files focused** (< 500 lines)

### Communication

- **Update PR descriptions** as work progresses
- **Respond to reviews** promptly
- **Ask questions** if unclear
- **Share knowledge** with team

## Troubleshooting

### CI Failures

1. **Check workflow logs** in GitHub
2. **Reproduce locally** with same commands
3. **Fix issues** and push again
4. **Ask for help** if stuck

### Merge Conflicts

1. **Pull latest main**: `git pull origin main`
2. **Rebase feature branch**: `git rebase main`
3. **Resolve conflicts**
4. **Continue rebase**: `git rebase --continue`
5. **Force push**: `git push --force-with-lease`

### Test Failures

1. **Run tests locally** to reproduce
2. **Check test logs** for details
3. **Fix failing tests**
4. **Ensure all tests pass** before pushing

## Related Documentation

- [CI Setup Guide](README_CI_SETUP.md) - CI/CD setup
- [Style Guide](style_guide.md) - Code style rules
- [Testing Guide](testing.md) - Testing documentation
- [Release Process](release_process.md) - Release workflow


