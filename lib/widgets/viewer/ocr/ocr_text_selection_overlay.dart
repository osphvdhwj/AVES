import 'dart:math';
import 'package:aves/model/ocr/ocr_text_block.dart';
import 'package:aves/theme/durations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Invisible text selection overlay - works like browser text selection
/// Long press to start selecting, drag handles to adjust selection
class OCRTextSelectionOverlay extends StatefulWidget {
  final OCRResult ocrResult;
  final Size imageSize;
  final Size displaySize;
  final Offset displayOffset;
  final VoidCallback? onSelectionChanged;
  final bool showDebugBounds;

  const OCRTextSelectionOverlay({
    super.key,
    required this.ocrResult,
    required this.imageSize,
    required this.displaySize,
    this.displayOffset = Offset.zero,
    this.onSelectionChanged,
    this.showDebugBounds = false,
  });

  @override
  State<OCRTextSelectionOverlay> createState() => _OCRTextSelectionOverlayState();
}

class _OCRTextSelectionOverlayState extends State<OCRTextSelectionOverlay> {
  // Selection state
  OCRTextElement? _startElement;
  OCRTextElement? _endElement;
  int _startCharIndex = 0;
  int _endCharIndex = 0;
  
  // UI state
  bool _isSelecting = false;
  Offset? _longPressPosition;
  OverlayEntry? _selectionHandlesOverlay;
  OverlayEntry? _contextMenuOverlay;

  // Scaled OCR result
  OCRResult? _scaledResult;

  @override
  void initState() {
    super.initState();
    _updateScaledResult();
  }

