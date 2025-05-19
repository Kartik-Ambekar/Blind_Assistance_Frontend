import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'look_around_screen.dart';
import 'detect_object_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _lastWords = '';
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initializeTts();
    _speakWelcome();
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

  Future<void> _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _speakWelcome() async {
    await _speak(
      "Welcome! You can choose from three modes: 1. Look Around, 2. Detect Object, 3. Chat.",
    );
  }

  Future<void> _announceOptions() async {
    await _speak(
      "You can choose from three modes: 1. Look Around, 2. Detect Object, 3. Chat.",
    );
  }

  Future<void> _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_US',
    );
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords.toLowerCase();
    });
    _processCommand(_lastWords);
  }

  void _processCommand(String command) {
    if (command.contains('look around')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LookAroundScreen()),
      ).then((_) => _announceOptions());
    } else if (command.contains('detect object')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DetectObjectScreen()),
      ).then((_) => _announceOptions());
    } else if (command.contains('chat')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChatScreen()),
      ).then((_) => _announceOptions());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blind Assistant'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isListening ? 'Listening...' : 'Tap the microphone to speak',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'Last words: $_lastWords',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }
} 