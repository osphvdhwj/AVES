enum AppFlavor { play, izzy, libre }

extension ExtraAppFlavor on AppFlavor {
  // Current flavor - defaults to play
  static AppFlavor current = AppFlavor.play;

  bool get canEnableErrorReporting {
    switch (this) {
      case AppFlavor.play:
        return true;
      case AppFlavor.izzy:
      case AppFlavor.libre:
        return false;
    }
  }

  bool get hasMapStyleDefault {
    switch (this) {
      case AppFlavor.play:
        return true;
      case AppFlavor.izzy:
      case AppFlavor.libre:
        return false;
    }
  }

  // OCR is supported only in Play flavor (requires Google Play Services)
  bool get supportsOCR {
    switch (this) {
      case AppFlavor.play:
        return true;
      case AppFlavor.izzy:
      case AppFlavor.libre:
        return false;
    }
  }
}
