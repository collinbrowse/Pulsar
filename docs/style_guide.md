# Style Guide

This document outlines the code style and formatting rules for the Pulsar iOS project.

## Overview

Pulsar uses two complementary tools for code quality:
- **SwiftLint** - Static analysis and style enforcement
- **SwiftFormat** - Automatic code formatting

Both tools are configured to work together and ensure consistent code style across the project.

## SwiftLint

### Configuration

SwiftLint is configured via `.swiftlint.yml` in the project root.

### Key Rules

#### Disabled Rules
- `trailing_whitespace` - Handled by SwiftFormat
- `line_length` - Flexible line length (warnings at 500, errors at 1000)

#### Opt-In Rules
- `empty_count` - Prefer `isEmpty` over `count == 0`
- `explicit_init` - Prefer explicit `.init()` calls
- `fatal_error_message` - Require messages in `fatalError()` calls
- `force_unwrapping` - Warn about force unwrapping
- `implicit_return` - Prefer explicit returns
- `sorted_imports` - Sort imports alphabetically
- `vertical_whitespace_closing_braces` - Consistent spacing
- `vertical_whitespace_opening_braces` - Consistent spacing

#### Rule Thresholds
- **Identifier Name**: 2-60 characters
- **Type Name**: 3-50 characters
- **File Length**: Warning at 500 lines, error at 1000 lines
- **Function Body Length**: Warning at 50 lines, error at 100 lines
- **Type Body Length**: Warning at 300 lines, error at 500 lines
- **Cyclomatic Complexity**: Warning at 10, error at 20

### Running SwiftLint

#### Local Development
```bash
# Check for violations
./scripts/run-lint.sh

# Auto-fix issues
swiftlint --fix
```

#### Pre-Commit Hook
SwiftLint runs automatically before each commit:
- Checks only staged Swift files (fast, 2-5 seconds)
- Blocks commit if violations found
- Auto-fixes issues where possible
- Re-stages auto-fixed files

**Setup** (one-time per developer):
```bash
./scripts/setup-git-hooks.sh
```

**Usage**: Just commit normally - the hook runs automatically!

#### CI Integration
SwiftLint runs automatically on:
- Pull requests (via `ci-lint.yml`)
- Main CI workflow (via `ci.yml`)

## SwiftFormat

### Configuration

SwiftFormat is configured via `.swiftformat` in the project root.

### Key Settings

#### Indentation
- **Style**: Tabs
- **Width**: 4 spaces per tab
- **Case Statements**: Not indented (standard Swift style)

#### Line Length
- **Max Width**: 120 characters
- **Wrapping**: Arguments, parameters, and collections wrap before first item

#### Spacing
- **Operators**: Spaced (e.g., `a + b`)
- **Ranges**: Spaced (e.g., `0..<10`)
- **Trailing Whitespace**: Always trimmed

#### Braces
- **Style**: Same-line (e.g., `if condition {`)
- **Guard Else**: Auto-detect best position

#### Swift 6 Features
- **Concurrency**: Enabled
- **Actor Isolation**: Enabled

### Running SwiftFormat

#### Local Development
```bash
# Check formatting (no changes)
./scripts/run-format.sh

# Auto-fix formatting
./scripts/run-format-fix.sh
```

#### CI Integration
SwiftFormat runs automatically on pull requests via `ci-lint.yml`.

## Code Style Guidelines

### Naming Conventions

#### Types
- **Classes/Structs/Enums**: PascalCase
  ```swift
  class ActivityService { }
  struct Profile { }
  enum ActivityType { }
  ```

#### Variables and Functions
- **Variables**: camelCase
  ```swift
  let activityCount = 10
  var isLoading = false
  ```

- **Functions**: camelCase
  ```swift
  func fetchActivities() async throws { }
  func calculateDistance() -> Double { }
  ```

#### Constants
- **Constants**: camelCase (not SCREAMING_SNAKE_CASE)
  ```swift
  let maxActivitySize = 100
  let defaultTimeout: TimeInterval = 30
  ```

#### Enums
- **Enum Names**: PascalCase
- **Enum Cases**: camelCase
  ```swift
  enum ActivityType {
      case run
      case bike
      case swim
  }
  ```

