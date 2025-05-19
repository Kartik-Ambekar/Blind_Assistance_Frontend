import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _lastWords = '';
  String _lastResponse = '';
  bool _isProcessing = false;
  bool _isSpeechComplete = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    setState(() {
      _isSpeechComplete = false;
      _lastWords = '';
    });
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: (level) {
        // Optional: Handle sound level changes
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _isSpeechComplete = true;
    });
    
    // Only process the query if we have words and speech is complete
    if (_lastWords.isNotEmpty) {
      _processQuery(_lastWords);
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      // Check if this is the final result
      if (result.finalResult) {
        _isSpeechComplete = true;
      }
    });
  }

  Future<String> _createAudioFile(String text) async {
    final tempDir = await getTemporaryDirectory();
    final audioPath = '${tempDir.path}/query.mp3';
    
    // Use TTS to create audio file
    await _flutterTts.synthesizeToFile(text, audioPath);
    
    // Wait for the file to be created
    await Future.delayed(const Duration(milliseconds: 500));
    
    return audioPath;
  }

  Future<void> _processQuery(String query) async {
    if (query.isEmpty || !_isSpeechComplete) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create audio file from the speech
      final audioPath = await _createAudioFile(query);
      
      // Create a multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.37:5569/api/chat'),
      );

      // Add the audio file to the request with key 'file'
      request.files.add(
        await http.MultipartFile.fromPath('file', audioPath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final audioBytes = base64Decode(responseData['audio']);
        
        final tempDir = await getTemporaryDirectory();
        final responseAudioPath = '${tempDir.path}/response.mp3';
        await File(responseAudioPath).writeAsBytes(audioBytes);

        setState(() {
          _lastResponse = 'Response received';
        });

        await _audioPlayer.setFilePath(responseAudioPath);
        await _audioPlayer.play();
      } else {
        setState(() {
          _lastResponse = 'Error processing query';
        });
      }
    } catch (e) {
      setState(() {
        _lastResponse = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isListening ? 'Listening...' : 'Tap the microphone to speak',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  if (_lastWords.isNotEmpty)
                    Text(
                      'You said: $_lastWords',
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (_lastResponse.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _lastResponse,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
            ),
          ),
        ],
      ),
    );
  }
} 