import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/ocr/ocr_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRProvider extends ChangeNotifier {
  final OCRService _ocrService = OCRService();

  OCRResult? _currentResult;
  bool _isProcessing = false;
  String? _error;
  TextElement? _selectedTextElement;

  OCRResult? get currentResult => _currentResult;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  TextElement? get selectedTextElement => _selectedTextElement;

  Future<void> extractTextFromImage(File imageFile) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      _currentResult = await _ocrService.recognizeText(imageFile);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _currentResult = null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void selectTextElement(TextElement element) {
    _selectedTextElement = element;
    notifyListeners();
  }

  void clearSelection() {
    _selectedTextElement = null;
    notifyListeners();
  }

  void clearResult() {
    _currentResult = null;
    _selectedTextElement = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
