import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class DetectObjectScreen extends StatefulWidget {
  const DetectObjectScreen({super.key});

  @override
  State<DetectObjectScreen> createState() => _DetectObjectScreenState();
}

class _DetectObjectScreenState extends State<DetectObjectScreen> {
  CameraController? _controller;
  bool _isDetecting = true;
  final FlutterTts _flutterTts = FlutterTts();
  String _lastDetectedObject = '';
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _initializeCamera();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    _isSpeaking = true;
    await _flutterTts.speak(text);
    _isSpeaking = false;
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    // Set flash mode to off
    await _controller!.setFlashMode(FlashMode.off);

    if (mounted) {
      setState(() {});
      _startDetection();
    }
  }

  Future<void> _startDetection() async {
    setState(() {
      _isDetecting = true;
    });
    _detectObjects();
  }

  Future<void> _stopDetection() async {
    setState(() {
      _isDetecting = false;
    });
  }

  Future<void> _detectObjects() async {
    if (!_isDetecting || _controller == null) return;

    try {
      // Take a picture without flash
      final XFile image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.37:5569/api/detect'),
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'image.jpg'),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final detectedObject = await response.stream.bytesToString();
        if (detectedObject != _lastDetectedObject) {
          _lastDetectedObject = detectedObject;
          await _speak('Detected: $detectedObject');
        }
      }
    } catch (e) {
      print('Error detecting objects: $e');
    }

    if (_isDetecting) {
      Future.delayed(const Duration(milliseconds: 500), _detectObjects);
    }
  }

  @override
  void dispose() {
    _stopDetection();
    _controller?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detect Object'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),

          // Overlay for detected object
          if (_lastDetectedObject.isNotEmpty)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Detected: $_lastDetectedObject',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Instructions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withOpacity(0.7),
              child: const Text(
                'Point the camera at an object.\nThe app will automatically detect and announce it.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
