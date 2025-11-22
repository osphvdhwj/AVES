import 'dart:async';
import 'dart:io';

import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as path;

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  TextRecognizer? _recognizer;
  final Map<int, RecognizedText> _cache = {};
  final Map<int, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxCacheSize = 50;

  TextRecognizer get recognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  /// Extract text from an image entry
  Future<RecognizedText?> extractText(AvesEntry entry) async {
    try {
      // Check cache first
      final cached = _getCached(entry.id);
      if (cached != null) {
        return cached;
      }

      // Prepare input image
      final inputImage = await _prepareInputImage(entry);
      if (inputImage == null) {
        debugPrint('[OCR] Failed to prepare input image for entry: ${entry.uri}');
        return null;
      }

      // Process image
      final result = await recognizer.processImage(inputImage);
      
      // Cache result
      if (result.text.isNotEmpty) {
        _cacheResult(entry.id, result);
      }

      return result;
    } catch (e, stack) {
      debugPrint('[OCR] Error extracting text: $e');
      await reportService.recordError(e, stack);
      return null;
    }
  }

  /// Prepare input image with optimization
  Future<InputImage?> _prepareInputImage(AvesEntry entry) async {
    try {
      final filePath = entry.path;
      if (filePath == null || filePath.isEmpty) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      // Check file size and optimize if needed
      final fileSize = await file.length();
      const maxSize = 4 * 1024 * 1024; // 4MB

      if (fileSize > maxSize) {
        // For large files, we should decode and resize
        // For now, we'll try processing as-is
        debugPrint('[OCR] Large file detected: ${fileSize ~/ 1024}KB');
      }

      return InputImage.fromFilePath(filePath);
    } catch (e) {
      debugPrint('[OCR] Error preparing input image: $e');
      return null;
    }
  }

  /// Get cached OCR result
  RecognizedText? _getCached(int entryId) {
    final timestamp = _cacheTimestamps[entryId];
    if (timestamp != null) {
      if (DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _cache[entryId];
      } else {
        // Expired
        _cache.remove(entryId);
        _cacheTimestamps.remove(entryId);
      }
    }
    return null;
  }

  /// Cache OCR result
  void _cacheResult(int entryId, RecognizedText result) {
    // Implement LRU cache
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      DateTime? oldest;
      int? oldestId;
      _cacheTimestamps.forEach((id, timestamp) {
        if (oldest == null || timestamp.isBefore(oldest!)) {
          oldest = timestamp;
          oldestId = id;
        }
      });
      if (oldestId != null) {
        _cache.remove(oldestId);
        _cacheTimestamps.remove(oldestId);
      }
    }

    _cache[entryId] = result;
    _cacheTimestamps[entryId] = DateTime.now();
  }

  /// Clear cache for specific entry
  void clearCache(int entryId) {
    _cache.remove(entryId);
    _cacheTimestamps.remove(entryId);
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Check if entry has cached result
  bool hasCached(int entryId) => _getCached(entryId) != null;

  /// Dispose resources
  void dispose() {
    _recognizer?.close();
    _recognizer = null;
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
