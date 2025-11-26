import 'package:aves/theme/durations.dart';
import 'package:flutter/material.dart';

/// Floating action button to trigger OCR with status indicators
class OCRActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final OCRButtonState state;
  final double? progress;
  final String? statusMessage;

  const OCRActionButton({
    super.key,
    this.onPressed,
    this.state = OCRButtonState.idle,
    this.progress,
    this.statusMessage,
  });

  @override
  State<OCRActionButton> createState() => _OCRActionButtonState();
}

class _OCRActionButtonState extends State<OCRActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.state == OCRButtonState.processing) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(OCRActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == OCRButtonState.processing) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.statusMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.9),
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.state == OCRButtonState.processing)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 16.0,
                      height: 16.0,
                      child: CircularProgressIndicator(
                        value: widget.progress,
                        strokeWidth: 2.0,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                Text(
                  widget.statusMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ScaleTransition(
          scale: _pulseAnimation,
          child: FloatingActionButton(
            onPressed: widget.state == OCRButtonState.processing ? null : widget.onPressed,
            backgroundColor: _getButtonColor(),
            foregroundColor: Colors.white,
            elevation: 6.0,
            child: _buildIcon(),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    switch (widget.state) {
      case OCRButtonState.idle:
        return const Icon(Icons.text_fields_rounded, size: 28.0);
      case OCRButtonState.processing:
        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.text_fields_rounded, size: 28.0),
            SizedBox(
              width: 48.0,
              height: 48.0,
              child: CircularProgressIndicator(
                value: widget.progress,
                strokeWidth: 3.0,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        );
      case OCRButtonState.success:
        return const Icon(Icons.check_circle_rounded, size: 28.0);
      case OCRButtonState.error:
        return const Icon(Icons.error_rounded, size: 28.0);
    }
  }

  Color _getButtonColor() {
    switch (widget.state) {
      case OCRButtonState.idle:
        return Theme.of(context).colorScheme.primary;
      case OCRButtonState.processing:
        return Theme.of(context).colorScheme.secondary;
      case OCRButtonState.success:
        return Colors.green.shade600;
      case OCRButtonState.error:
        return Colors.red.shade600;
    }
  }

  Color _getStatusColor() {
    switch (widget.state) {
      case OCRButtonState.idle:
        return Theme.of(context).colorScheme.primary;
      case OCRButtonState.processing:
        return Theme.of(context).colorScheme.secondary;
      case OCRButtonState.success:
        return Colors.green.shade600;
      case OCRButtonState.error:
        return Colors.red.shade600;
    }
  }
}

/// State of the OCR button
enum OCRButtonState {
  idle,
  processing,
  success,
  error,
}

/// Compact OCR button for toolbar integration
class CompactOCRButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isActive;
  final String? tooltip;

  const CompactOCRButton({
    super.key,
    this.onPressed,
    this.isActive = false,
    this.tooltip = 'Scan text',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.text_fields_rounded,
        color: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

/// OCR mode toggle button
class OCRModeToggle extends StatelessWidget {
  final bool isOCRMode;
  final VoidCallback? onToggle;

  const OCRModeToggle({
    super.key,
    required this.isOCRMode,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: ADurations.viewerOverlayAnimation,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isOCRMode
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isOCRMode
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOCRMode ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              size: 20.0,
              color: isOCRMode
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8.0),
            Text(
              isOCRMode ? 'Text Selection Mode' : 'View Mode',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: isOCRMode
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
