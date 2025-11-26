import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Represents a detected text block from OCR with enhanced metadata
class OCRTextBlock {
  final String text;
  final Rect boundingBox;
  final double confidence;
  final String? language;
  final List<OCRTextLine> lines;
  final TextBlockType type;

  const OCRTextBlock({
    required this.text,
    required this.boundingBox,
    this.confidence = 0.0,
    this.language,
    this.lines = const [],
    this.type = TextBlockType.paragraph,
  });

  /// Create from ML Kit TextBlock
  factory OCRTextBlock.fromMLKit(TextBlock block, {String? detectedLanguage}) {
    final lines = block.lines.map((line) => OCRTextLine.fromMLKit(line)).toList();
    
    return OCRTextBlock(
      text: block.text,
      boundingBox: block.boundingBox,
      confidence: _calculateAverageConfidence(lines),
      language: detectedLanguage,
      lines: lines,
      type: _inferBlockType(block.text),
    );
  }

  /// Scale bounding box for different display sizes
  OCRTextBlock scaleBoundingBox(double scaleX, double scaleY, {Offset offset = Offset.zero}) {
    final scaledRect = Rect.fromLTRB(
      boundingBox.left * scaleX + offset.dx,
      boundingBox.top * scaleY + offset.dy,
      boundingBox.right * scaleX + offset.dx,
      boundingBox.bottom * scaleY + offset.dy,
    );

    return OCRTextBlock(
      text: text,
      boundingBox: scaledRect,
      confidence: confidence,
      language: language,
      lines: lines.map((line) => line.scaleBoundingBox(scaleX, scaleY, offset: offset)).toList(),
      type: type,
    );
  }

  /// Check if a point is within this block's bounding box
  bool containsPoint(Offset point) {
    return boundingBox.contains(point);
  }

  /// Merge with another text block (for joined words or lines)
  OCRTextBlock mergeWith(OCRTextBlock other) {
    final mergedRect = boundingBox.expandToInclude(other.boundingBox);
    final mergedLines = [...lines, ...other.lines];
    final avgConfidence = (confidence + other.confidence) / 2;

    return OCRTextBlock(
      text: '$text ${other.text}',
      boundingBox: mergedRect,
      confidence: avgConfidence,
      language: language ?? other.language,
      lines: mergedLines,
      type: type,
    );
  }

