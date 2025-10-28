# SPM Dependencies for Milestone 3 - Activity Import

## Required Packages

Add the following Swift Package Manager dependencies via Xcode:

### 1. CoreGPX
**URL:** `https://github.com/vincentneo/CoreGPX.git`  
**Version:** Latest (recommend: 0.9.2+)  
**Purpose:** Parse GPX (GPS Exchange Format) files  
**License:** MIT

```swift
// Usage Example
import CoreGPX
let gpx = try GPXParser(withURL: fileURL)
```

### 2. XMLCoder
**URL:** `https://github.com/CoreOffice/XMLCoder.git`  
**Version:** Latest (recommend: 0.17.0+)  
**Purpose:** Parse TCX (Training Center XML) files  
**License:** MIT

```swift
// Usage Example
import XMLCoder
let decoder = XMLDecoder()
let tcxData = try decoder.decode(TCXData.self, from: data)
```

### 3. FitDataProtocol  
**URL:** `https://github.com/FitnessKit/FitDataProtocol.git`  
**Version:** Latest (recommend: 2.1.0+)  
**Purpose:** Parse FIT (Flexible and Interoperable Data Transfer) files  
**License:** MIT

```swift
// Usage Example
import FitDataProtocol
let fitFile = try FitFile(data: data)
```

## Installation Steps

1. Open `Pulsar.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "Pulsar" target
4. Go to "Package Dependencies" tab
5. Click "+" to add each package
6. Enter the GitHub URL
7. Select "Up to Next Major Version"
8. Click "Add Package"

## Alternative: Command Line (if available)

```bash
# Add via xcodebuild (requires Xcode 15+)
cd Pulsar.xcodeproj
xcodebuild -resolvePackageDependencies

# Or manually edit Package.resolved
```

## Verification

After adding packages, verify they're available:

```swift
import CoreGPX
import XMLCoder
import FitDataProtocol

// All imports should succeed without errors
```

## Notes

- These packages are pure Swift and have no additional dependencies
- All are actively maintained with iOS 26 support
- Total size: ~2MB combined
- No privacy-sensitive code or tracking

