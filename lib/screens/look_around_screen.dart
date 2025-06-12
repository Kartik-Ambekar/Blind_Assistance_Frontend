import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LookAroundScreen extends StatefulWidget {
  const LookAroundScreen({super.key});

  @override
  State<LookAroundScreen> createState() => _LookAroundScreenState();
}

class _LookAroundScreenState extends State<LookAroundScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  String? _videoPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
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
      enableAudio: true,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {});
      _speak("Camera initialized. Double tap the screen to start recording.");
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final directory = await getTemporaryDirectory();
    _videoPath = '${directory.path}/video_${DateTime.now()}.mp4';

    await _controller!.startVideoRecording();
    setState(() {
      _isRecording = true;
    });
    await _speak("Recording started. Double tap to stop recording.");
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final XFile video = await _controller!.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });
    await _speak("Recording stopped. Processing video...");

    await _processVideo(video.path);
  }

  Future<void> _processVideo(String videoPath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.37:5569/api/process'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', videoPath),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final audioBytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final audioPath = '${tempDir.path}/response.mp3';
        await File(audioPath).writeAsBytes(audioBytes);

        await _audioPlayer.setFilePath(audioPath);
        await _audioPlayer.play();
      } else {
        await _speak("Error processing video. Please try again.");
      }
    } catch (e) {
      await _speak("Error occurred. Please try again.");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer.dispose();
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
        title: const Text('Look Around'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),

          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.black.withOpacity(0.7),
                child: const Text(
                  'Recording...',
                  style: TextStyle(
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
              child: Text(
                _isRecording
                    ? 'Double tap to stop recording'
                    : 'Double tap to start recording',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Gesture detector for double tap
          Positioned.fill(
            child: GestureDetector(
              onDoubleTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
