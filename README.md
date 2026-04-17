# Doctor Consultation App

A beautiful Flutter mobile application for doctor consultations with a clean, modern UI.

## Features

- **Onboarding Screen**: Welcome and get started flow
- **Home Screen**: Browse doctor categories and view top doctors
- **Detail Screen**: View doctor details and available appointment schedules
- **Search Functionality**: Search for doctors by specialty
- **Responsive Design**: Works seamlessly on iOS and Android devices

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Dart**: Programming language
- **UI Packages**:
  - [google_fonts](https://pub.dev/packages/google_fonts) - Custom fonts
  - [flutter_svg](https://pub.dev/packages/flutter_svg) - SVG support

## Getting Started

### Prerequisites

- Flutter SDK (>=2.12.0)
- iOS 11.0+ for iOS development
- Xcode for iOS builds

### Installation

1. Clone the repository:
```bash
git clone <your-repository-url>
cd doctor-consultation-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For iOS
flutter run -d iPhone

# For Android
flutter run -d android
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── constant.dart          # App constants and colors
├── screens/               # Screen widgets
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   └── detail_screen.dart
└── components/            # Reusable UI components
    ├── category_card.dart
    ├── doctor_card.dart
    ├── schedule_card.dart
    └── search_bar.dart
```

## Design Credits

Original Design: [Asif Robhan](https://dribbble.com/shots/9780713-Doctor-Consultation-App)
