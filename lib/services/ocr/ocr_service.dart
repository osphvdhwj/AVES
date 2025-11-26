import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'package:aves/app_flavor.dart';
import 'package:aves/model/entry/entry.dart';
import 'package:aves/model/ocr/ocr_text_block.dart';
import 'package:aves/ref/mime_types.dart';
import 'package:aves/services/common/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced OCR service with advanced image preprocessing for maximum accuracy
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  // Recognizers for supported scripts
  TextRecognizer? _latinRecognizer;
  TextRecognizer? _chineseRecognizer;
  TextRecognizer? _japaneseRecognizer;
  TextRecognizer? _koreanRecognizer;

  // Cache management
  final Map<String, OCRResult> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxCacheSize = 50;
  static const int _maxImageSize = 10 * 1024 * 1024; // 10MB
  static const String _prefKeyPrefix = 'ocr_cache_v3_';
  static const String _prefKeyTimestamp = '_timestamp';
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistentCache();
      _isInitialized = true;
      debugPrint('[OCR] Enhanced service initialized with preprocessing');
    } catch (e) {
      debugPrint('[OCR] Failed to initialize: $e');
      _isInitialized = true;
    }
  }

  TextRecognizer _getRecognizer(TextRecognitionScript script) {
    switch (script) {
      case TextRecognitionScript.latin:
        _latinRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
        return _latinRecognizer!;
      case TextRecognitionScript.chinese:
        _chineseRecognizer ??= TextRecognizer(script: TextRecognitionScript.chinese);
        return _chineseRecognizer!;
      case TextRecognitionScript.japanese:
        _japaneseRecognizer ??= TextRecognizer(script: TextRecognitionScript.japanese);
        return _japaneseRecognizer!;
      case TextRecognitionScript.korean:
        _koreanRecognizer ??= TextRecognizer(script: TextRecognitionScript.korean);
        return _koreanRecognizer!;
      default:
        _latinRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
        return _latinRecognizer!;
    }
  }

  /// Extract text with enhanced OCRResult model and preprocessing
  Future<OCRResult?> extractTextEnhanced(
    AvesEntry entry, {
    Function(String)? onError,
    Function(double)? onProgress,
    TextRecognitionScript script = TextRecognitionScript.latin,
    bool retryWithAlternateScript = true,
    bool enablePreprocessing = true,
  }) async {
    await initialize();
    
    if (!ExtraAppFlavor.current.supportsOCR) {
      onError?.call('OCR not available in this build variant');
      return null;
    }

    try {
      final startTime = DateTime.now();
      
      // Generate cache key from image hash
      final cacheKey = await _generateCacheKey(entry);
      if (cacheKey != null) {
        final cached = await _getCached(cacheKey);
        if (cached != null) {
          debugPrint('[OCR] Cache hit for entry ${entry.id}');
          return cached;
        }
      }

      if (!MimeTypes.isImage(entry.mimeType)) {
        onError?.call('Entry is not an image');
        return null;
      }

      onProgress?.call(0.1);

      // Prepare and preprocess input image
      final inputImage = await _prepareInputImage(
        entry,
        onError: onError,
        enablePreprocessing: enablePreprocessing,
        onProgress: (p) => onProgress?.call(0.1 + (p * 0.2)),
      );
      if (inputImage == null) return null;

      onProgress?.call(0.3);

      // Process with primary recognizer
      final recognizer = _getRecognizer(script);
      debugPrint('[OCR] Processing with ${script.name} script');
      
      var recognizedText = await recognizer.processImage(inputImage);
      onProgress?.call(0.7);

      // Retry with alternate script if confidence is low
      if (retryWithAlternateScript && _hasLowConfidence(recognizedText)) {
        debugPrint('[OCR] Low confidence (${(_calculateConfidence(recognizedText) * 100).toInt()}%), retrying with alternate script');
        final alternateScript = _getAlternateScript(script);
        final alternateRecognizer = _getRecognizer(alternateScript);
        final alternateResult = await alternateRecognizer.processImage(inputImage);
        
        // Use alternate result if better
        if (_calculateConfidence(alternateResult) > _calculateConfidence(recognizedText)) {
          recognizedText = alternateResult;
          debugPrint('[OCR] Using alternate script result (${(_calculateConfidence(recognizedText) * 100).toInt()}% confidence)');
        }
      }

      onProgress?.call(0.9);

      // Create OCRResult
      final processingTime = DateTime.now().difference(startTime);
      final result = OCRResult.fromRecognizedText(
        recognizedText,
        detectedLanguage: script.name,
        processingTime: processingTime,
      );

      // Cache result
      if (cacheKey != null && result.isNotEmpty) {
        await _cacheResult(cacheKey, result);
        debugPrint('[OCR] Cached result: ${result.totalWords} words, '
            '${result.totalCharacters} chars, '
            '${(result.averageConfidence * 100).toInt()}% confidence');
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

  /// Legacy method for backward compatibility
  Future<RecognizedText?> extractText(
    AvesEntry entry, {
    Function(String)? onError,
    Function(double)? onProgress,
  }) async {
    await initialize();
    if (!ExtraAppFlavor.current.supportsOCR) {
      onError?.call('OCR not available in this build variant');
      return null;
    }
    try {
      final cached = await _getCached(entry.id.toString());
      if (cached != null) {
        debugPrint('[OCR] Cache hit for entry ${entry.id}');
        return RecognizedText(text: cached.fullText, blocks: []);
      }
      if (!MimeTypes.isImage(entry.mimeType)) {
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
      final recognizer = _getRecognizer(TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      onProgress?.call(0.9);
      if (result.text.isNotEmpty) {
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
    bool enablePreprocessing = true,
    Function(double)? onProgress,
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
        debugPrint('[OCR] Large file: ${fileSize ~/ 1024}KB');
      }
      if (fileSize == 0) {
        onError?.call('File is empty');
        return null;
      }

      onProgress?.call(0.1);

      // Apply preprocessing if enabled
      if (enablePreprocessing) {
        try {
          debugPrint('[OCR] Applying image preprocessing...');
          final processedPath = await _preprocessImage(filePath, onProgress);
          if (processedPath != null) {
            debugPrint('[OCR] Using preprocessed image');
            return InputImage.fromFilePath(processedPath);
          }
        } catch (e) {
          debugPrint('[OCR] Preprocessing failed, using original: $e');
        }
      }

      onProgress?.call(1.0);
      return InputImage.fromFilePath(filePath);
    } catch (e) {
      final errorMsg = 'Failed to prepare image: $e';
      debugPrint('[OCR] $errorMsg');
      onError?.call(errorMsg);
      return null;
    }
  }

  /// Preprocess image for better OCR accuracy
  Future<String?> _preprocessImage(String imagePath, Function(double)? onProgress) async {
    try {
      onProgress?.call(0.2);

      // Read image
      final imageBytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return null;

      onProgress?.call(0.4);

      // 1. Convert to grayscale for better text recognition
      image = img.grayscale(image);

      onProgress?.call(0.5);

      // 2 & 3. Adjust contrast and brightness using adjustColor
      image = img.adjustColor(image, 
        contrast: 1.3,      // 30% increase in contrast
        brightness: 0.05,   // Slight brightness increase
      );

      onProgress?.call(0.7);

      // 4. Sharpen for better edge detection
      image = img.convolution(image, filter: [
        0, -1,  0,
       -1,  5, -1,
        0, -1,  0,
      ]);

      onProgress?.call(0.8);

      // 5. Apply threshold for binarization (better for text)
      final threshold = _calculateOtsuThreshold(image);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final luminance = img.getLuminance(pixel);
          final newColor = luminance > threshold ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(0, 0, 0);
          image.setPixel(x, y, newColor);
        }
      }

      onProgress?.call(0.9);

      // Save preprocessed image to temp file
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.png';
      final processedFile = File(tempPath);
      await processedFile.writeAsBytes(img.encodePng(image));

      onProgress?.call(1.0);

      debugPrint('[OCR] Preprocessed image saved: $tempPath');
      return tempPath;
    } catch (e) {
      debugPrint('[OCR] Image preprocessing error: $e');
      return null;
    }
  }

  /// Calculate Otsu's threshold for optimal binarization
  int _calculateOtsuThreshold(img.Image image) {
    // Build histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel).toInt();
        histogram[luminance]++;
      }
    }

    // Calculate total pixels
    final total = image.width * image.height;

    // Calculate Otsu threshold
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;
    double maxVariance = 0;
    int threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];
      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i;
      }
    }

    return threshold;
  }

  /// Generate cache key from image content hash
  Future<String?> _generateCacheKey(AvesEntry entry) async {
    try {
      final filePath = entry.path;
      if (filePath == null) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      // Read file and generate hash
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('[OCR] Failed to generate cache key: $e');
      return null;
    }
  }

  bool _hasLowConfidence(RecognizedText result) {
    final confidence = _calculateConfidence(result);
    return confidence < 0.65; // Slightly higher threshold
  }

  double _calculateConfidence(RecognizedText result) {
    if (result.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int count = 0;

    for (final block in result.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          if (element.confidence != null) {
            totalConfidence += element.confidence!;
            count++;
          }
        }
      }
    }

    return count > 0 ? totalConfidence / count : 0.0;
  }

  TextRecognitionScript _getAlternateScript(TextRecognitionScript primary) {
    switch (primary) {
      case TextRecognitionScript.latin:
        return TextRecognitionScript.chinese;
      case TextRecognitionScript.chinese:
        return TextRecognitionScript.japanese;
      case TextRecognitionScript.japanese:
        return TextRecognitionScript.korean;
      default:
        return TextRecognitionScript.latin;
    }
  }

  Future<OCRResult?> _getCached(String cacheKey) async {
    // Check memory cache
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp != null) {
      if (DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _memoryCache[cacheKey];
      } else {
        _memoryCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }
    }

    // Check persistent cache
    if (_prefs != null) {
      try {
        final prefKey = '$_prefKeyPrefix$cacheKey';
        final timestampKey = '$prefKey$_prefKeyTimestamp';
        final timestampStr = _prefs!.getString(timestampKey);
        
        if (timestampStr != null) {
          final timestamp = DateTime.parse(timestampStr);
          if (DateTime.now().difference(timestamp) < _cacheExpiry) {
            final cachedJson = _prefs!.getString(prefKey);
            if (cachedJson != null) {
              final result = _deserializeOCRResult(cachedJson);
              if (result != null) {
                _memoryCache[cacheKey] = result;
                _cacheTimestamps[cacheKey] = timestamp;
                return result;
              }
            }
          } else {
            await _prefs!.remove(prefKey);
            await _prefs!.remove(timestampKey);
          }
        }
      } catch (e) {
        debugPrint('[OCR] Failed to read persistent cache: $e');
      }
    }

    return null;
  }

  Future<void> _cacheResult(String cacheKey, OCRResult result) async {
    final now = DateTime.now();

    // Manage memory cache size
    if (_memoryCache.length >= _maxCacheSize) {
      DateTime? oldest;
      String? oldestKey;
      _cacheTimestamps.forEach((key, timestamp) {
        if (oldest == null || timestamp.isBefore(oldest!)) {
          oldest = timestamp;
          oldestKey = key;
        }
      });
      if (oldestKey != null) {
        _memoryCache.remove(oldestKey);
        _cacheTimestamps.remove(oldestKey);
      }
    }

    _memoryCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = now;

    // Persist to storage
    if (_prefs != null) {
      try {
        final prefKey = '$_prefKeyPrefix$cacheKey';
        final timestampKey = '$prefKey$_prefKeyTimestamp';
        final serialized = _serializeOCRResult(result);
        await _prefs!.setString(prefKey, serialized);
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
      int loaded = 0;
      
      for (final key in keys) {
        if (key.startsWith(_prefKeyPrefix) && !key.endsWith(_prefKeyTimestamp)) {
          final cacheKey = key.substring(_prefKeyPrefix.length);
          final timestampKey = '$key$_prefKeyTimestamp';
          final timestampStr = _prefs!.getString(timestampKey);
          
          if (timestampStr != null) {
            final timestamp = DateTime.parse(timestampStr);
            if (DateTime.now().difference(timestamp) < _cacheExpiry) {
              final cachedJson = _prefs!.getString(key);
              if (cachedJson != null) {
                final result = _deserializeOCRResult(cachedJson);
                if (result != null) {
                  _memoryCache[cacheKey] = result;
                  _cacheTimestamps[cacheKey] = timestamp;
                  loaded++;
                }
              }
            } else {
              await _prefs!.remove(key);
              await _prefs!.remove(timestampKey);
            }
          }
        }
      }
      
      debugPrint('[OCR] Loaded $loaded cached results');
    } catch (e) {
      debugPrint('[OCR] Failed to load persistent cache: $e');
    }
  }

  String _serializeOCRResult(OCRResult result) {
    return jsonEncode({
      'fullText': result.fullText,
      'averageConfidence': result.averageConfidence,
      'detectedLanguage': result.detectedLanguage,
      'totalWords': result.totalWords,
      'totalLines': result.totalLines,
      'processingTime': result.processingTime.inMilliseconds,
    });
  }

  OCRResult? _deserializeOCRResult(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      
      return OCRResult(
        blocks: [], // Blocks not serialized for cache efficiency
        fullText: data['fullText'] as String,
        averageConfidence: data['averageConfidence'] as double,
        detectedLanguage: data['detectedLanguage'] as String?,
        timestamp: DateTime.now(),
        processingTime: Duration(milliseconds: data['processingTime'] as int),
      );
    } catch (e) {
      debugPrint('[OCR] Failed to deserialize: $e');
      return null;
    }
  }

  Future<void> clearCache(String cacheKey) async {
    _memoryCache.remove(cacheKey);
    _cacheTimestamps.remove(cacheKey);
    
    if (_prefs != null) {
      final prefKey = '$_prefKeyPrefix$cacheKey';
      final timestampKey = '$prefKey$_prefKeyTimestamp';
      await _prefs!.remove(prefKey);
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
    
    // Clean up temp preprocessed images
    try {
      final tempDir = Directory.systemTemp;
      final files = tempDir.listSync();
      for (final file in files) {
        if (file.path.contains('ocr_preprocessed_')) {
          try {
            file.deleteSync();
          } catch (e) {
            // Ignore errors
          }
        }
      }
    } catch (e) {
      debugPrint('[OCR] Failed to clean temp files: $e');
    }
    
    debugPrint('[OCR] All cache cleared');
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return {
      'memoryItems': _memoryCache.length,
      'maxCacheSize': _maxCacheSize,
      'persistentEnabled': _prefs != null,
      'cacheVersion': 'v3',
      'preprocessingEnabled': true,
    };
  }

  void dispose() {
    _latinRecognizer?.close();
    _chineseRecognizer?.close();
    _japaneseRecognizer?.close();
    _koreanRecognizer?.close();
    
    _latinRecognizer = null;
    _chineseRecognizer = null;
    _japaneseRecognizer = null;
    _koreanRecognizer = null;
    
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _prefs = null;
    _isInitialized = false;
    
    debugPrint('[OCR] Service disposed');
  }
}