  /// Extract specific data types from text
  List<String> extractEmails() {
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    return emailRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  List<String> extractPhoneNumbers() {
    final phoneRegex = RegExp(
      r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
    );
    return phoneRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  List<String> extractUrls() {
    final urlRegex = RegExp(
      r'https?://[^\s]+|www\.[^\s]+',
    );
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  List<String> extractCurrency() {
    final currencyRegex = RegExp(
      r'[\$£€¥₹]\s?\d+(?:[.,]\d{2})?|\d+(?:[.,]\d{2})?\s?(?:USD|EUR|GBP|INR|JPY)',
    );
    return currencyRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  bool get hasHighConfidence => confidence >= 0.8;
  bool get hasMediumConfidence => confidence >= 0.6 && confidence < 0.8;
  bool get hasLowConfidence => confidence < 0.6;

  /// Check if block is likely a specific data type
  bool get isLikelyEmail => extractEmails().isNotEmpty;
  bool get isLikelyPhone => extractPhoneNumbers().isNotEmpty;
  bool get isLikelyUrl => extractUrls().isNotEmpty;
  bool get isLikelyPrice => extractCurrency().isNotEmpty;

  static double _calculateAverageConfidence(List<OCRTextLine> lines) {
    if (lines.isEmpty) return 0.0;
    final sum = lines.fold<double>(0.0, (sum, line) => sum + line.confidence);
    return sum / lines.length;
  }

  static TextBlockType _inferBlockType(String text) {
    if (text.length <= 50 && !text.contains('\n')) {
      return TextBlockType.heading;
    }
    if (text.split('\n').length > 3) {
      return TextBlockType.paragraph;
    }
    return TextBlockType.line;
  }

  @override
  String toString() => 'OCRTextBlock(text: "${text.substring(0, text.length > 30 ? 30 : text.length)}...", '
      'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
      'language: $language)';
}

/// Represents a line within a text block
class OCRTextLine {
  final String text;
  final Rect boundingBox;
  final double confidence;
  final List<OCRTextElement> elements;

  const OCRTextLine({
    required this.text,
    required this.boundingBox,
    this.confidence = 0.0,
    this.elements = const [],
  });

  factory OCRTextLine.fromMLKit(TextLine line) {
    final elements = line.elements.map((element) => OCRTextElement.fromMLKit(element)).toList();
    
    return OCRTextLine(
      text: line.text,
      boundingBox: line.boundingBox,
      confidence: _calculateAverageConfidence(elements),
      elements: elements,
    );
  }

  OCRTextLine scaleBoundingBox(double scaleX, double scaleY, {Offset offset = Offset.zero}) {
    final scaledRect = Rect.fromLTRB(
      boundingBox.left * scaleX + offset.dx,
      boundingBox.top * scaleY + offset.dy,
      boundingBox.right * scaleX + offset.dx,
      boundingBox.bottom * scaleY + offset.dy,
    );

    return OCRTextLine(
      text: text,
      boundingBox: scaledRect,
      confidence: confidence,
      elements: elements.map((e) => e.scaleBoundingBox(scaleX, scaleY, offset: offset)).toList(),
    );
  }

  static double _calculateAverageConfidence(List<OCRTextElement> elements) {
    if (elements.isEmpty) return 0.0;
    final sum = elements.fold<double>(0.0, (sum, elem) => sum + elem.confidence);
    return sum / elements.length;
  }
}

/// Represents an individual text element (word)
class OCRTextElement {
  final String text;
  final Rect boundingBox;
  final double confidence;

  const OCRTextElement({
    required this.text,
    required this.boundingBox,
    this.confidence = 0.0,
  });

  factory OCRTextElement.fromMLKit(TextElement element) {
    return OCRTextElement(
      text: element.text,
      boundingBox: element.boundingBox,
      confidence: element.confidence ?? 0.0,
    );
  }

  OCRTextElement scaleBoundingBox(double scaleX, double scaleY, {Offset offset = Offset.zero}) {
    final scaledRect = Rect.fromLTRB(
      boundingBox.left * scaleX + offset.dx,
      boundingBox.top * scaleY + offset.dy,
      boundingBox.right * scaleX + offset.dx,
      boundingBox.bottom * scaleY + offset.dy,
    );

    return OCRTextElement(
      text: text,
      boundingBox: scaledRect,
      confidence: confidence,
    );
  }
}

/// Type of text block for better categorization
enum TextBlockType {
  heading,
  paragraph,
  line,
  listItem,
  table,
}

/// Result container for OCR processing
class OCRResult {
  final List<OCRTextBlock> blocks;
  final String fullText;
  final double averageConfidence;
  final String? detectedLanguage;
  final DateTime timestamp;
  final Duration processingTime;

  const OCRResult({
    required this.blocks,
    required this.fullText,
    required this.averageConfidence,
    this.detectedLanguage,
    required this.timestamp,
    required this.processingTime,
  });

  factory OCRResult.fromRecognizedText(
    RecognizedText recognizedText, {
    String? detectedLanguage,
    required Duration processingTime,
  }) {
    final blocks = recognizedText.blocks
        .map((block) => OCRTextBlock.fromMLKit(block, detectedLanguage: detectedLanguage))
        .toList();

    final avgConfidence = blocks.isEmpty
        ? 0.0
        : blocks.fold<double>(0.0, (sum, block) => sum + block.confidence) / blocks.length;

    return OCRResult(
      blocks: blocks,
      fullText: recognizedText.text,
      averageConfidence: avgConfidence,
      detectedLanguage: detectedLanguage,
      timestamp: DateTime.now(),
      processingTime: processingTime,
    );
  }

  bool get isEmpty => blocks.isEmpty;
  bool get isNotEmpty => blocks.isNotEmpty;
  bool get hasHighConfidence => averageConfidence >= 0.8;
  
  int get totalCharacters => fullText.length;
  int get totalWords => fullText.split(RegExp(r'\s+')).length;
  int get totalLines => blocks.fold(0, (sum, block) => sum + block.lines.length);

  /// Scale all blocks for display
  OCRResult scaleForDisplay(double scaleX, double scaleY, {Offset offset = Offset.zero}) {
    return OCRResult(
      blocks: blocks.map((block) => block.scaleBoundingBox(scaleX, scaleY, offset: offset)).toList(),
      fullText: fullText,
      averageConfidence: averageConfidence,
      detectedLanguage: detectedLanguage,
      timestamp: timestamp,
      processingTime: processingTime,
    );
  }
}

extension RectExtensions on Rect {
  Rect expandToInclude(Rect other) {
    return Rect.fromLTRB(
      left < other.left ? left : other.left,
      top < other.top ? top : other.top,
      right > other.right ? right : other.right,
      bottom > other.bottom ? bottom : other.bottom,
    );
  }
}
