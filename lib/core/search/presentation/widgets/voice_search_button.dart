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
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    // Initializing the service, checking availability
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (_disposed) return;
        // 'listening' status is received when listening starts
        final newListeningState = status == stt.SpeechToText.listeningStatus; 
        
        // Only call setState if the status actually changed
        if (_isListening != newListeningState) { 
          setState(() {
            _isListening = newListeningState;
          });
          widget.onListeningStateChange(_isListening);
        }
      },
      onError: (error) {
        if (_disposed) return;
        // The error handler should always reset the listening state
        if (_isListening) {
          setState(() {
            _isListening = false;
          });
          widget.onListeningStateChange(false);
        }
        // TRANSLATED: 'Voice Input Error: ${error.errorMsg}'
        _showError('Voice Input Error: ${error.errorMsg}');
      },
    );
  }

  void _startListening() {
    if (!_speechAvailable) {
      // TRANSLATED: 'Voice service not available'
      _showError('Voice service not available');
      return;
    }

    if (_isListening) {
      // Already listening, so stop and restart or just return
      _stopListening();
      return; 
    }

    if (_disposed) return;
    
    // Call the plugin's listen method
    _speech.listen(
      onResult: (result) {
        if (_disposed) return;
        if (result.finalResult) {
          // Send final recognized text to parent and stop
          widget.onVoiceResult(result.recognizedWords);
          _stopListening();
        }
      },
      // You may need to tune these durations based on user behavior
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      // UPDATED LOCALE: Target locale for English (United States)
      localeId: 'en_US', 
    );
    
    // Note: The UI state update (setState) will be handled by the onStatus callback
  }

  void _stopListening() {
    if (_disposed) return;
    _speech.stop();
    // State update handled by the onStatus callback, but we can force it here
    if (_isListening && !_disposed) {
      setState(() => _isListening = false);
      widget.onListeningStateChange(false);
    }
  }

  void _showError(String message) {
    if (_disposed) return;
    // Ensure we have a context for the ScaffoldMessenger
    if (mounted) { 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        // Use a disabled color if speech is not available
        _speechAvailable 
            ? (_isListening ? Icons.mic_off : Icons.mic)
            : Icons.mic_none, 
        color: _isListening ? Colors.red : Colors.grey[600],
      ),
      onPressed: _speechAvailable 
          ? (_isListening ? _stopListening : _startListening)
          : null, // Disable button if speech service isn't available
      // TRANSLATED: 'Voice Search'
      tooltip: 'Voice Search',
    );
  }
}