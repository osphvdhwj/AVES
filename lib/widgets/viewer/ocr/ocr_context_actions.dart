import 'package:aves/model/ocr/ocr_text_block.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Google Lens-style floating action bubble for OCR text blocks
class OCRContextActions extends StatefulWidget {
  final OCRTextBlock textBlock;
  final Offset position;
  final VoidCallback? onDismiss;

  const OCRContextActions({
    super.key,
    required this.textBlock,
    required this.position,
    this.onDismiss,
  });

  @override
  State<OCRContextActions> createState() => _OCRContextActionsState();
}

class _OCRContextActionsState extends State<OCRContextActions> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAction(OCRAction action) async {
    try {
      switch (action) {
        case OCRAction.copy:
          await _copyToClipboard();
          break;
        case OCRAction.share:
          await _shareText();
          break;
        case OCRAction.search:
          await _searchText();
          break;
        case OCRAction.translate:
          await _translateText();
          break;
      }
      _dismiss();
    } catch (e) {
      debugPrint('[OCR Actions] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: ${action.label}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.textBlock.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareText() async {
    await Share.share(
      widget.textBlock.text,
      subject: 'Extracted text from image',
    );
  }

  Future<void> _searchText() async {
    final query = Uri.encodeComponent(widget.textBlock.text);
    final url = 'https://www.google.com/search?q=$query';
    await appService.open(url);
  }

  Future<void> _translateText() async {
    final query = Uri.encodeComponent(widget.textBlock.text);
    final sourceLang = widget.textBlock.language ?? 'auto';
    final url = 'https://translate.google.com/?sl=$sourceLang&text=$query';
    await appService.open(url);
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            elevation: 8.0,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(28.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...OCRAction.values.map((action) {
                    return _ActionButton(
                      action: action,
                      onPressed: () => _handleAction(action),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual action button within the context bubble
class _ActionButton extends StatefulWidget {
  final OCRAction action;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.action,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: _isPressed
              ? (isDark ? Colors.white12 : Colors.black12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(28.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.action.icon,
              size: 24.0,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4.0),
            Text(
              widget.action.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Available OCR actions
enum OCRAction {
  copy,
  share,
  search,
  translate,
}

extension OCRActionExtension on OCRAction {
  String get label {
    switch (this) {
      case OCRAction.copy:
        return 'Copy';
      case OCRAction.share:
        return 'Share';
      case OCRAction.search:
        return 'Search';
      case OCRAction.translate:
        return 'Translate';
    }
  }

  IconData get icon {
    switch (this) {
      case OCRAction.copy:
        return Icons.copy_rounded;
      case OCRAction.share:
        return Icons.share_rounded;
      case OCRAction.search:
        return Icons.search_rounded;
      case OCRAction.translate:
        return Icons.translate_rounded;
    }
  }
}

/// Compact action bar for selected text
class OCRActionBar extends StatelessWidget {
  final String text;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onSearch;
  final VoidCallback? onTranslate;

  const OCRActionBar({
    super.key,
    required this.text,
    this.onCopy,
    this.onShare,
    this.onSearch,
    this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: onCopy,
              tooltip: 'Copy',
              padding: const EdgeInsets.all(8.0),
            ),
          if (onShare != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20),
              onPressed: onShare,
              tooltip: 'Share',
              padding: const EdgeInsets.all(8.0),
            ),
          if (onSearch != null)
            IconButton(
              icon: const Icon(Icons.search_rounded, size: 20),
              onPressed: onSearch,
              tooltip: 'Search',
              padding: const EdgeInsets.all(8.0),
            ),
          if (onTranslate != null)
            IconButton(
              icon: const Icon(Icons.translate_rounded, size: 20),
              onPressed: onTranslate,
              tooltip: 'Translate',
              padding: const EdgeInsets.all(8.0),
            ),
        ],
      ),
    );
  }
}
