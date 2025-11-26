# OCR Integration Guide

## Overview

This guide documents the modern OCR integration updates for Aves Gallery, providing Google Lens-style text recognition with interactive overlays and context actions.

## Architecture

### Component Structure

```
lib/
├── model/ocr/
│   └── ocr_text_block.dart          # Data models for OCR results
├── services/ocr/
│   └── ocr_service.dart             # Enhanced OCR processing service
└── widgets/viewer/ocr/
    ├── ocr_overlay.dart             # Interactive bounding box overlay
    ├── ocr_context_actions.dart     # Google Lens-style action bubble
    ├── ocr_bottom_sheet.dart        # Bulk text operations sheet
    └── ocr_action_button.dart       # Floating action button with status
```

## Key Features

### 1. **Enhanced OCR Model** (`ocr_text_block.dart`)

- **OCRTextBlock**: Rich text block model with:
  - Bounding box coordinates with scaling utilities
  - Confidence scores and language detection
  - Smart data extraction (emails, phones, URLs, currency)
  - Block merging for improved readability

- **OCRResult**: Complete OCR processing result:
  - Collection of text blocks
  - Average confidence metrics
  - Processing time tracking
  - Language detection

```dart
// Example usage
final result = await ocrService.extractTextEnhanced(entry);
if (result != null) {
  print('Found ${result.totalWords} words');
  print('Confidence: ${(result.averageConfidence * 100).toInt()}%');
  
  for (final block in result.blocks) {
    if (block.isLikelyEmail) {
      print('Email found: ${block.extractEmails()}');
    }
  }
}
```

### 2. **Enhanced OCR Service** (`ocr_service.dart`)

**New Features:**
- ✅ Multi-language support (Latin, Chinese, Japanese, Korean, Devanagari)
- ✅ Image hash-based caching for better cache hits
- ✅ Smart fallback to alternate languages on low confidence
- ✅ Enhanced result model (OCRResult) with block-level metadata
- ✅ Improved serialization for persistent caching

**Configuration:**
```dart
// Extract text with specific language
final result = await ocrService.extractTextEnhanced(
  entry,
  script: TextRecognitionScript.japanese,
  retryWithAlternateScript: true,
  onProgress: (progress) => print('Progress: ${(progress * 100).toInt()}%'),
);
```

### 3. **Interactive Overlay** (`ocr_overlay.dart`)

**Features:**
- Visual bounding boxes over detected text
- Confidence-based color coding (green/orange/red)
- Smooth fade-in animations
- Tap feedback with scale transforms
- Theme-aware styling (dark/light mode)
- Per-block confidence and language labels

**Integration:**
```dart
OCROverlay(
  ocrResult: ocrResult,
  imageSize: Size(1920, 1080),
  displaySize: Size(800, 600),
  onBlockTap: (block) {
    // Handle block selection
  },
)
```

### 4. **Context Actions** (`ocr_context_actions.dart`)

**Google Lens-Style Bubble:**
- **Copy**: Copy text to clipboard
- **Share**: Share via system share sheet
- **Search**: Google search for selected text
- **Translate**: Open Google Translate

**Visual Design:**
- Material Design 3 elevation
- Smooth scale + fade animations
- Rounded action buttons with icons and labels
- Adaptive positioning above selected text

### 5. **Bottom Sheet** (`ocr_bottom_sheet.dart`)

**Bulk Operations:**
- View all detected text blocks
- Select individual blocks or all text
- Bulk actions: Copy All, Share All, Search, Translate
- Metadata display: confidence, language, data type indicators
- Smart text categorization (email, phone, URL detection)

**Stats Display:**
- Total words and lines
- Average confidence
- Processing time

### 6. **Action Button** (`ocr_action_button.dart`)

**States:**
- `idle`: Ready to scan
- `processing`: Scanning with progress indicator
- `success`: Scan completed
- `error`: Error occurred

**Visual Feedback:**
- Pulsing animation during processing
- Color changes based on state
- Status messages with progress percentage
- Smooth transitions

## UI/UX Guidelines

### Color Scheme

**Light Mode:**
- Overlay background: `Colors.white.withOpacity(0.85)`
- High confidence: `Colors.green.shade700`
- Medium confidence: `Colors.orange.shade700`
- Low confidence: `Colors.red.shade700`

**Dark Mode:**
- Overlay background: `Colors.black.withOpacity(0.80)`
- High confidence: `Colors.green.shade300`
- Medium confidence: `Colors.orange.shade300`
- Low confidence: `Colors.red.shade300`

### Animations

- Bounding box fade-in: 150ms (ADurations.viewerOverlayAnimation)
- Action bubble: 200ms with easeOutBack curve
- Bottom sheet: 300ms (ADurations.bottomSheetAnimation)
- Tap feedback: 100ms scale transform

### Typography

- Confidence labels: 9px, w600
- Language tags: 8px, w600, uppercase, letter-spacing 0.5
- Action labels: 10px, w500
- Body text: Theme.textTheme.bodyMedium

## Integration Example

Here's how to integrate OCR into the image viewer:

