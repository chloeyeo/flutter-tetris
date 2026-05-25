# 🕹️ Flutter Tetris: My First Android Project

A fully functional, classic Tetris game built from scratch using **Flutter** and **Dart**. This project marks my first journey into mobile application development and game logic engineering.

## 🚀 Overview
This isn't just a Tetris clone; it's a deep dive into state management, game loops, and adaptive UI design in Flutter. I built this to understand how high-frequency UI updates interact with complex backend logic.

### ✨ Key Features
- **7-Bag Randomization System**: Implemented the official Tetris "Random Generator" algorithm to ensure a fair distribution of pieces and prevent frustrating repetitions.
- **SRS-Lite Rotation Logic**: Custom-engineered rotation math with "Wall Kick" support, allowing pieces to rotate smoothly even when flush against boundaries.
- **Adaptive UI**: Leveraged `LayoutBuilder` and `SafeArea` to ensure the game board scales perfectly across all Android device sizes and aspect ratios, including devices with notches/home indicators.
- **Line Clearing & Scoring**: Efficiently managing a 10x20 grid state to detect full rows, shift data down, and track progress.

## 🛠️ Tech Stack
- **Framework**: Flutter
- **Language**: Dart
- **State Management**: StatefulWidgets with optimized `Timer.periodic` game loops.

## 🧠 Technical Challenges & Learning Wins
One of the most valuable parts of this project was overcoming technical hurdles that aren't found in tutorials:

### 1. The "16k Page Size" Debugging
Early in development, I encountered immediate crashes on specific Android emulators. I identified that the experimental **16k Page Size** environment was incompatible with the standard Flutter engine rendering. I successfully resolved this by migrating to a stable **API 34 system image**, which stabilized the development environment.

### 2. Rendering Optimization (Impeller vs Skia)
I experimented with Flutter's new **Impeller** rendering engine. After identifying instability on certain emulator graphics drivers, I implemented a fallback to the **Skia** engine via the `AndroidManifest.xml`, ensuring 100% uptime during debugging.

### 3. Collision Detection Math
Building a collision system that handles negative modulo results (for pieces spawning above the visible grid) required a deep understanding of how Dart handles arithmetic versus traditional C-style languages.

## 📸 Screenshots


## 🏁 How to Run
1. Clone this repository.
2. Ensure you have the Flutter SDK installed.
3. Run `flutter pub get`.
4. Launch on a standard Android Emulator (API 34 recommended) or a physical device.

---
**First project, many more to come!** I’m excited to keep exploring the Flutter ecosystem and building performant, user-centric mobile applications.