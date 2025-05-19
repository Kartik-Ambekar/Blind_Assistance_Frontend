# Blind Assistant App

A Flutter application designed to assist visually impaired users through voice interaction and computer vision capabilities.

## Features

1. **Look Around Mode**
   - Record video of surroundings
   - Get audio description of the scene
   - Uses YOLO and LLaMA for object detection and scene description

2. **Detect Object Mode**
   - Real-time object detection
   - Voice feedback for detected objects
   - Continuous monitoring with periodic updates

3. **Chat Mode**
   - Voice-based interaction
   - Natural language processing
   - Audio response playback

## Setup

1. Install Flutter:
   ```bash
   # Follow instructions at https://flutter.dev/docs/get-started/install
   ```

2. Clone the repository:
   ```bash
   git clone <repository-url>
   cd blind-assistant
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Configure backend URL:
   - Open the following files and update the backend URL:
     - `lib/screens/look_around_screen.dart`
     - `lib/screens/detect_object_screen.dart`
     - `lib/screens/chat_screen.dart`
   - Replace `http://your-backend-url` with your actual backend server URL

5. Run the app:
   ```bash
   flutter run
   ```

## Required Permissions

The app requires the following permissions:
- Camera access
- Microphone access
- Storage access (for saving temporary files)

## Backend Requirements

The app expects a backend server with the following endpoints:

1. `/api/process`
   - Accepts video file
   - Returns MP3 audio description

2. `/api/detect`
   - Accepts image file
   - Returns detected object label

3. `/api/chat`
   - Accepts audio file
   - Returns MP3 response

## Dependencies

- speech_to_text: ^6.6.0
- camera: ^0.10.5+9
- path_provider: ^2.1.2
- http: ^1.2.0
- flutter_tts: ^3.8.5
- permission_handler: ^11.3.0
- just_audio: ^0.9.36

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 