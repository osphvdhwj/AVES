import 'dart:async';
import 'dart:io';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:aves/app_flavor.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  TextRecognizer? _recognizer;
  final Map<int, RecognizedText> _memoryCache = {};
  final Map<int, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxCacheSize = 50;
  static const int _maxImageSize = 4 * 1024 * 1024; // 4MB
  static const String _prefKeyPrefix = 'ocr_cache_';
  static const String _prefKeyTimestamp = '_timestamp';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistentCache();
      _isInitialized = true;
      debugPrint('[OCR] Service initialized with persistent cache');
    } catch (e) {
      debugPrint('[OCR] Failed to initialize: $e');
      _isInitialized = true;
    }
  }

  TextRecognizer get recognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  Future<RecognizedText?> extractText(
    AvesEntry entry, {
    Function(String)? onError,
    Function(double)? onProgress,
  }) async {
    await initialize();
    if (!AppFlavor.current.supportsOCR) {
      onError?.call('OCR not available in this build variant');
      return null;
    }
    try {
      final cached = await _getCached(entry.id);
      if (cached != null) {
        debugPrint('[OCR] Cache hit for entry ${entry.id}');
        return cached;
      }
      if (!entry.isImage) {
        final error = 'Entry is not an image';
        onError?.call(error);
        return null;
      }
      onProgress?.call(0.1);
      final inputImage = await _prepareInputImage(entry, onError: onError);
      if (inputImage == null) {
        return null;
      }
      onProgress?.call(0.5);
      debugPrint('[OCR] Processing image: ${entry.uri}');
      final result = await recognizer.processImage(inputImage);
      onProgress?.call(0.9);
      if (result.text.isNotEmpty) {
        await _cacheResult(entry.id, result);
        debugPrint('[OCR] Found ${result.text.length} characters');
      } else {
        debugPrint('[OCR] No text found in image');
      }
      onProgress?.call(1.0);
      return result;
    } catch (e, stack) {
      final errorMsg = 'Failed to extract text: $e';
      debugPrint('[OCR] $errorMsg');
      onError?.call(errorMsg);
      await reportService.recordError(e, stack);
      return null;
    }
  }

  Future<InputImage?> _prepareInputImage(
    AvesEntry entry, {
    Function(String)? onError,
  }) async {
    try {
      final filePath = entry.path;
      if (filePath == null || filePath.isEmpty) {
        onError?.call('File path is empty');
        return null;
      }
      final file = File(filePath);
      if (!await file.exists()) {
        onError?.call('File does not exist');
        return null;
      }
      final fileSize = await file.length();
      if (fileSize > _maxImageSize) {
        debugPrint('[OCR] Large file detected: ${fileSize ~/ 1024}KB');
      }
      if (fileSize == 0) {
        onError?.call('File is empty');
        return null;
      }
      return InputImage.fromFilePath(filePath);
    } catch (e) {
      final errorMsg = 'Failed to prepare image: $e';
      debugPrint('[OCR] $errorMsg');
      onError?.call(errorMsg);
      return null;
    }
  }

  Future<RecognizedText?> _getCached(int entryId) async {
    final timestamp = _cacheTimestamps[entryId];
    if (timestamp != null) {
      if (DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _memoryCache[entryId];
      } else {
        _memoryCache.remove(entryId);
        _cacheTimestamps.remove(entryId);
      }
    }
    if (_prefs != null) {
      try {
        final cacheKey = '$_prefKeyPrefix$entryId';
        final timestampKey = '$cacheKey$_prefKeyTimestamp';
        final timestampStr = _prefs!.getString(timestampKey);
        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          if (DateTime.now().difference(timestamp) < _cacheExpiry) {
            final cachedJson = _prefs!.getString(cacheKey);
            if (cachedJson != null) {
              final result = _deserializeRecognizedText(cachedJson);
              if (result != null) {
                _memoryCache[entryId] = result;
                _cacheTimestamps[entryId] = timestamp;
                return result;
              }
            }
          } else {
            await _prefs!.remove(cacheKey);
            await _prefs!.remove(timestampKey);
          }
        }
      } catch (e) {
        debugPrint('[OCR] Failed to read persistent cache: $e');
      }
    }
    return null;
  }

  Future<void> _cacheResult(int entryId, RecognizedText result) async {
    final now = DateTime.now();
    if (_memoryCache.length >= _maxCacheSize) {
      DateTime? oldest;
      int? oldestId;
      _cacheTimestamps.forEach((id, timestamp) {
        if (oldest == null || timestamp.isBefore(oldest!)) {
          oldest = timestamp;
          oldestId = id;
        }
      });
      if (oldestId != null) {
        _memoryCache.remove(oldestId);
        _cacheTimestamps.remove(oldestId);
      }
    }
    _memoryCache[entryId] = result;
    _cacheTimestamps[entryId] = now;
    if (_prefs != null) {
      try {
        final cacheKey = '$_prefKeyPrefix$entryId';
        final timestampKey = '$cacheKey$_prefKeyTimestamp';
        final serialized = _serializeRecognizedText(result);
        await _prefs!.setString(cacheKey, serialized);
        await _prefs!.setString(timestampKey, now.toIso8601String());
      } catch (e) {
        debugPrint('[OCR] Failed to write persistent cache: $e');
      }
    }
  }

  Future<void> _loadPersistentCache() async {
    if (_prefs == null) return;
    try {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefKeyPrefix) && !key.endsWith(_prefKeyTimestamp)) {
          final entryIdStr = key.substring(_prefKeyPrefix.length);
          final entryId = int.tryParse(entryIdStr);
          if (entryId != null) {
            final timestampKey = '$key$_prefKeyTimestamp';
            final timestampStr = _prefs!.getString(timestampKey);
            if (timestampStr != null) {
              final timestamp = DateTime.parse(timestampStr);
              if (DateTime.now().difference(timestamp) < _cacheExpiry) {
                final cachedJson = _prefs!.getString(key);
                if (cachedJson != null) {
                  final result = _deserializeRecognizedText(cachedJson);
                  if (result != null) {
                    _memoryCache[entryId] = result;
                    _cacheTimestamps[entryId] = timestamp;
                  }
                }
              } else {
                await _prefs!.remove(key);
                await _prefs!.remove(timestampKey);
              }
            }
          }
        }
      }
      debugPrint('[OCR] Loaded ${_memoryCache.length} cached results');
    } catch (e) {
      debugPrint('[OCR] Failed to load persistent cache: $e');
    }
  }

  String _serializeRecognizedText(RecognizedText result) {
    return jsonEncode({'text': result.text});
  }
  RecognizedText? _deserializeRecognizedText(String json) {
    try {
      final data = jsonDecode(json);
      return RecognizedText(text: data['text'], blocks: []);
    } catch (e) {
      debugPrint('[OCR] Failed to deserialize: $e');
      return null;
    }
  }

  Future<void> clearCache(int entryId) async {
    _memoryCache.remove(entryId);
    _cacheTimestamps.remove(entryId);
    if (_prefs != null) {
      final cacheKey = '$_prefKeyPrefix$entryId';
      final timestampKey = '$cacheKey$_prefKeyTimestamp';
      await _prefs!.remove(cacheKey);
      await _prefs!.remove(timestampKey);
    }
  }

  Future<void> clearAllCache() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefKeyPrefix)) {
          await _prefs!.remove(key);
        }
      }
    }
    debugPrint('[OCR] All cache cleared');
  }

  Future<bool> hasCached(int entryId) async {
    return await _getCached(entryId) != null;
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'memoryItems': _memoryCache.length,
      'maxCacheSize': _maxCacheSize,
      'persistentEnabled': _prefs != null,
    };
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _prefs = null;
    _isInitialized = false;
    debugPrint('[OCR] Service disposed');
  }
}
