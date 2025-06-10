import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/api_config.dart';

class CurrencyDetectScreen extends StatefulWidget {
  const CurrencyDetectScreen({super.key});

  @override
  State<CurrencyDetectScreen> createState() => _CurrencyDetectScreenState();
}

class _CurrencyDetectScreenState extends State<CurrencyDetectScreen> {
  CameraController? _controller;
  bool _isDetecting = true;
  final FlutterTts _flutterTts = FlutterTts();
  String _lastDetectedCurrency = '';
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
    _detectCurrency();
  }

  Future<void> _stopDetection() async {
    setState(() {
      _isDetecting = false;
    });
  }

  Future<void> _detectCurrency() async {
    if (!_isDetecting || _controller == null) return;

    try {
      // Take a picture without flash
      final XFile image = await _controller!.takePicture();
      final bytes = await File(image.path).readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.currencyDetect),
      );

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: 'image.jpg'),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final detectedCurrency = await response.stream.bytesToString();
        if (detectedCurrency.isNotEmpty &&
            detectedCurrency != _lastDetectedCurrency) {
          setState(() {
            _lastDetectedCurrency = detectedCurrency;
          });
          await _speak('Detected currency: $detectedCurrency');
        }
      }
    } catch (e) {
      print('Error detecting currency: $e');
    }

    if (_isDetecting) {
      Future.delayed(const Duration(milliseconds: 500), _detectCurrency);
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
        title: const Text('Currency Detection'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),

          // Overlay for detected currency
          if (_lastDetectedCurrency.isNotEmpty)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Semantics(
                label: 'Detected currency: $_lastDetectedCurrency',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Detected Currency: $_lastDetectedCurrency',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // Instructions overlay
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Semantics(
              label:
                  'Instructions: Point the camera at a currency note. The app will automatically detect and announce the currency.',
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.black.withOpacity(0.7),
                child: const Text(
                  'Point the camera at a currency note.\nThe app will automatically detect and announce the currency.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
