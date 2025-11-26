import 'package:aves/model/ocr/ocr_text_block.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/widgets/common/extensions/theme.dart';
import 'package:flutter/material.dart';

/// Interactive overlay displaying OCR text blocks with bounding boxes
class OCROverlay extends StatefulWidget {
  final OCRResult? ocrResult;
  final Size imageSize;
  final Size displaySize;
  final Offset displayOffset;
  final Function(OCRTextBlock)? onBlockTap;
  final OCRTextBlock? selectedBlock;
  final bool showConfidenceLabels;

  const OCROverlay({
    super.key,
    this.ocrResult,
    required this.imageSize,
    required this.displaySize,
    this.displayOffset = Offset.zero,
    this.onBlockTap,
    this.selectedBlock,
    this.showConfidenceLabels = true,
  });

  @override
  State<OCROverlay> createState() => _OCROverlayState();
}

class _OCROverlayState extends State<OCROverlay> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: ADurations.viewerOverlayAnimation,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(OCROverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ocrResult != widget.ocrResult) {
      _fadeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.ocrResult;
    if (result == null || result.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate scale factors
    final scaleX = widget.displaySize.width / widget.imageSize.width;
    final scaleY = widget.displaySize.height / widget.imageSize.height;

    // Scale OCR result for display
    final scaledResult = result.scaleForDisplay(
      scaleX,
      scaleY,
      offset: widget.displayOffset,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          ...scaledResult.blocks.map((block) {
            final isSelected = widget.selectedBlock?.text == block.text &&
                widget.selectedBlock?.boundingBox == block.boundingBox;

            return _BoundingBoxWidget(
              block: block,
              isSelected: isSelected,
              showConfidence: widget.showConfidenceLabels,
              onTap: () => widget.onBlockTap?.call(block),
            );
          }),
        ],
      ),
    );
  }
}

/// Widget representing a single OCR text block bounding box
class _BoundingBoxWidget extends StatefulWidget {
  final OCRTextBlock block;
  final bool isSelected;
  final bool showConfidence;
  final VoidCallback? onTap;

  const _BoundingBoxWidget({
    required this.block,
    required this.isSelected,
    required this.showConfidence,
    this.onTap,
  });

  @override
  State<_BoundingBoxWidget> createState() => _BoundingBoxWidgetState();
}

class _BoundingBoxWidgetState extends State<_BoundingBoxWidget> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  Color _getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).isDark;
    
    if (widget.isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    
    if (widget.block.hasHighConfidence) {
      return isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (widget.block.hasMediumConfidence) {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    } else {
      return isDark ? Colors.red.shade300 : Colors.red.shade700;
    }
  }

  Color _getFillColor(BuildContext context) {
    final borderColor = _getBorderColor(context);
    return borderColor.withOpacity(widget.isSelected ? 0.15 : 0.05);
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.block.boundingBox;
    final borderColor = _getBorderColor(context);
    final fillColor = _getFillColor(context);

    return Positioned(
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(
                color: borderColor,
                width: widget.isSelected ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: borderColor.withOpacity(0.3),
                        blurRadius: 8.0,
                        spreadRadius: 1.0,
                      ),
                    ]
                  : null,
            ),
            child: widget.showConfidence && box.height > 24
                ? Align(
                    alignment: Alignment.topRight,
                    child: _ConfidenceLabel(
                      confidence: widget.block.confidence,
                      language: widget.block.language,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Small label showing confidence percentage and language
class _ConfidenceLabel extends StatelessWidget {
  final double confidence;
  final String? language;

  const _ConfidenceLabel({
    required this.confidence,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).isDark;
    final percentText = '${(confidence * 100).toInt()}%';
    
    return Container(
      margin: const EdgeInsets.all(2.0),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.black87 : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(3.0),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (language != null) ..[
            Text(
              language!.toUpperCase(),
              style: TextStyle(
                fontSize: 8.0,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 3.0),
            Container(
              width: 1.0,
              height: 8.0,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
            const SizedBox(width: 3.0),
          ],
          Text(
            percentText,
            style: TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.w600,
              color: _getConfidenceColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(BuildContext context) {
    final isDark = Theme.of(context).isDark;
    
    if (confidence >= 0.8) {
      return isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (confidence >= 0.6) {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    } else {
      return isDark ? Colors.red.shade300 : Colors.red.shade700;
    }
  }
}

/// Loading indicator for OCR processing
class OCRLoadingOverlay extends StatelessWidget {
  final String message;
  final double? progress;

  const OCRLoadingOverlay({
    super.key,
    this.message = 'Scanning text...',
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).isDark;

    return Container(
      color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
      child: Center(
        child: Card(
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (progress != null)
                  SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3.0,
                    ),
                  )
                else
                  const SizedBox(
                    width: 48.0,
                    height: 48.0,
                    child: CircularProgressIndicator(strokeWidth: 3.0),
                  ),
                const SizedBox(height: 16.0),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (progress != null) ..[
                  const SizedBox(height: 8.0),
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