```dart
class ImageViewerWithOCR extends StatefulWidget {
  final AvesEntry entry;
  
  @override
  State<ImageViewerWithOCR> createState() => _ImageViewerWithOCRState();
}

class _ImageViewerWithOCRState extends State<ImageViewerWithOCR> {
  OCRResult? _ocrResult;
  OCRTextBlock? _selectedBlock;
  OCRButtonState _buttonState = OCRButtonState.idle;
  double _progress = 0.0;
  
  Future<void> _performOCR() async {
    setState(() {
      _buttonState = OCRButtonState.processing;
      _progress = 0.0;
    });
    
    final result = await OCRService().extractTextEnhanced(
      widget.entry,
      onProgress: (p) => setState(() => _progress = p),
      onError: (e) => _showError(e),
    );
    
    setState(() {
      _ocrResult = result;
      _buttonState = result != null 
          ? OCRButtonState.success 
          : OCRButtonState.error;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Image display
        ImageWidget(entry: widget.entry),
        
        // OCR overlay
        if (_ocrResult != null)
          OCROverlay(
            ocrResult: _ocrResult,
            imageSize: widget.entry.displaySize,
            displaySize: MediaQuery.of(context).size,
            onBlockTap: (block) {
              setState(() => _selectedBlock = block);
            },
            selectedBlock: _selectedBlock,
          ),
        
        // Context actions
        if (_selectedBlock != null)
          OCRContextActions(
            textBlock: _selectedBlock!,
            position: _calculatePosition(_selectedBlock!),
            onDismiss: () => setState(() => _selectedBlock = null),
          ),
        
        // Action button
        Positioned(
          right: 16,
          bottom: 16,
          child: OCRActionButton(
            state: _buttonState,
            progress: _progress,
            statusMessage: _getStatusMessage(),
            onPressed: _performOCR,
          ),
        ),
      ],
    );
  }
}
```

## Performance Considerations

### Caching Strategy

1. **Image Hash-Based Keys**: Cache uses SHA-256 hash of image content
2. **Two-Tier Cache**: Memory (50 items) + Persistent (SharedPreferences)
3. **24-Hour Expiry**: Cached results expire after 24 hours
4. **LRU Eviction**: Oldest items removed when cache is full

### Memory Management

- OCR results stored with minimal serialization
- Bounding boxes scaled on-demand
- Text blocks lazy-loaded when displayed
- Recognizers disposed when service is disposed

### Image Processing

- Maximum image size: 8MB
- Automatic retry with alternate script on low confidence
- Processing time tracked for performance monitoring

## Error Handling

### Common Errors

1. **File Not Found**: Image file doesn't exist or path is invalid
2. **OCR Not Available**: Build variant doesn't support OCR
3. **Low Confidence**: Text detection confidence below threshold
4. **Processing Timeout**: Image too large or complex

### Recovery Strategies

```dart
try {
  final result = await ocrService.extractTextEnhanced(entry);
  if (result == null || result.isEmpty) {
    // No text found
    showSnackBar('No text detected in image');
  } else if (result.hasLowConfidence) {
    // Low confidence warning
    showSnackBar('Text detection confidence is low');
  }
} catch (e) {
  // Handle error
  showErrorDialog('OCR failed: $e');
}
```

## Testing

### Unit Tests

```dart
test('OCRTextBlock extracts emails correctly', () {
  final block = OCRTextBlock(
    text: 'Contact: john@example.com for info',
    boundingBox: Rect.zero,
  );
  
  expect(block.isLikelyEmail, true);
  expect(block.extractEmails(), ['john@example.com']);
});
```

### Widget Tests

```dart
testWidgets('OCR overlay displays bounding boxes', (tester) async {
  final result = OCRResult(...);
  
  await tester.pumpWidget(
    MaterialApp(
      home: OCROverlay(
        ocrResult: result,
        imageSize: Size(800, 600),
        displaySize: Size(800, 600),
      ),
    ),
  );
  
  expect(find.byType(OCROverlay), findsOneWidget);
});
```

## Dependencies

Ensure these packages are in `pubspec.yaml`:

```yaml
dependencies:
  google_mlkit_text_recognition: ^0.13.0
  shared_preferences: ^2.2.2
  share_plus: ^7.2.1
  crypto: ^3.0.3
```

## Migration Notes

### From Legacy OCR

The new system is backward compatible. Legacy code using `extractText()` continues to work:

```dart
// Legacy (still supported)
final recognizedText = await ocrService.extractText(entry);

// New (recommended)
final ocrResult = await ocrService.extractTextEnhanced(entry);
```

### Cache Migration

Old cache entries (`ocr_cache_*`) are not automatically migrated. They will expire naturally or can be cleared:

```dart
await ocrService.clearAllCache();
```

## Future Enhancements

- [ ] Advanced image preprocessing (deskew, denoise, contrast)
- [ ] Table structure recognition
- [ ] Handwriting recognition
- [ ] Multi-page document OCR
- [ ] Export to structured formats (JSON, CSV)
- [ ] OCR history and search
- [ ] Integration with note-taking apps

## Troubleshooting

### OCR Not Working

1. Check build flavor supports OCR: `ExtraAppFlavor.current.supportsOCR`
2. Verify ML Kit models are downloaded
3. Ensure image is valid format (JPEG, PNG, WebP)
4. Check file permissions

### Low Accuracy

1. Try different language scripts
2. Ensure image has sufficient resolution
3. Check image is well-lit and text is clear
4. Verify text is horizontal (rotation not yet supported)

### Performance Issues

1. Reduce image size before processing
2. Clear cache if too large: `clearAllCache()`
3. Check memory usage
4. Disable retry with alternate script for faster processing

## Credits

- **ML Kit**: Google ML Kit for text recognition
- **Design Inspiration**: Google Lens for UI/UX patterns
- **Aves Gallery**: Base gallery application

## License

Same as Aves Gallery main project.
