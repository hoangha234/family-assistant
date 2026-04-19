# iMate - Family Assistant

A smart family assistant Flutter app with AI integration, health tracking, meal planning, finance management, and IoT device control.

## Getting Started

### Prerequisites
- Flutter SDK (3.x or later)
- Firebase project
- Google Gemini API key

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/hoangha234/family-assistant.git
   cd family-assistant
   ```

2. **Set up API Keys**
   ```bash
   # Copy the example file and add your Gemini API key
   cp lib/core/config/api_keys.example.dart lib/core/config/api_keys.dart
   ```
   Then edit `lib/core/config/api_keys.dart` and replace `YOUR_GEMINI_API_KEY_HERE` with your actual key from [Google AI Studio](https://aistudio.google.com/app/apikey).

3. **Set up Firebase**
   ```bash
   # Option A: Use FlutterFire CLI (recommended)
   dart pub global activate flutterfire_cli
   flutterfire configure

   # Option B: Manual setup
   # Copy the example and fill in your Firebase config
   cp lib/firebase_options.example.dart lib/firebase_options.dart
   ```
   For Android, place your `google-services.json` in `android/app/`.

4. **Install dependencies**
   ```bash
   flutter pub get
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## ⚠️ Security Notice

The following files contain sensitive API keys and are **excluded from version control**:

- `lib/core/config/api_keys.dart` — Gemini API key
- `lib/firebase_options.dart` — Firebase configuration
- `android/app/google-services.json` — Android Firebase config
- `ios/Runner/GoogleService-Info.plist` — iOS Firebase config

**Never commit these files to the repository.** Use the `.example` templates to set up your own.

## Features

- 🤖 AI Assistant (Gemini-powered)
- 🏥 Health Dashboard & Tracking
- 🍽️ Meal Planning
- 💰 Finance Management
- 🛒 Shopping Schedule
- 🏠 IoT Device Control
- 💧 Hydration & Sleep Tracking

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Google AI for Developers](https://ai.google.dev/)
