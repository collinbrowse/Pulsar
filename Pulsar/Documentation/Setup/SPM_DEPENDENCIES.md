# SPM Dependencies Setup Guide

This document explains how to add Swift Package Manager (SPM) dependencies to the Pulsar Xcode project.

## Required Dependencies

### 1. The Composable Architecture (TCA)
**Purpose**: State management and app architecture

**Repository**: `https://github.com/pointfreeco/swift-composable-architecture`

**Installation**:
1. Open `Pulsar.xcodeproj` in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the repository URL: `https://github.com/pointfreeco/swift-composable-architecture`
4. Select **Up to Next Major Version** starting from `1.0.0`
5. Click **Add Package**
6. Select the **Pulsar** target
7. Add `ComposableArchitecture` to the target

**Import in code**:
```swift
import ComposableArchitecture
```

---

### 2. CoreGPX
**Purpose**: GPX file parsing

**Repository**: `https://github.com/vincentneo/CoreGPX`

**Installation**:
1. **File → Add Package Dependencies...**
2. Enter: `https://github.com/vincentneo/CoreGPX`
3. Select **Up to Next Major Version** starting from `0.9.0`
4. Add to **Pulsar** target

**Import in code**:
```swift
import CoreGPX
```

**Usage**:
```swift
let parser = GPXParser(withURL: fileURL)
if let gpxRoot = parser.parsedData() {
    for track in gpxRoot.tracks {
        // Process track points
    }
}
```

---

### 3. FitDataProtocol (FIT File Parser)
**Purpose**: FIT file parsing (Garmin, Wahoo, etc.)

**Repository**: `https://github.com/FitnessKit/FitDataProtocol`

**Installation**:
1. **File → Add Package Dependencies...**
2. Enter: `https://github.com/FitnessKit/FitDataProtocol`
3. Select **Up to Next Major Version** starting from `2.0.0`
4. Add to **Pulsar** target

**Import in code**:
```swift
import FitDataProtocol
```

**Usage**:
```swift
let fileData = try Data(contentsOf: fitFileURL)
let fitFile = try FitFile.decode(data: fileData)
for message in fitFile.messages {
    // Process FIT messages
}
```

---

### 4. XMLCoder
**Purpose**: TCX file parsing (XML to Swift structs)

**Repository**: `https://github.com/MaxDesiatov/XMLCoder`

**Installation**:
1. **File → Add Package Dependencies...**
2. Enter: `https://github.com/MaxDesiatov/XMLCoder`
3. Select **Up to Next Major Version** starting from `0.17.0`
4. Add to **Pulsar** target

**Import in code**:
```swift
import XMLCoder
```

**Usage**:
```swift
struct TrainingCenterDatabase: Codable {
    let activities: Activities
}

let decoder = XMLDecoder()
let tcx = try decoder.decode(TrainingCenterDatabase.self, from: xmlData)
```

---

## Installation via Xcode (Recommended)

### Step-by-Step:
1. Open `Pulsar.xcodeproj` in Xcode
2. Select the **Pulsar** project in the navigator
3. Select the **Pulsar** target
4. Go to the **General** tab
5. Scroll down to **Frameworks, Libraries, and Embedded Content**
6. Click the **+** button
7. Select **Add Other... → Add Package Dependency...**
8. Repeat for each package listed above

### Verify Installation:
1. Go to **File → Packages → Resolve Package Versions**
2. Check that all packages resolve without errors
3. Build the project: `Cmd+B`
4. Verify no compile errors related to missing imports

---

## Installation via Package.resolved (Alternative)

If you have a `Package.resolved` file from another project, you can:

1. Copy `Package.resolved` to the project root
2. Xcode will automatically detect and resolve packages
3. Accept the package versions when prompted

---

## Troubleshooting

### "Package not found"
**Solution**: Check the repository URL is correct and accessible

### "No such module 'ComposableArchitecture'"
**Solution**: 
1. Clean build folder: `Cmd+Shift+K`
2. Delete derived data: `Cmd+Shift+K` then `~/Library/Developer/Xcode/DerivedData`
3. Resolve packages: **File → Packages → Resolve Package Versions**
4. Rebuild

### "Package resolution failed"
**Solution**:
1. Check your internet connection
2. Try **File → Packages → Reset Package Caches**
3. Remove and re-add the package

### Version conflicts
**Solution**:
1. Go to **File → Packages → Update to Latest Package Versions**
2. Or manually specify compatible versions

---

## Testing Package Integration

After installing packages, create a simple test to verify:

```swift
import Testing
import ComposableArchitecture
import CoreGPX
import FitDataProtocol
import XMLCoder
@testable import Pulsar

@Suite("Package Integration Tests")
struct PackageIntegrationTests {
    
    @Test("TCA is available")
    func testTCAAvailable() {
        let store = Store(initialState: TestState()) {
            TestReducer()
        }
        #expect(store != nil)
    }
    
    @Test("CoreGPX is available")
    func testCoreGPXAvailable() {
        let gpxRoot = GPXRoot(creator: "Pulsar")
        #expect(gpxRoot.creator == "Pulsar")
    }
    
    @Test("FitDataProtocol is available")
    func testFitDataProtocolAvailable() {
        // Basic availability check
        #expect(FitFile.self != nil)
    }
    
    @Test("XMLCoder is available")
    func testXMLCoderAvailable() {
        let decoder = XMLDecoder()
        #expect(decoder != nil)
    }
}

// Minimal TCA test types
private struct TestState: Equatable {}
private struct TestReducer: Reducer {
    func reduce(into state: inout TestState, action: Never) -> Effect<Never> {
        return .none
    }
}
```

---

## Package Versions (Recommended as of Oct 2025)

| Package | Minimum Version | Recommended |
|---------|----------------|-------------|
| ComposableArchitecture | 1.0.0 | Latest 1.x |
| CoreGPX | 0.9.0 | Latest 0.x |
| FitDataProtocol | 2.0.0 | Latest 2.x |
| XMLCoder | 0.17.0 | Latest 0.x |

---

## CI/CD Configuration

For GitHub Actions, packages are automatically resolved during the build process.

If you encounter issues in CI:

```yaml
- name: Resolve SPM dependencies
  run: |
    xcodebuild -resolvePackageDependencies \
      -project Pulsar.xcodeproj \
      -scheme Pulsar
```

---

## Further Reading

- [Apple SPM Documentation](https://developer.apple.com/documentation/xcode/swift-packages)
- [TCA Documentation](https://pointfreeco.github.io/swift-composable-architecture/)
- [CoreGPX GitHub](https://github.com/vincentneo/CoreGPX)
- [FitDataProtocol GitHub](https://github.com/FitnessKit/FitDataProtocol)
- [XMLCoder GitHub](https://github.com/MaxDesiatov/XMLCoder)

