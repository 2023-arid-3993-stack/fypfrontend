import 'package:flutter/services.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;

  static const MethodChannel _channel = MethodChannel('vtrc/voice');
  bool isVoiceEnabled = true;
  String _lastSpoken = "";
  DateTime _lastSpokenTime = DateTime.fromMillisecondsSinceEpoch(0);

  VoiceService._internal();

  Future<void> speak(String text, {int minIntervalSeconds = 2}) async {
    if (!isVoiceEnabled || text.trim().isEmpty) return;

    final now = DateTime.now();
    final difference = now.difference(_lastSpokenTime).inSeconds;

    final isIdleText = text.toLowerCase().contains("path clear") || text.toLowerCase().contains("center clear");
    if (isIdleText) {
      // Don't repeat "path clear" incessantly; wait at least 15 seconds if same
      if (text == _lastSpoken && difference < 15) {
        return;
      }
      if (difference < 3) {
        return;
      }
    } else {
      // Active obstacle warning or direction change
      if (text == _lastSpoken && difference < minIntervalSeconds) {
        return;
      }
    }

    _lastSpoken = text;
    _lastSpokenTime = now;

    try {
      await _channel.invokeMethod('speak', {'text': text});
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }
}
