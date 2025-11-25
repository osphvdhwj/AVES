import 'dart:ui' as ui;
import 'package:aves/model/entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';

class OCRLensOverlay extends StatefulWidget {
  final AvesEntry entry;
  final RecognizedText recognizedText;
  final VoidCallback onClose;
  final Animation<double> animation;

  const OCRLensOverlay({
    super.key,
    required this.entry,
    required this.recognizedText,
    required this.onClose,
    required this.animation,
  });

  @override
  State<OCRLensOverlay> createState() => _OCRLensOverlayState();
}

class _OCRLensOverlayState extends State<OCRLensOverlay> {
  final Set<int> _selectedBlockIndices = {};
  bool _showAllText = false;

  String get _selectedText {
    if (_selectedBlockIndices.isEmpty) return '';
    
    final selectedBlocks = widget.recognizedText.blocks
        .asMap()
        .entries
        .where((entry) => _selectedBlockIndices.contains(entry.key))
        .map((entry) => entry.value.text)
        .toList();
    
    return selectedBlocks.join(' ');
  }

  String get _allText => widget.recognizedText.text;

  void _toggleBlock(int index) {
    setState(() {
      if (_selectedBlockIndices.contains(index)) {
        _selectedBlockIndices.remove(index);
      } else {
        _selectedBlockIndices.add(index);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedBlockIndices.clear();
      for (int i = 0; i < widget.recognizedText.blocks.length; i++) {
        _selectedBlockIndices.add(i);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedBlockIndices.clear();
      _showAllText = false;
    });
  }

  Future<void> _copyText() async {
    final text = _showAllText ? _allText : _selectedText;
    if (text.isEmpty) return;
    
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareText() async {
    final text = _showAllText ? _allText : _selectedText;
    if (text.isEmpty) return;
    
    await Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.animation,
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Stack(
            children: [
              // Close gesture detector
              Positioned.fill(
                child: GestureDetector(
                  onTap: _selectedBlockIndices.isEmpty && !_showAllText 
                      ? widget.onClose 
                      : _clearSelection,
                  child: Container(color: Colors.transparent),
                ),
              ),
              
              // Text blocks overlay
              if (!_showAllText) ..._buildTextBlocksOverlay(),
              
              // Top toolbar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopToolbar(),
              ),
              
              // Bottom action bar
              if (_selectedBlockIndices.isNotEmpty || _showAllText)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildActionBar(),
                ),
              
              // All text view
              if (_showAllText) _buildAllTextView(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTextBlocksOverlay() {
    return widget.recognizedText.blocks.asMap().entries.map((entry) {
      final index = entry.key;
      final block = entry.value;
      final isSelected = _selectedBlockIndices.contains(index);
      
      return Positioned(
        left: block.boundingBox.left.toDouble(),
        top: block.boundingBox.top.toDouble(),
        width: block.boundingBox.width.toDouble(),
        height: block.boundingBox.height.toDouble(),
        child: GestureDetector(
          onTap: () => _toggleBlock(index),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              border: Border.all(
                color: isSelected 
                    ? Colors.blue 
                    : Colors.white.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(4),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text(
                block.text,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTopToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
            tooltip: 'Close',
          ),
          const Spacer(),
          if (!_showAllText && _selectedBlockIndices.isEmpty)
            TextButton.icon(
              onPressed: _selectAll,
              icon: const Icon(Icons.select_all, color: Colors.white, size: 20),
              label: const Text('Select All', style: TextStyle(color: Colors.white)),
            ),
          if (_selectedBlockIndices.isNotEmpty || _showAllText)
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear, color: Colors.white, size: 20),
              label: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: Icon(
              _showAllText ? Icons.grid_view : Icons.view_headline,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showAllText = !_showAllText;
                if (_showAllText) {
                  _selectedBlockIndices.clear();
                }
              });
            },
            tooltip: _showAllText ? 'Show blocks' : 'Show all text',
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    final textToShow = _showAllText ? _allText : _selectedText;
    final blockCount = _selectedBlockIndices.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_showAllText && blockCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$blockCount ${blockCount == 1 ? 'block' : 'blocks'} selected',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.copy,
                label: 'Copy',
                onPressed: _copyText,
              ),
              _ActionButton(
                icon: Icons.share,
                label: 'Share',
                onPressed: _shareText,
              ),
              _ActionButton(
                icon: Icons.search,
                label: 'Search',
                onPressed: () {
                  // Implement web search
                  final searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(textToShow)}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Search: $searchUrl')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllTextView() {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 56), // Space for toolbar
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _allText,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80), // Space for action bar
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, size: 28),
          onPressed: onPressed,
          color: Colors.blue,
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
