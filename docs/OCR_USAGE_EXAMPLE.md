# OCR Usage Examples

## 🚀 Quick Start - Adding OCR to Image Viewer

### Step 1: Add OCR button to viewer overlay

In your `entry_viewer_stack.dart` or similar viewer file:

```dart
import 'package:aves/services/ocr/ocr_service.dart';
import 'package:aves/model/ocr/ocr_text_block.dart';
import 'package:aves/widgets/viewer/ocr/ocr_overlay.dart';
import 'package:aves/widgets/viewer/ocr/ocr_action_button.dart';
import 'package:aves/widgets/viewer/ocr/ocr_bottom_sheet.dart';

class ImageViewer extends StatefulWidget {
  final AvesEntry entry;
  
  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  OCRResult? _ocrResult;
  OCRButtonState _buttonState = OCRButtonState.idle;
  double _progress = 0.0;
  String? _statusMessage;
  
  Future<void> _performOCR() async {
    setState(() {
      _buttonState = OCRButtonState.processing;
      _progress = 0.0;
      _statusMessage = 'Scanning text...';
    });
    
    try {
      final result = await OCRService().extractTextEnhanced(
        widget.entry,
        enablePreprocessing: true, // Enable powerful preprocessing!
        retryWithAlternateScript: true,
        onProgress: (p) {
          setState(() {
            _progress = p;
            if (p < 0.3) {
              _statusMessage = 'Preprocessing image...';
            } else if (p < 0.7) {
              _statusMessage = 'Recognizing text...';
            } else {
              _statusMessage = 'Finalizing...';
            }
          });
        },
        onError: (e) {
          setState(() {
            _buttonState = OCRButtonState.error;
            _statusMessage = 'Error: $e';
          });
        },
      );
      
      if (result != null && result.isNotEmpty) {
        setState(() {
          _ocrResult = result;
          _buttonState = OCRButtonState.success;
          _statusMessage = '${result.totalWords} words found · ${(result.averageConfidence * 100).toInt()}% confident';
        });
        
        // Auto-show bottom sheet with results
        Future.delayed(Duration(milliseconds: 500), () {
          OCRBottomSheet.show(context, result);
        });
      } else {
        setState(() {
          _buttonState = OCRButtonState.error;
          _statusMessage = 'No text found';
        });
      }
    } catch (e) {
      setState(() {
        _buttonState = OCRButtonState.error;
        _statusMessage = 'OCR failed';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your existing image widget
        YourImageWidget(entry: widget.entry),
        
        // OCR overlay (shows bounding boxes when result available)
        if (_ocrResult != null)
          OCROverlay(
            ocrResult: _ocrResult,
            imageSize: Size(
              widget.entry.width?.toDouble() ?? 1920,
              widget.entry.height?.toDouble() ?? 1080,
            ),
            displaySize: MediaQuery.of(context).size,
            onBlockTap: (block) {
              // Show bottom sheet when user taps a text block
              OCRBottomSheet.show(context, _ocrResult!);
            },
          ),
        
        // OCR action button
        Positioned(
          right: 16,
          bottom: 80,
          child: OCRActionButton(
            state: _buttonState,
            progress: _progress,
            statusMessage: _statusMessage,
            onPressed: _performOCR,
          ),
        ),
      ],
    );
  }
}
```

## 🔧 Advanced Preprocessing Options

### Enable/Disable Preprocessing

```dart
// Maximum accuracy (recommended for most images)
final result = await OCRService().extractTextEnhanced(
  entry,
  enablePreprocessing: true, // Enable image enhancement
  retryWithAlternateScript: true, // Try alternate languages if confidence is low
);

// Faster processing (skip preprocessing)
final result = await OCRService().extractTextEnhanced(
  entry,
  enablePreprocessing: false,
  retryWithAlternateScript: false,
);
```

### Choose Recognition Script

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// Latin script (English, Spanish, French, etc.)
final result = await OCRService().extractTextEnhanced(
  entry,
  script: TextRecognitionScript.latin,
);

// Chinese script
final result = await OCRService().extractTextEnhanced(
  entry,
  script: TextRecognitionScript.chinese,
);

// Japanese script
final result = await OCRService().extractTextEnhanced(
  entry,
  script: TextRecognitionScript.japanese,
);

// Korean script
final result = await OCRService().extractTextEnhanced(
  entry,
  script: TextRecognitionScript.korean,
);
```

## 🎨 UI Customization Examples

### Custom OCR Button

```dart
// Floating button with custom position
Positioned(
  right: 16,
  bottom: 100,
  child: OCRActionButton(
    state: _buttonState,
    progress: _progress,
    statusMessage: _statusMessage,
    onPressed: () async {
      // Your custom OCR logic
    },
  ),
)

// Compact toolbar button
CompactOCRButton(
  isActive: _ocrResult != null,
  onPressed: _performOCR,
  tooltip: 'Extract text from image',
)

