import 'dart:ui' as ui;

import 'package:aves/model/entry/entry.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';

class OCROverlay extends StatefulWidget {
  final AvesEntry entry;
  final RecognizedText recognizedText;
  final VoidCallback onClose;
  final Animation<double> animation;

  const OCROverlay({
    super.key,
    required this.entry,
    required this.recognizedText,
    required this.onClose,
    required this.animation,
  });

  @override
  State<OCROverlay> createState() => _OCROverlayState();
}

class _OCROverlayState extends State<OCROverlay> {
  final Set<TextElement> _selectedElements = {};
  bool _showingAllText = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.animation.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dimmed background with blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onClose,
                tooltip: 'Close OCR',
              ),
            ),

            // Mode toggle
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  _showingAllText ? Icons.grid_view : Icons.text_fields,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showingAllText = !_showingAllText),
                tooltip: _showingAllText ? 'Show blocks' : 'Show all text',
              ),
            ),

            // Text content
            if (_showingAllText)
              _buildFullTextView()
            else
              _buildTextBlocksView(),

            // Action toolbar
            _buildActionToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBlocksView() {
    return Positioned.fill(
      child: InteractiveViewer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                ...widget.recognizedText.blocks.expand((block) {
                  return block.lines.expand((line) {
                    return line.elements.map((element) {
                      final isSelected = _selectedElements.contains(element);
                      return Positioned(
                        left: element.boundingBox.left.toDouble(),
                        top: element.boundingBox.top.toDouble(),
                        child: GestureDetector(
                          onTap: () => _toggleElement(element),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.5)
                                  : Colors.yellow.withOpacity(0.3),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.yellow,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              element.text,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: element.boundingBox.height * 0.7,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  });
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFullTextView() {
    final fullText = widget.recognizedText.text;
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.of(context).padding.top + 80,
      bottom: 120,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            fullText,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionToolbar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.select_all,
                label: 'Select All',
                onPressed: _selectAll,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.copy,
                label: 'Copy',
                onPressed: _copyText,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: _shareText,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.search,
                label: 'Search',
                onPressed: _searchText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 24, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  void _toggleElement(TextElement element) {
    setState(() {
      if (_selectedElements.contains(element)) {
        _selectedElements.remove(element);
      } else {
        _selectedElements.add(element);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedElements.clear();
      for (final block in widget.recognizedText.blocks) {
        for (final line in block.lines) {
          _selectedElements.addAll(line.elements);
        }
      }
    });
  }

  void _copyText() async {
    final text = _getSelectedText();
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${text.length} characters copied'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareText() async {
    final text = _getSelectedText();
    if (text.isEmpty) return;

    // Use share functionality
    // Note: You'll need to add share_plus package or use platform channels
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied. Share functionality requires share_plus package.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _searchText() async {
    final text = _getSelectedText();
    if (text.isEmpty) return;

    // Open web search or internal search
    final uri = Uri.https('www.google.com', '/search', {'q': text});
    // Use url_launcher
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Search query copied: ${text.length > 50 ? text.substring(0, 50) + '...' : text}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getSelectedText() {
    if (_showingAllText) {
      return widget.recognizedText.text;
    } else if (_selectedElements.isEmpty) {
      return widget.recognizedText.text;
    } else {
      return _selectedElements.map((e) => e.text).join(' ');
    }
  }
}
