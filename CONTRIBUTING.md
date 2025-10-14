# Contributing to react-native-call-keeper

Thank you for your interest in contributing to react-native-call-keeper! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/react-native-call-keeper.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Install dependencies: `npm install`

## Development Setup

### Prerequisites

- Node.js >= 18.0.0
- npm or yarn
- For iOS development: Xcode 14+, CocoaPods
- For Android development: Android Studio, JDK 17

### Running the Example App

1. Navigate to the example directory:
```bash
cd example
npm install
```

2. For iOS:
```bash
cd ios && pod install && cd ..
npm run ios
```

3. For Android:
```bash
npm run android
```

## Making Changes

### Code Style

This project uses ESLint and Prettier for code formatting. Make sure your code passes linting:

```bash
npm run lint
npm run typecheck
```

### Testing

Before submitting a PR, ensure:
- Your code builds without errors
- TypeScript types are correct
- The example app works on both iOS and Android
- All existing functionality still works

### Commit Messages

Use clear and descriptive commit messages:
- feat: Add new feature
- fix: Bug fix
- docs: Documentation changes
- style: Code style changes (formatting, etc.)
- refactor: Code refactoring
- test: Adding or updating tests
- chore: Maintenance tasks

## Submitting Changes

1. Push your changes to your fork
2. Create a Pull Request to the main repository
3. Describe your changes in detail
4. Link any related issues

## Code Structure

```
react-native-call-keeper/
├── src/                    # TypeScript source code
│   ├── NativeCallKeeper.ts # TurboModule interface
│   └── index.tsx          # Main module export
├── ios/                   # iOS native code
│   ├── CallKeeper.h
│   └── CallKeeper.mm
├── android/               # Android native code
│   └── src/
│       ├── main/
│       ├── oldarch/       # Old architecture support
│       └── newarch/       # New architecture support
├── app.plugin.js         # Expo config plugin
└── example/              # Example application
```

## Architecture

### iOS (CallKit)
- Uses Apple's CallKit framework
- Implements CXProviderDelegate
- Handles VoIP push notifications
- Manages audio sessions

### Android (ConnectionService)
- Uses Android's ConnectionService API
- Implements self-managed connections
- Requires specific permissions
- API 23+ support

### New Architecture Support
- TurboModule specification in TypeScript
- Codegen for native interfaces
- Supports both old and new architecture

## Reporting Issues

When reporting issues, please include:
- React Native version
- iOS/Android version
- Device/Simulator information
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs

## Questions?

If you have questions, feel free to:
- Open a GitHub issue
- Start a discussion
- Check existing documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

