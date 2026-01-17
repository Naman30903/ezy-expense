import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Service for handling speech-to-text functionality.
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  String? _lastError;

  /// Initialize the speech recognition engine.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: _handleError,
      );
    } catch (e) {
      _lastError = e.toString();
      _isInitialized = false;
    }
    
    return _isInitialized;
  }

  void _handleError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;
  }

  /// Start listening for speech input.
  /// [onResult] is called with partial results as the user speaks.
  /// [onFinalResult] is called when speech recognition is complete.
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onFinalResult,
    Duration listenDuration = const Duration(seconds: 30),
    Duration pauseDuration = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      bool available = await initialize();
      if (!available) {
        throw Exception('Speech recognition not available: $_lastError');
      }
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        }
      },
      listenFor: listenDuration,
      pauseFor: pauseDuration,
      localeId: 'en_IN', // Indian English for better INR/rupee recognition
    );
  }

  /// Stop listening for speech.
  Future<void> stop() async {
    await _speech.stop();
  }

  /// Cancel speech recognition.
  Future<void> cancel() async {
    await _speech.cancel();
  }

  /// Check if currently listening.
  bool get isListening => _speech.isListening;

  /// Check if initialized.
  bool get isInitialized => _isInitialized;

  /// Get last error message.
  String? get lastError => _lastError;

  /// Get available locales for speech recognition.
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }
}
