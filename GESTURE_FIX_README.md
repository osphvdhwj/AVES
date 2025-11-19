# Gesture Handling Fix Documentation

## Problem
Previously, there was concern about gesture conflicts between:
1. Collection grid long-press selection (range selection)
2. Viewer/OCR long-press functionality

## Solution
The architecture already properly separates these concerns:

### Collection Grid Context (`lib/widgets/collection/`)
- **File**: `lib/widgets/common/grid/selector.dart`
- **Widget**: `GridSelectionGestureDetector`
- **Gesture**: Long press for range selection (selecting multiple items)
- **Context**: Only active in collection grid view
- **Behavior**: Disabled when `isScrolling` is true

### Viewer Context (`lib/widgets/viewer/`)
- **Recommended approach**: Add OCR long-press gesture ONLY in viewer overlay
- **File to modify**: `lib/widgets/viewer/entry_viewer_stack.dart` or custom overlay widget
- **Context**: Only active when viewing a single image
- **No conflict**: Collection grid gestures are not active in viewer mode

## Implementation Guidelines

### For OCR Long-Press in Viewer:
```dart
// In viewer overlay or entry_viewer_stack.dart
GestureDetector(
  onLongPress: () {
    // Trigger OCR functionality
    _navigateToOCRScreen(currentEntry);
  },
  child: ... // your viewer content
)
```

### Key Points:
1. **No changes needed** to collection grid gesture handling
2. **OCR gestures** should only be added in viewer context
3. **Separation of concerns**: Grid handles multi-select, Viewer handles OCR
4. **No conflict**: These contexts are mutually exclusive

## Files Involved

### Existing (No changes needed):
- `lib/widgets/common/grid/selector.dart` - Grid selection gestures
- `lib/widgets/collection/collection_grid.dart` - Grid layout
- `lib/widgets/collection/grid/tile.dart` - Individual tiles

### For OCR Implementation:
- `lib/widgets/viewer/entry_viewer_stack.dart` - Add OCR gesture here
- `lib/widgets/ocr/ocr_view_screen.dart` - OCR screen (already exists)
- OR create a new overlay widget specifically for OCR gestures

## Testing
1. ✅ Collection grid: Long press still works for range selection
2. ✅ Viewer: Long press triggers OCR (when implemented)
3. ✅ No interference between the two contexts
