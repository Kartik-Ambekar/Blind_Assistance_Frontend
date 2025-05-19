import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
    if (mounted) setState(() {});
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final directory = await getTemporaryDirectory();
    _videoPath = '${directory.path}/video_${DateTime.now()}.mp4';

    await _controller!.startVideoRecording();
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final XFile video = await _controller!.stopVideoRecording();
    setState(() {
      _isRecording = false;
    });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error processing video')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _audioPlayer.dispose();
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
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller!),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
          ),
        ],
      ),
    );
  }
} 