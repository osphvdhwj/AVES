# Quick Start: OCR Integration

## 🚀 Fast Track Implementation (30 Minutes)

This guide helps you integrate the OCR feature into your existing Aves viewer with minimal modifications.

## Step 1: Verify Branch

```bash
git fetch origin
git checkout feature/ocr-integration
./flutterw pub get
```

## Step 2: Essential Files to Modify

You only need to modify **ONE** existing file:

### `lib/widgets/viewer/entry_viewer_stack.dart`

Add these imports at the top:

```dart
// Add after existing imports
import 'package:aves/services/ocr/ocr_service.dart';
import 'package:aves/widgets/viewer/overlay/ocr_overlay.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
```

Add these state variables in `_EntryViewerStackState` class:

```dart
class _EntryViewerStackState extends State<EntryViewerStack> {
  // ... existing variables ...
  
  // ADD THESE:
  late OCRService _ocrService;
  final ValueNotifier<RecognizedText?> _ocrResultNotifier = ValueNotifier(null);
  bool _ocrMode = false;
  bool _isProcessingOCR = false;
```

In `initState()`, add:

```dart
@override
void initState() {
  super.initState();
  // ... existing init code ...
  
  // ADD THIS:
  _ocrService = OCRService();
}
```

In `dispose()`, add:

```dart
@override
void dispose() {
  // ADD THIS BEFORE other dispose calls:
  _ocrService.dispose();
  _ocrResultNotifier.dispose();
  
  // ... existing dispose code ...
  super.dispose();
}
```

Add this method anywhere in the class:

```dart
Future<void> _performOCR() async {
  final entry = entryNotifier.value;
  if (entry == null || !entry.isImage) return;
  
  setState(() => _isProcessingOCR = true);
  
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Extracting text...'),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await _ocrService.extractText(entry);
    
    if (mounted) Navigator.pop(context); // Close loading dialog
    
    if (result != null && result.text.isNotEmpty) {
      _ocrResultNotifier.value = result;
      setState(() => _ocrMode = true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text found in image'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to extract text: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isProcessingOCR = false);
  }
}
```

Modify the `_buildOverlays` method:

```dart
List<Widget> _buildOverlays(Size availableSize) {
  final appMode = context.read<ValueNotifier<AppMode>>().value;
  
  List<Widget> overlays;
  switch (appMode) {
    case AppMode.screenSaver:
      overlays = [];
      break;
    case AppMode.slideshow:
      overlays = [
        _buildViewerTopOverlay(availableSize),
        _buildSlideshowBottomOverlay(availableSize),
      ];
      break;
    default:
      overlays = [
        _buildViewerTopOverlay(availableSize),
        _buildViewerBottomOverlay(availableSize),
      ];
  }
  
  // ADD THIS: OCR overlay
  if (_ocrMode && _ocrResultNotifier.value != null) {
    overlays.add(
      OCROverlay(
        entry: entryNotifier.value!,
        recognizedText: _ocrResultNotifier.value!,
        onClose: () => setState(() => _ocrMode = false),
        animation: _overlayAnimationController,
      ),
    );
  }
  
  return overlays;
}
```

In the `build()` method, wrap the entire return widget with gesture detector.

Find this line (around line 230):
```dart
return PopScope(
```

Wrap it like this:
```dart
return GestureDetector(
  onLongPressStart: isViewingImage && !_viewLocked.value && !_isProcessingOCR
      ? (_) => _performOCR()
      : null,
  behavior: HitTestBehavior.translucent,
  child: PopScope(
    // ... rest of existing code ...
  ),
);
```

## Step 3: Test It!

```bash
./flutterw run -t lib/main_play.dart --flavor play
```

1. Open any image with text
2. Long-press (hold) on the image for ~0.5 seconds
3. Wait for "Extracting text..." dialog
4. OCR overlay should appear with highlighted text!

## Step 4: (Optional) Fix Grid Selection Conflict

If you want to prevent the "hold to select multiple" gesture from interfering:

### Modify `lib/widgets/collection/collection_grid.dart`

Find the `GridSelectionGestureDetector` usage (around line 600):

```dart
// BEFORE:
final selector = GridSelectionGestureDetector<AvesEntry>(
  scrollableKey: _scrollableKey,
  selectable: widget.selectable,
  items: collection.sortedEntries,
  scrollController: scrollController,
  appBarHeightNotifier: _appBarHeightNotifier,
  child: scaler,
);
```

Replace import at top:
```dart
// CHANGE:
import 'package:aves/widgets/common/grid/selector.dart';

// TO:
import 'package:aves/widgets/common/grid/selector_ocr_aware.dart';
```

Replace the selector instantiation:
```dart
// AFTER:
final selector = GridSelectionGestureDetectorOCRAware<AvesEntry>(
  scrollableKey: _scrollableKey,
  selectable: widget.selectable,
  items: collection.sortedEntries,
  scrollController: scrollController,
  appBarHeightNotifier: _appBarHeightNotifier,
  isInViewerMode: false,  // Always false in grid
  child: scaler,
);
```

## Done! 🎉

You now have working OCR functionality!

## Common Issues

### "OCR not triggering"
- Make sure you're in full-screen image view (not grid)
- Hold longer (at least 500ms)
- Check you're pressing on an image, not video

### "Build errors"
```bash
./flutterw clean
./flutterw pub get
./flutterw run -t lib/main_play.dart --flavor play
```

### "No text found" on images with text
- Ensure good image quality
- Try printed text (handwriting less reliable)
- Check sufficient contrast

## Next Steps

See `OCR_IMPLEMENTATION.md` for:
- Advanced customization
- Settings UI integration
- Multi-language support
- Performance tuning