### File Organization

#### File Length
- **Warning**: 500 lines
- **Error**: 1000 lines
- **Recommendation**: Keep files under 300 lines when possible

#### Function Length
- **Warning**: 50 lines
- **Error**: 100 lines
- **Recommendation**: Extract complex logic into separate functions

#### Type Body Length
- **Warning**: 300 lines
- **Error**: 500 lines
- **Recommendation**: Split large types into extensions or separate types

### Import Organization

Imports are automatically sorted by SwiftFormat:
1. System imports (Foundation, SwiftUI, etc.)
2. Third-party imports
3. Local imports
4. `@testable` imports (at bottom)

```swift
import Foundation
import SwiftUI
import SwiftData

import CoreGPX
import PostHog

import Pulsar

@testable import Pulsar
```

### Spacing and Formatting

#### Operators
```swift
// Good
let sum = a + b
let product = x * y

// Bad
let sum=a+b
let product=x*y
```

#### Braces
```swift
// Good (same-line)
if condition {
    // code
}

// Bad (Allman style)
if condition
{
    // code
}
```

#### Trailing Commas
```swift
// Good
let items = [
    "item1",
    "item2",
    "item3",
]

// Also acceptable (no trailing comma)
let items = [
    "item1",
    "item2",
    "item3"
]
```

### Swift 6 Concurrency

#### Async/Await
```swift
// Good
func fetchData() async throws -> Data {
    let url = URL(string: "https://api.example.com")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

#### MainActor
```swift
// Good
@MainActor
final class ActivityService {
    func updateUI() {
        // UI updates
    }
}
```

## Pre-Commit Workflow

### Automatic (Recommended)

The pre-commit hook runs automatically when you commit:

1. **Stage your changes**
   ```bash
   git add SomeFile.swift
   ```

2. **Commit** (hook runs automatically)
   ```bash
   git commit -m "feat: your commit message"
   ```

3. **If violations found**:
   - Hook blocks the commit
   - Fix issues (or run `swiftlint --fix`)
   - Stage fixes and commit again

### Manual (Optional)

You can still run checks manually before committing:

1. **Run SwiftLint**
   ```bash
   ./scripts/run-lint.sh
   ```

2. **Run SwiftFormat Check**
   ```bash
   ./scripts/run-format.sh
   ```

3. **Auto-fix Issues** (if needed)
   ```bash
   swiftlint --fix
   ./scripts/run-format-fix.sh
   ```

4. **Commit**
   ```bash
   git add .
   git commit -m "feat: your commit message"
   ```

## CI Integration

### Pull Requests

Both SwiftLint and SwiftFormat run automatically on pull requests:
- **Workflow**: `.github/workflows/ci-lint.yml`
- **Failure**: PR cannot be merged if linting fails
- **Reports**: Lint reports uploaded as artifacts

### Main CI

SwiftLint also runs in the main CI workflow:
- **Workflow**: `.github/workflows/ci.yml`
- **Job**: `lint`
- **Failure**: Build fails if linting errors found

## Common Issues and Fixes

### Issue: Force Unwrapping
```swift
// Bad
let userId = appState.currentUserId!

// Good
guard let userId = appState.currentUserId else {
    return
}
```

### Issue: Long Function
```swift
// Bad (100+ lines)
func processActivity() {
    // 100 lines of code
}

// Good (extracted)
func processActivity() {
    validateActivity()
    parseActivity()
    saveActivity()
}

private func validateActivity() { }
private func parseActivity() { }
private func saveActivity() { }
```

### Issue: Unsorted Imports
```swift
// Bad
import SwiftData
import Foundation
import SwiftUI

// Good (auto-sorted by SwiftFormat)
import Foundation
import SwiftData
import SwiftUI
```

## Related Documentation

- [SwiftLint Rules](https://realm.github.io/SwiftLint/rule-directory.html)
- [SwiftFormat Options](https://github.com/nicklockwood/SwiftFormat/blob/master/Rules.md)
- [CI Overview](ci_overview.md) - CI/CD setup
- [Testing Guide](testing.md) - Testing documentation