// Mode toggle
OCRModeToggle(
  isOCRMode: _showOCROverlay,
  onToggle: () {
    setState(() => _showOCROverlay = !_showOCROverlay);
  },
)
```

### Custom Overlay Styling

```dart
OCROverlay(
  ocrResult: _ocrResult,
  imageSize: imageSize,
  displaySize: displaySize,
  showConfidenceLabels: true, // Show confidence % on each block
  selectedBlock: _selectedBlock,
  onBlockTap: (block) {
    setState(() => _selectedBlock = block);
    // Show context actions or details
  },
)
```

## 📊 Working with OCR Results

### Extract Specific Data Types

```dart
final result = await OCRService().extractTextEnhanced(entry);

if (result != null) {
  for (final block in result.blocks) {
    // Extract emails
    if (block.isLikelyEmail) {
      final emails = block.extractEmails();
      print('Found emails: $emails');
    }
    
    // Extract phone numbers
    if (block.isLikelyPhone) {
      final phones = block.extractPhoneNumbers();
      print('Found phones: $phones');
    }
    
    // Extract URLs
    if (block.isLikelyUrl) {
      final urls = block.extractUrls();
      print('Found URLs: $urls');
    }
    
    // Extract currency amounts
    if (block.isLikelyPrice) {
      final amounts = block.extractCurrency();
      print('Found amounts: $amounts');
    }
  }
}
```

### Filter by Confidence

```dart
final highConfidenceBlocks = result.blocks.where((b) => b.hasHighConfidence).toList();
final lowConfidenceBlocks = result.blocks.where((b) => b.hasLowConfidence).toList();

print('High confidence: ${highConfidenceBlocks.length} blocks');
print('Low confidence: ${lowConfidenceBlocks.length} blocks');
```

### Get Statistics

```dart
print('Total words: ${result.totalWords}');
print('Total characters: ${result.totalCharacters}');
print('Total lines: ${result.totalLines}');
print('Average confidence: ${(result.averageConfidence * 100).toInt()}%');
print('Processing time: ${result.processingTime.inMilliseconds}ms');
print('Detected language: ${result.detectedLanguage}');
```

## ⚡ Performance Tips

### 1. Cache Management

```dart
// Clear cache for specific image
await OCRService().clearCache(cacheKey);

// Clear all cached results
await OCRService().clearAllCache();

// Check cache stats
final stats = await OCRService().getCacheStats();
print('Cached items: ${stats['memoryItems']}');
```

### 2. Progress Tracking

```dart
final result = await OCRService().extractTextEnhanced(
  entry,
  onProgress: (progress) {
    print('OCR Progress: ${(progress * 100).toInt()}%');
    // Update UI progress indicator
  },
);
```

### 3. Error Handling

```dart
final result = await OCRService().extractTextEnhanced(
  entry,
  onError: (error) {
    print('OCR Error: $error');
    // Show error message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OCR failed: $error')),
    );
  },
);
```

## 🌍 Language Detection & Multi-Script

### Auto-Detect Best Script

```dart
// Start with Latin, automatically retry with Chinese/Japanese/Korean if confidence is low
final result = await OCRService().extractTextEnhanced(
  entry,
  script: TextRecognitionScript.latin,
  retryWithAlternateScript: true,
);

if (result != null) {
  print('Detected language: ${result.detectedLanguage}');
}
```

### Process Mixed-Language Images

```dart
// Try multiple scripts and combine results
final latinResult = await OCRService().extractTextEnhanced(
  entry,
  script: TextRecognitionScript.latin,
  retryWithAlternateScript: false,
);

final chineseResult = await OCRService().extractTextEnhanced(
  entry,
  script: TextRecognitionScript.chinese,
  retryWithAlternateScript: false,
);

// Combine results based on confidence
```

## 🛠️ Troubleshooting

### OCR Returns Empty Results

1. **Enable preprocessing** - Improves text detection significantly
```dart
enablePreprocessing: true
```

2. **Try alternate scripts** - Language might be different than expected
```dart
retryWithAlternateScript: true
```

3. **Check image quality** - Ensure text is readable and not too blurred

### Low Confidence Results

1. **Image preprocessing helps** - Grayscale, contrast, binarization improve accuracy
2. **Choose correct script** - Latin for English, Chinese for 中文, etc.
3. **Image resolution** - Higher resolution = better results

### Performance Issues

1. **Disable preprocessing for faster results** (if image quality is already good)
2. **Cache is automatic** - Subsequent scans of same image are instant
3. **Reduce image size** before OCR if extremely large (> 10MB)

## 📝 Summary

### What Makes This OCR Powerful

✅ **Advanced Image Preprocessing**
  - Grayscale conversion
  - Contrast enhancement
  - Brightness adjustment
  - Sharpening filter
  - Otsu's binarization

✅ **Multi-Language Support**
  - Latin (English, Spanish, French, German, etc.)
  - Chinese (中文)
  - Japanese (日本語)
  - Korean (한국어)

✅ **Smart Features**
  - Auto-retry with alternate scripts
  - Confidence-based quality checks
  - Email/phone/URL extraction
  - SHA-256 hash-based caching
  - Persistent + memory cache

✅ **Modern UI**
  - Interactive bounding boxes
  - Confidence color coding
  - Google Lens-style actions
  - Bottom sheet with bulk operations

---

**Next Steps:**
1. Add OCR button to your image viewer
2. Test with different image types
3. Customize UI to match your app's design
4. Enable preprocessing for maximum accuracy!
