import 'package:aves/model/entry/entry.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Notification to trigger OCR processing
class TriggerOCRNotification extends Notification {
  final AvesEntry entry;
  final Offset position;

  const TriggerOCRNotification({
    required this.entry,
    required this.position,
  });
}

/// Notification when OCR is complete
class OCRCompleteNotification extends Notification {
  final AvesEntry entry;
  final RecognizedText? result;
  final String? error;

  const OCRCompleteNotification({
    required this.entry,
    this.result,
    this.error,
  });

  bool get hasError => error != null;
  bool get hasResult => result != null && result!.text.isNotEmpty;
}

/// Notification to show/hide OCR overlay
class ToggleOCROverlayNotification extends Notification {
  final bool visible;

  const ToggleOCROverlayNotification(this.visible);
}

/// Notification when OCR mode is activated
class OCRModeActivatedNotification extends Notification {
  final bool active;

  const OCRModeActivatedNotification(this.active);
}
