# Test Fixtures

This directory contains test fixture files for ActivityService tests.

## Files

- `sample.gpx` - Valid GPX file with 5 track points
- `sample.tcx` - Valid TCX file with 5 track points
- `invalid.gpx` - Invalid GPX file (missing coordinates)
- `invalid.tcx` - Invalid TCX file (missing position data)

## FIT Files

FIT files are binary format and require special tools to create. For testing FIT parsing, you may need to:
1. Use actual FIT files from devices
2. Use FIT file generators
3. Create minimal valid FIT files using FIT SDK

For now, FIT file parsing tests will use mock data or skip if FIT files are not available.