  @override
  void didUpdateWidget(OCRTextSelectionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ocrResult != widget.ocrResult ||
        oldWidget.displaySize != widget.displaySize) {
      _updateScaledResult();
    }
  }

  void _updateScaledResult() {
    final scaleX = widget.displaySize.width / widget.imageSize.width;
    final scaleY = widget.displaySize.height / widget.imageSize.height;
    _scaledResult = widget.ocrResult.scaleForDisplay(
      scaleX,
      scaleY,
      offset: widget.displayOffset,
    );
  }

  @override
  void dispose() {
    _removeOverlays();
    super.dispose();
  }

  void _removeOverlays() {
    _selectionHandlesOverlay?.remove();
    _selectionHandlesOverlay = null;
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
  }

  // Find text element at position
  OCRTextElement? _findElementAt(Offset position) {
    if (_scaledResult == null) return null;

    for (final block in _scaledResult!.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          if (element.boundingBox.contains(position)) {
            return element;
          }
        }
      }
    }
    return null;
  }

  // Calculate character index within element
  int _getCharIndexInElement(OCRTextElement element, Offset position) {
    final box = element.boundingBox;
    final relativeX = (position.dx - box.left) / box.width;
    final charIndex = (relativeX * element.text.length).round().clamp(0, element.text.length);
    return charIndex;
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final element = _findElementAt(details.localPosition);
    if (element == null) return;

    setState(() {
      _isSelecting = true;
      _longPressPosition = details.localPosition;
      _startElement = element;
      _endElement = element;
      _startCharIndex = _getCharIndexInElement(element, details.localPosition);
      _endCharIndex = _startCharIndex;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    _showSelectionHandles();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isSelecting) return;

    final element = _findElementAt(details.localPosition);
    if (element == null) return;

    setState(() {
      _endElement = element;
      _endCharIndex = _getCharIndexInElement(element, details.localPosition);
    });

    _updateSelectionHandles();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isSelecting) return;

    HapticFeedback.selectionClick();
    _showContextMenu();
  }

  void _showSelectionHandles() {
    _removeOverlays();

    _selectionHandlesOverlay = OverlayEntry(
      builder: (context) => _SelectionHandles(
        startRect: _getSelectionStartRect(),
        endRect: _getSelectionEndRect(),
        onStartDrag: (delta) => _updateStartHandle(delta),
        onEndDrag: (delta) => _updateEndHandle(delta),
      ),
    );

    Overlay.of(context).insert(_selectionHandlesOverlay!);
  }

  void _updateSelectionHandles() {
    _selectionHandlesOverlay?.markNeedsBuild();
  }

  Rect _getSelectionStartRect() {
    if (_startElement == null) return Rect.zero;
    final box = _startElement!.boundingBox;
    final charWidth = box.width / _startElement!.text.length;
    return Rect.fromLTWH(
      box.left + (_startCharIndex * charWidth),
      box.top,
      charWidth,
      box.height,
    );
  }

  Rect _getSelectionEndRect() {
    if (_endElement == null) return Rect.zero;
    final box = _endElement!.boundingBox;
    final charWidth = box.width / _endElement!.text.length;
    return Rect.fromLTWH(
      box.left + (_endCharIndex * charWidth),
      box.top,
      charWidth,
      box.height,
    );
  }

  void _updateStartHandle(Offset delta) {
    final newPosition = Offset(
      _getSelectionStartRect().left + delta.dx,
      _getSelectionStartRect().top + delta.dy,
    );

    final element = _findElementAt(newPosition);
    if (element != null) {
      setState(() {
        _startElement = element;
        _startCharIndex = _getCharIndexInElement(element, newPosition);
      });
      _updateSelectionHandles();
    }
  }

  void _updateEndHandle(Offset delta) {
    final newPosition = Offset(
      _getSelectionEndRect().right + delta.dx,
      _getSelectionEndRect().bottom + delta.dy,
    );

    final element = _findElementAt(newPosition);
    if (element != null) {
      setState(() {
        _endElement = element;
        _endCharIndex = _getCharIndexInElement(element, newPosition);
      });
      _updateSelectionHandles();
    }
  }

  void _showContextMenu() {
    _contextMenuOverlay?.remove();

    final selectedText = _getSelectedText();
    if (selectedText.isEmpty) return;

    final menuRect = _getSelectionBounds();

    _contextMenuOverlay = OverlayEntry(
      builder: (context) => _ContextMenu(
        text: selectedText,
        position: Offset(menuRect.center.dx, menuRect.top - 50),
        onCopy: () {
          Clipboard.setData(ClipboardData(text: selectedText));
          _clearSelection();
        },
        onShare: () {
          // TODO: Implement share
          _clearSelection();
        },
        onSearch: () {
          // TODO: Implement search
          _clearSelection();
        },
        onDismiss: _clearSelection,
      ),
    );

    Overlay.of(context).insert(_contextMenuOverlay!);
  }

  String _getSelectedText() {
    if (_startElement == null || _endElement == null) return '';

    // Single element selection
    if (_startElement == _endElement) {
      final start = min(_startCharIndex, _endCharIndex);
      final end = max(_startCharIndex, _endCharIndex);
      return _startElement!.text.substring(start, end);
    }

    // Multi-element selection
    // TODO: Implement multi-element text extraction
    return _startElement!.text;
  }

  Rect _getSelectionBounds() {
    final startRect = _getSelectionStartRect();
    final endRect = _getSelectionEndRect();
    return Rect.fromLTRB(
      min(startRect.left, endRect.left),
      min(startRect.top, endRect.top),
      max(startRect.right, endRect.right),
      max(startRect.bottom, endRect.bottom),
    );
  }

  void _clearSelection() {
    setState(() {
      _isSelecting = false;
      _startElement = null;
      _endElement = null;
      _startCharIndex = 0;
      _endCharIndex = 0;
    });
    _removeOverlays();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: _handleLongPressMoveUpdate,
      onLongPressEnd: _handleLongPressEnd,
      onTap: () {
        if (_isSelecting) _clearSelection();
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Debug bounds (optional)
            if (widget.showDebugBounds)
              ..._buildDebugBounds(),
            
            // Selection highlight
            if (_isSelecting)
              _buildSelectionHighlight(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHighlight() {
    final bounds = _getSelectionBounds();
    return Positioned(
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  List<Widget> _buildDebugBounds() {
    if (_scaledResult == null) return [];

    final widgets = <Widget>[];
    for (final block in _scaledResult!.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final box = element.boundingBox;
          widgets.add(
            Positioned(
              left: box.left,
              top: box.top,
              width: box.width,
              height: box.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                ),
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }
}

/// Selection handles (like browser text selection)
class _SelectionHandles extends StatelessWidget {
  final Rect startRect;
  final Rect endRect;
  final Function(Offset) onStartDrag;
  final Function(Offset) onEndDrag;

  const _SelectionHandles({
    required this.startRect,
    required this.endRect,
    required this.onStartDrag,
    required this.onEndDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Start handle
        Positioned(
          left: startRect.left - 12,
          top: startRect.top,
          child: GestureDetector(
            onPanUpdate: (details) => onStartDrag(details.delta),
            child: _Handle(isStart: true),
          ),
        ),
        // End handle
        Positioned(
          left: endRect.right - 12,
          top: endRect.bottom - 24,
          child: GestureDetector(
            onPanUpdate: (details) => onEndDrag(details.delta),
            child: _Handle(isStart: false),
          ),
        ),
      ],
    );
  }
}

/// Individual selection handle
class _Handle extends StatelessWidget {
  final bool isStart;

  const _Handle({required this.isStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 4,
          height: isStart ? 18 : 4,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: isStart ? Radius.circular(2) : Radius.zero,
              bottom: isStart ? Radius.zero : Radius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Context menu for selected text
class _ContextMenu extends StatelessWidget {
  final String text;
  final Offset position;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSearch;
  final VoidCallback onDismiss;

  const _ContextMenu({
    required this.text,
    required this.position,
    required this.onCopy,
    required this.onShare,
    required this.onSearch,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu
        Positioned(
          left: position.dx - 100,
          top: position.dy,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuItem(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: onCopy,
                  ),
                  _MenuItem(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: onShare,
                  ),
                  _MenuItem(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    onTap: onSearch,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
