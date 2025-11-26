# Deployment Guide

This document outlines the deployment process for the Pulsar iOS application.

## Overview

Pulsar is deployed to the App Store via TestFlight for beta testing and then to the App Store for production releases.

## Deployment Environments

### Development
- **Target**: Local development and testing
- **Configuration**: Debug builds
- **Distribution**: Local simulator/device

### TestFlight (Beta)
- **Target**: Internal and external beta testers
- **Configuration**: Release builds
- **Distribution**: TestFlight
- **Status**: Not yet automated (see Future Work)

### App Store (Production)
- **Target**: End users
- **Configuration**: Release builds
- **Distribution**: App Store
- **Status**: Not yet automated (see Future Work)

## Current Deployment Process

### Manual Deployment

1. **Prepare Release**
   - Update version number in Xcode
   - Update CHANGELOG.md
   - Create release branch

2. **Build Archive**
   - Open Xcode
   - Product → Archive
   - Wait for archive to complete

3. **Distribute**
   - Select archive in Organizer
   - Click "Distribute App"
   - Choose distribution method (TestFlight or App Store)
   - Follow prompts

4. **Submit for Review** (App Store only)
   - Complete App Store Connect metadata
   - Submit for review

## Future Automation

### TestFlight Automation

When ready, the following will be automated:

1. **GitHub Actions Workflow**
   - Triggered by version tags (e.g., `v1.0.0`)
   - Builds archive
   - Exports IPA
   - Uploads to TestFlight via App Store Connect API

2. **Required Setup**
   - App Store Connect API key in GitHub Secrets
   - ExportOptions.plist configuration
   - Signing certificates

### App Store Automation

Similar to TestFlight, but with additional steps:
- App Store metadata updates
- Screenshot generation
- Review submission

## Version Management

### Version Numbering

Follow semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Version Location

Version is set in Xcode project settings:
- **Marketing Version**: User-facing version (e.g., 1.0.0)
- **Current Project Version**: Build number (e.g., 1)

## Release Checklist

Before deploying:

- [ ] All tests passing
- [ ] Code coverage meets threshold (80%)
- [ ] No linting errors
- [ ] CHANGELOG.md updated
- [ ] Version number updated
- [ ] Release notes prepared
- [ ] Screenshots updated (if UI changes)
- [ ] App Store metadata updated
- [ ] TestFlight build tested

## Related Documentation

- [Release Process](release_process.md) - Detailed release workflow
- [CI Overview](ci_overview.md) - CI/CD setup
- [Team Workflow](TEAM_WORKFLOW.md) - Development workflow




