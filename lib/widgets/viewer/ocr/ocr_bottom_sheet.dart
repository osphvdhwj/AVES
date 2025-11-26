import 'package:aves/model/ocr/ocr_text_block.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/durations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Bottom sheet displaying all OCR results with bulk actions
class OCRBottomSheet extends StatefulWidget {
  final OCRResult ocrResult;
  final VoidCallback? onClose;

  const OCRBottomSheet({
    super.key,
    required this.ocrResult,
    this.onClose,
  });

  static Future<void> show(BuildContext context, OCRResult result) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OCRBottomSheet(ocrResult: result),
    );
  }

  @override
  State<OCRBottomSheet> createState() => _OCRBottomSheetState();
}

class _OCRBottomSheetState extends State<OCRBottomSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Set<int> _selectedBlockIndices = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: ADurations.bottomSheetAnimation,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _selectedText {
    if (_selectAll || _selectedBlockIndices.isEmpty) {
      return widget.ocrResult.fullText;
    }
    return _selectedBlockIndices
        .map((i) => widget.ocrResult.blocks[i].text)
        .join(' ');
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _selectedText));
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
      _selectedText,
      subject: 'Extracted text from image',
    );
  }

  Future<void> _searchText() async {
    final query = Uri.encodeComponent(_selectedText);
    final url = 'https://www.google.com/search?q=$query';
    await appService.open(url);
  }

  Future<void> _translateText() async {
    final query = Uri.encodeComponent(_selectedText);
    final sourceLang = widget.ocrResult.detectedLanguage ?? 'auto';
    final url = 'https://translate.google.com/?sl=$sourceLang&text=$query';
    await appService.open(url);
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedBlockIndices.clear();
      }
    });
  }

  void _toggleBlock(int index) {
    setState(() {
      if (_selectedBlockIndices.contains(index)) {
        _selectedBlockIndices.remove(index);
      } else {
        _selectedBlockIndices.add(index);
        _selectAll = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.ocrResult;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16.0,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12.0),
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extracted Text',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${result.totalWords} words · '
                            '${result.totalLines} lines · '
                            '${(result.averageConfidence * 100).toInt()}% confident',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Action bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _ActionChip(
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                            onPressed: _copyToClipboard,
                          ),
                          _ActionChip(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onPressed: _shareText,
                          ),
                          _ActionChip(
                            icon: Icons.search_rounded,
                            label: 'Search',
                            onPressed: _searchText,
                          ),
                          _ActionChip(
                            icon: Icons.translate_rounded,
                            label: 'Translate',
                            onPressed: _translateText,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(
                        _selectAll ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 20,
                      ),
                      label: const Text('All'),
                      onPressed: _toggleSelectAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  shrinkWrap: true,
                  itemCount: result.blocks.length,
                  separatorBuilder: (context, index) => const Divider(height: 24.0),
                  itemBuilder: (context, index) {
                    final block = result.blocks[index];
                    final isSelected = _selectAll || _selectedBlockIndices.contains(index);

                    return _TextBlockTile(
                      block: block,
                      isSelected: isSelected,
                      onTap: () => _toggleBlock(index),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Action chip for bottom sheet actions
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}

/// Individual text block tile
class _TextBlockTile extends StatelessWidget {
  final OCRTextBlock block;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TextBlockTile({
    required this.block,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      _InfoChip(
                        label: '${(block.confidence * 100).toInt()}%',
                        color: _getConfidenceColor(context, block.confidence),
                      ),
                      if (block.language != null)
                        _InfoChip(
                          label: block.language!.toUpperCase(),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      if (block.isLikelyEmail)
                        _InfoChip(
                          label: 'EMAIL',
                          icon: Icons.email_rounded,
                        ),
                      if (block.isLikelyPhone)
                        _InfoChip(
                          label: 'PHONE',
                          icon: Icons.phone_rounded,
                        ),
                      if (block.isLikelyUrl)
                        _InfoChip(
                          label: 'URL',
                          icon: Icons.link_rounded,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              block.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(BuildContext context, double confidence) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (confidence >= 0.8) {
      return isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (confidence >= 0.6) {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    } else {
      return isDark ? Colors.red.shade300 : Colors.red.shade700;
    }
  }
}

/// Small info chip for metadata display
class _InfoChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const _InfoChip({
    required this.label,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ..[
            Icon(icon, size: 12, color: chipColor),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: chipColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
