import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRResult {
  final String fullText;
  final List<TextBlock> blocks;
  final File? sourceImage;
  final DateTime extractedAt;

  OCRResult({
    required this.fullText,
    required this.blocks,
    this.sourceImage,
    required this.extractedAt,
  });

  bool get isEmpty => fullText.trim().isEmpty;
}

class OCRService {
  static final OCRService _instance = OCRService._internal();
  late final TextRecognizer _textRecognizer;

  factory OCRService() => _instance;

  OCRService._internal() {
    _textRecognizer = TextRecognizer();
  }

  Future<OCRResult> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return OCRResult(
        fullText: recognizedText.text,
        blocks: recognizedText.blocks,
        sourceImage: imageFile,
        extractedAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
