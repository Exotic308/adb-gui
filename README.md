# Android Debug Bridge GUI

A modern, cross-platform desktop application for managing Android devices via ADB. View real-time logs, configure filtering rules, and manage connected devices with an intuitive graphical interface.

<table>
  <tr>
    <td width="50%">
      <h3 align="center">Splash Screen</h3>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/105db7f2-fc62-483b-bf24-3f20dd96cd5a" />
        <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/0f7e4c0b-c8aa-4b45-90eb-e75bfc6d8272" />
        <img alt="Splash screen with initialization checklist" src="https://github.com/user-attachments/assets/0f7e4c0b-c8aa-4b45-90eb-e75bfc6d8272" width="100%" />
      </picture>
    </td>
    <td width="50%">
      <h3 align="center">Real-time Logs</h3>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/b450852b-4063-4ade-9726-d91b5a2246fe" />
        <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/8af5aa23-3351-497c-a5c4-e30175a120d0" />
        <img alt="Logcat viewer with color-coded priorities" src="https://github.com/user-attachments/assets/8af5aa23-3351-497c-a5c4-e30175a120d0" width="100%" />
      </picture>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3 align="center">Filtering Rules</h3>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/8d241025-56f9-41e2-ac2f-4293fc549d0a" />
        <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/ccbb035b-f6fe-4d8d-a9da-3e2528ecb3b4" />
        <img alt="Rule-based log filtering configuration" src="https://github.com/user-attachments/assets/ccbb035b-f6fe-4d8d-a9da-3e2528ecb3b4" width="100%" />
      </picture>
    </td>
    <td width="50%">
      <h3 align="center">Settings</h3>
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/06178758-1f36-4356-8a90-4b0d66081a09" />
        <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/641b8d5b-68b5-46dd-91c8-9b7d38dca39a" />
        <img alt="Settings page with theme and buffer options" src="https://github.com/user-attachments/assets/641b8d5b-68b5-46dd-91c8-9b7d38dca39a" width="100%" />
      </picture>
    </td>
  </tr>
</table>

## 📋 Requirements

- **Flutter** and **Dart**
- **Android Debug Bridge (ADB)** installed and in your system PATH
- **Operating System**: macOS, Windows, or Linux

## 🚀 Installation

### 1. Clone the repository
```bash
git clone https://github.com/Exotic308/adb-gui.git
cd adb-gui
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run the application
```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

## 🔧 ADB Setup

This application requires ADB (Android Debug Bridge) to communicate with Android devices.

### Installing ADB

1. Download [Android Platform Tools](https://developer.android.com/studio/releases/platform-tools)
2. Extract the archive to a location on your computer
3. Add the `platform-tools` directory to your system PATH:

**macOS/Linux:**
```bash
echo 'export PATH=$PATH:/path/to/platform-tools' >> ~/.zshrc
source ~/.zshrc
```

**Windows:**
- Search for "Environment Variables" in the Start menu
- Edit the `Path` variable under System Variables
- Add the path to your `platform-tools` folder

### Verify Installation
```bash
adb version
```

The app will automatically detect ADB on first launch and guide you through setup if needed.

## 💡 Usage

1. **Enable USB Debugging** on your Android device:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"

2. **Connect your device** via USB cable

3. **Launch the application**:
   - The app will automatically check for ADB availability
   - If multiple devices are connected, select the one you want to monitor

4. **Configure filtering rules**:
   - Click the Rules button (filter icon) in the logs screen
   - Add rules to capture logs by tag pattern and minimum priority
   - Examples: `com.example.*`, `MyApp`, or `*` for all logs

5. **Start monitoring**:
   - Logs will stream in real-time with color-coded priorities
   - Use the search bar to filter visible logs
   - Auto-scroll is enabled by default (scroll up to pause)

## 📁 Project Structure

```
lib/
├── main.dart              # Application entry point
├── models/                # Data models (Device, LogEntry, LogRule, etc.)
├── screens/               # Main UI screens (Splash, Doctor, Logs, Settings, Rules)
├── services/              # Logic (ADB, Logcat, Device management)
├── widgets/               # Reusable UI components
└── utils/                 # Utilities and constants
```