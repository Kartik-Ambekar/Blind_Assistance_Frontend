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
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _options = [
    {
      'title': 'Look Around',
      'description': 'Use your camera to explore your surroundings',
      'icon': Icons.visibility,
      'route': LookAroundScreen(),
    },
    {
      'title': 'Detect Objects',
      'description': 'Identify objects in your environment',
      'icon': Icons.search,
      'route': DetectObjectScreen(),
    },
    {
      'title': 'Chat Assistant',
      'description': 'Get help from an AI assistant',
      'icon': Icons.chat,
      'route': ChatScreen(),
    },
  ];

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
      "Welcome to Blind Assistant! Swipe left or right to navigate between options. Double tap to select. Say 'help' for voice commands.",
    );
  }

  Future<void> _announceOptions() async {
    await _speak(
      "You can choose from three modes: 1. Look Around, 2. Detect Object, 3. Chat. Swipe to navigate or use voice commands.",
    );
  }

  Future<void> _startListening() async {
    await _speak("Listening for your command...");
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
    if (command.contains('help')) {
      _announceOptions();
    } else if (command.contains('look around')) {
      _navigateToScreen(0);
    } else if (command.contains('detect object')) {
      _navigateToScreen(1);
    } else if (command.contains('chat')) {
      _navigateToScreen(2);
    }
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _speak("Navigating to ${_options[index]['title']}");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _options[index]['route']),
    ).then((_) => _announceOptions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blind Assistant'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Main content
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe right
                setState(() {
                  _selectedIndex =
                      (_selectedIndex - 1).clamp(0, _options.length - 1);
                });
                _speak(_options[_selectedIndex]['title']);
              } else if (details.primaryVelocity! < 0) {
                // Swipe left
                setState(() {
                  _selectedIndex =
                      (_selectedIndex + 1).clamp(0, _options.length - 1);
                });
                _speak(_options[_selectedIndex]['title']);
              }
            },
            onTap: () {
              _navigateToScreen(_selectedIndex);
            },
            child: Container(
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final option = _options[index];
                        return Semantics(
                          label: '${option['title']}. ${option['description']}',
                          button: true,
                          selected: index == _selectedIndex,
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: index == _selectedIndex
                                ? Colors.blue[100]
                                : Colors.white,
                            elevation: index == _selectedIndex ? 8 : 2,
                            child: ListTile(
                              leading: Icon(
                                option['icon'],
                                size: 32,
                                color: Colors.blue[900],
                              ),
                              title: Text(
                                option['title'],
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              subtitle: Text(
                                option['description'],
                                style: const TextStyle(fontSize: 16),
                              ),
                              onTap: () => _navigateToScreen(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Large microphone button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                label: _isListening ? 'Stop listening' : 'Start listening',
                button: true,
                child: GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.red : Colors.blue[900],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
