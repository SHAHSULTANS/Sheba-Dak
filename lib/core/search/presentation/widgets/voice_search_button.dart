import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchButton extends StatefulWidget {
  final Function(String) onVoiceResult;
  final Function(bool) onListeningStateChange;

  const VoiceSearchButton({
    super.key,
    required this.onVoiceResult,
    required this.onListeningStateChange,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _disposed = false; // track if disposed

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (_disposed) return; // prevent setState after dispose
        setState(() {
          _isListening = status == 'listening';
        });
        widget.onListeningStateChange(_isListening);
      },
      onError: (error) {
        if (_disposed) return; // prevent setState after dispose
        setState(() {
          _isListening = false;
        });
        widget.onListeningStateChange(false);
        _showError('ভয়েস ইনপুট ত্রুটি: ${error.errorMsg}');
      },
    );
  }

  void _startListening() {
    if (!_speechAvailable) {
      _showError('ভয়েস সার্ভিস পাওয়া যায়নি');
      return;
    }

    if (_disposed) return;
    setState(() => _isListening = true);
    widget.onListeningStateChange(true);

    _speech.listen(
      onResult: (result) {
        if (_disposed) return;
        if (result.finalResult) {
          widget.onVoiceResult(result.recognizedWords);
          _stopListening();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'bn_BD',
    );
  }

  void _stopListening() {
    if (_disposed) return;
    _speech.stop();
    setState(() => _isListening = false);
    widget.onListeningStateChange(false);
  }

  void _showError(String message) {
    if (_disposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true; // mark disposed
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic_off : Icons.mic,
        color: _isListening ? Colors.red : Colors.grey[600],
      ),
      onPressed: _isListening ? _stopListening : _startListening,
      tooltip: 'ভয়েস সার্চ',
    );
  }
}
