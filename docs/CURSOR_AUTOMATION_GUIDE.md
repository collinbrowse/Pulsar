# Cursor Automation Guide

This guide explains how to use Cursor AI with the Pulsar iOS project's CI/CD automation setup.

## Overview

Cursor AI can leverage the CI/CD automation setup to:
- Understand project structure
- Generate code that passes linting
- Write tests that meet coverage requirements
- Follow project conventions automatically

## Project Structure

### Key Directories

```
Pulsar/
├── App/                    # App entry point
├── Features/               # Feature modules
├── Shared/                 # Shared code
│   ├── Models/            # SwiftData models
│   ├── Services/          # Business logic
│   ├── Networking/        # API clients
│   └── Utilities/         # Helper utilities
├── Documentation/         # Project documentation
└── ...

PulsarTests/               # Unit tests
PulsarUITests/             # UI tests

scripts/                   # Automation scripts
docs/                      # CI/CD documentation
.github/workflows/         # GitHub Actions
```

### Important Files

- **`.swiftlint.yml`**: Linting rules
- **`.swiftformat`**: Formatting rules
- **`Dangerfile`**: PR validation rules
- **Test Plans**: `PulsarTests/UnitTests.xctestplan`, `PulsarUITests/UITests.xctestplan`

## Using Cursor with CI/CD

### Code Generation

When generating code, Cursor should:

1. **Follow Style Guide**
   - Use tabs for indentation
   - Keep functions under 50 lines
   - Keep files under 500 lines
   - Follow naming conventions

2. **Include Tests**
   - Write unit tests for new functionality
   - Write UI tests for UI changes
   - Ensure tests pass locally

3. **Follow Architecture**
   - Use Services for business logic
   - Use SwiftData for persistence
   - Follow Root/Content view pattern

### Linting Integration

Cursor can check code before suggesting:

```bash
# Run linting check
./scripts/run-lint.sh

# Auto-fix issues
swiftlint --fix
./scripts/run-format-fix.sh
```

### Test Generation

When generating tests:

1. **Use Test Plans**
   - Unit tests: `PulsarTests/UnitTests.xctestplan`
   - UI tests: `PulsarUITests/UITests.xctestplan`

2. **Follow Test Patterns**
   - Swift Testing for unit tests
   - XCTest for UI tests
   - Mock external dependencies

3. **Ensure Coverage**
   - Target 80% coverage
   - Test edge cases
   - Test error conditions

## Cursor Rules Integration

### Project Rules

Cursor should follow project rules in `.cursor/rules/`:

- **swift-coding-standards.mdc**: Swift 6+ best practices
- **swiftui-view-composition.mdc**: View composition patterns
- **ui-architecture-patterns.mdc**: Architecture guidelines
- **project-structure.mdc**: File organization

### CI/CD Rules

Cursor should be aware of:

- **Linting rules**: `.swiftlint.yml`, `.swiftformat`
- **Coverage threshold**: 80%
- **PR requirements**: Danger rules in `Dangerfile`
- **Test requirements**: Test plans and organization

## Common Tasks

### Creating a New Feature

1. **Generate feature code** following architecture
2. **Generate tests** for new functionality
3. **Run linting**: `./scripts/run-lint.sh`
4. **Run formatting**: `./scripts/run-format.sh`
5. **Run tests**: `xcodebuild test -project Pulsar.xcodeproj -scheme PulsarTests`
6. **Update CHANGELOG.md** if user-facing

### Fixing Linting Issues

Cursor can help fix linting issues:

1. **Run linting**: `./scripts/run-lint.sh`
2. **Auto-fix**: `swiftlint --fix`
3. **Format code**: `./scripts/run-format-fix.sh`
4. **Verify**: Run linting again

### Writing Tests

Cursor can generate tests:

1. **Identify test target**: Unit or UI
2. **Follow test patterns**: Swift Testing or XCTest
3. **Mock dependencies**: Use protocols
4. **Ensure coverage**: Test all code paths

## Validation

### Before Committing

Cursor can validate code:

```bash
# Run validation script
./scripts/validate-ci-setup.sh

# Check linting
./scripts/run-lint.sh

# Check formatting
./scripts/run-format.sh

# Run tests
xcodebuild test -project Pulsar.xcodeproj -scheme PulsarTests
```

### CI Integration

Cursor can understand CI requirements:

- **Workflows**: `.github/workflows/*.yml`
- **Test plans**: `*.xctestplan`
- **Coverage**: 80% threshold
- **Danger**: PR validation rules

## Best Practices

### Code Generation

- **Follow style guide** automatically
- **Include tests** for new code
- **Follow architecture** patterns
- **Update documentation** when needed

### Error Handling

- **Use specific error types**
- **Handle errors gracefully**
- **Provide user-friendly messages**

### Testing

- **Write tests first** (TDD)
- **Test edge cases**
- **Mock external dependencies**
- **Ensure coverage**

## Troubleshooting

### Linting Failures

If Cursor generates code that fails linting:

1. **Run linting**: `./scripts/run-lint.sh`
2. **Check errors** in output
3. **Auto-fix**: `swiftlint --fix`
4. **Re-generate** if needed

### Test Failures

If tests fail:

1. **Run tests locally**: `xcodebuild test`
2. **Check test logs** for errors
3. **Fix test issues**
4. **Re-run tests**

### Coverage Issues

If coverage is below threshold:

1. **Check coverage report** in CI artifacts
2. **Identify uncovered code**
3. **Add tests** for uncovered code
4. **Re-run coverage check**

## Related Documentation

- [CI Setup Guide](README_CI_SETUP.md) - CI/CD setup
- [Style Guide](style_guide.md) - Code style rules
- [Testing Guide](testing.md) - Testing documentation
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow
