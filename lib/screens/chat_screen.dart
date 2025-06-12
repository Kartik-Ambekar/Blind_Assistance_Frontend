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
  final TextEditingController _textController = TextEditingController();
  bool _isListening = false;
  String _lastWords = '';
  String _lastResponse = '';
  bool _isProcessing = false;
  bool _isSpeechComplete = false;
  bool _isTextMode = false;

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
      _isTextMode = false;
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_US',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
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

    if (_lastWords.isNotEmpty) {
      _processQuery(_lastWords);
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      if (result.finalResult) {
        _isSpeechComplete = true;
      }
    });
  }

  Future<String> _createAudioFile(String text) async {
    final tempDir = await getTemporaryDirectory();
    final audioPath = '${tempDir.path}/query.mp3';
    await _flutterTts.synthesizeToFile(text, audioPath);
    await Future.delayed(const Duration(milliseconds: 500));
    return audioPath;
  }

  Future<void> _processQuery(String query) async {
    if (query.isEmpty || (!_isSpeechComplete && !_isTextMode)) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final audioPath = await _createAudioFile(query);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.37:5569/api/chat'),
      );

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

  void _toggleInputMode() {
    setState(() {
      _isTextMode = !_isTextMode;
      if (_isTextMode) {
        _stopListening();
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mode indicator
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isTextMode
                              ? 'Type your message below'
                              : 'Double tap to speak',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Text input field (when in text mode)
                      if (_isTextMode)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Last words or response
                      if (_lastWords.isNotEmpty && !_isTextMode)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You said: $_lastWords',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (_isProcessing)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),

                      if (_lastResponse.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _lastResponse,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom buttons
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mode toggle button
                FloatingActionButton(
                  onPressed: _toggleInputMode,
                  backgroundColor: Colors.blue[900],
                  child: Icon(
                    _isTextMode ? Icons.mic : Icons.keyboard,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                // Send/Record button
                FloatingActionButton(
                  onPressed: _isTextMode
                      ? () {
                          if (_textController.text.isNotEmpty) {
                            _processQuery(_textController.text);
                            _textController.clear();
                          }
                        }
                      : (_isListening ? _stopListening : _startListening),
                  backgroundColor: Colors.blue[900],
                  child: Icon(
                    _isTextMode
                        ? Icons.send
                        : (_isListening ? Icons.mic_off : Icons.mic),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Double tap gesture detector
          if (!_isTextMode)
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: _isListening ? _stopListening : _startListening,
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
