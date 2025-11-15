import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/ocr_provider.dart';

class OCRViewScreen extends StatefulWidget {
  final String? initialImagePath;

  const OCRViewScreen({Key? key, this.initialImagePath}) : super(key: key);

  @override
  State<OCRViewScreen> createState() => _OCRViewScreenState();
}

class _OCRViewScreenState extends State<OCRViewScreen> {
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _selectedImage = File(widget.initialImagePath!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performOCR(_selectedImage!);
      });
    }
  }

  Future<void> _performOCR(File imageFile) async {
    await context.read<OCRProvider>().extractTextFromImage(imageFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extract Text'),
        elevation: 0,
      ),
      body: Consumer<OCRProvider>(
        builder: (context, ocrProvider, _) {
          if (ocrProvider.isProcessing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ocrProvider.error != null) {
            return Center(child: Text('Error: {ocrProvider.error}'));
          }

          if (ocrProvider.currentResult == null) {
            return const Center(child: Text('No text found'));
          }

          return _buildResultView(ocrProvider.currentResult!.fullText);
        },
      ),
    );
  }

  Widget _buildResultView(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: text),
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            icon: const Icon(Icons.content_copy),
            label: const Text('Copy All'),
          ),
        ],
      ),
    );
  }
}
