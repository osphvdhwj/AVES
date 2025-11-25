import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OCRSettings {
  static const String _keyAutoDetect = 'ocr_auto_detect';
  static const String _keyOverlayOpacity = 'ocr_overlay_opacity';
  static const String _keyHoldDuration = 'ocr_hold_duration';
  static const String _keyCacheEnabled = 'ocr_cache_enabled';
  static const String _keyShowHint = 'ocr_show_hint';

  final SharedPreferences _prefs;

  OCRSettings(this._prefs);

  /// Auto-detect text when viewing images
  bool get autoDetect => _prefs.getBool(_keyAutoDetect) ?? false;
  set autoDetect(bool value) => _prefs.setBool(_keyAutoDetect, value);

  /// OCR overlay opacity (0.0 - 1.0)
  double get overlayOpacity => _prefs.getDouble(_keyOverlayOpacity) ?? 0.7;
  set overlayOpacity(double value) {
    assert(value >= 0.0 && value <= 1.0);
    _prefs.setDouble(_keyOverlayOpacity, value);
  }

  /// Hold duration in milliseconds before OCR activates
  int get holdDuration => _prefs.getInt(_keyHoldDuration) ?? 500;
  set holdDuration(int value) {
    assert(value >= 100 && value <= 2000);
    _prefs.setInt(_keyHoldDuration, value);
  }

  /// Enable OCR result caching
  bool get cacheEnabled => _prefs.getBool(_keyCacheEnabled) ?? true;
  set cacheEnabled(bool value) => _prefs.setBool(_keyCacheEnabled, value);

  /// Show hint on first use
  bool get showHint => _prefs.getBool(_keyShowHint) ?? true;
  set showHint(bool value) => _prefs.setBool(_keyShowHint, value);

  Duration get holdDurationAsDuration => Duration(milliseconds: holdDuration);
}
