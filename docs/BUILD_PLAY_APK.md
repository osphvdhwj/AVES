# Building Play Flavor APK with OCR Features

This guide explains how to build a signed release APK of Aves with OCR integration for the **Play flavor** (uses Google Play Services).

## 🎯 What's Included

The Play flavor APK includes all OCR features:

- ✅ **ML Kit Text Recognition** (via Google Play Services)
- ✅ **Google Lens-style overlay** with selectable text blocks
- ✅ **Multi-language OCR support**:
  - Latin script (English, French, German, Spanish, etc.)
  - Chinese (Simplified & Traditional)
  - Devanagari (Hindi, Sanskrit, etc.)
  - Japanese (Kanji, Hiragana, Katakana)
  - Korean (Hangul)
- ✅ **Text actions**: Copy, Share, Search
- ✅ **Optimized APK size**: Split-per-ABI (separate APK for each architecture)

## 🔑 Prerequisites

### 1. GitHub Secrets Setup

You need to set up the following secrets in your repository:

1. Go to: `Settings` → `Secrets and variables` → `Actions`
2. Click `New repository secret` and add:

| Secret Name | Description | Example |
|------------|-------------|----------|
| `KEYSTORE_B64` | Base64-encoded keystore file | `MIIEpAIBA...` |
| `KEYSTORE_PASSWORD` | Keystore password | `your-store-password` |
| `KEY_ALIAS` | Key alias name | `aves-key` |
| `KEY_PASSWORD` | Key password | `your-key-password` |
| `GOOGLE_API_KEY` | Google API key (optional) | `AIzaSy...` |

### 2. Creating a Keystore (if you don't have one)

#### On Android (Termux):

```bash
# Install Java Development Kit
pkg install openjdk-17

# Generate keystore
keytool -genkey -v \
  -keystore ~/aves-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias aves-key

# You'll be prompted for:
# - Keystore password (remember this!)
# - Key password (remember this!)
# - Your name, organization, etc.

# Convert to base64 for GitHub Secret
base64 ~/aves-release.jks > ~/aves-keystore-b64.txt

# Copy the contents of aves-keystore-b64.txt to KEYSTORE_B64 secret
cat ~/aves-keystore-b64.txt
```

#### On Linux/Mac:

```bash
# Generate keystore
keytool -genkey -v \
  -keystore ./aves-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias aves-key

# Convert to base64
base64 -w 0 ./aves-release.jks > aves-keystore-b64.txt

# Copy contents to GitHub Secret
cat aves-keystore-b64.txt
```

## 🚀 Building the APK

### Method 1: GitHub Actions (Recommended)

1. **Navigate to Actions**:
   - Go to your repository on GitHub
   - Click the `Actions` tab

2. **Run the workflow**:
   - Select `Build Play Flavor Release APK` from the left sidebar
   - Click `Run workflow` button (top right)
   - Choose branch: `feature/ocr-integration`
   - Enter version name (optional): e.g., `1.0.0-ocr` or `ocr-build`
   - Click green `Run workflow` button

3. **Wait for build** (∼10-15 minutes):
   - Watch the workflow progress
   - Green checkmark = success
   - Red X = failed (check logs)

4. **Download APK**:
   - Click on the completed workflow run
   - Scroll down to `Artifacts` section
   - Download the APK for your device architecture:
     - **arm64-v8a** → Most modern Android phones (2015+)
     - **armeabi-v7a** → Older 32-bit ARM devices
     - **x86_64** → Emulators, some tablets

### Method 2: Local Build (Advanced)

#### Requirements:
- Flutter 3.22.1
- Java 17
- Android SDK

#### Steps:

```bash
# 1. Clone your repository
git clone https://github.com/osphvdhwj/aves.git
cd aves
git checkout feature/ocr-integration

# 2. Get dependencies
flutter pub get

# 3. Create key.properties file
cat > android/key.properties << EOF
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=/path/to/your/release.jks
googleApiKey=<NONE>
EOF

# 4. Build APK
flutter build apk \
  --release \
  --flavor play \
  --target lib/main_play.dart \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/outputs/symbols

# 5. APK location
# build/app/outputs/flutter-apk/app-play-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-play-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-play-x86_64-release.apk
```

## 📦 Installing the APK

### On Your Android Device:

1. **Enable Unknown Sources**:
   - Settings → Security → Install unknown apps
   - Enable for your browser or file manager

2. **Transfer APK**:
   - Download from GitHub Actions artifacts
   - Transfer via USB, cloud storage, or direct download

3. **Install**:
   - Tap the APK file
   - Click `Install`
   - Open and grant required permissions

### Choosing the Right APK:

| Device Type | APK to Use | Size (approx) |
|------------|-----------|---------------|
| Modern phones (2015+) | arm64-v8a | ∼50-60 MB |
| Older phones (pre-2015) | armeabi-v7a | ∼45-55 MB |
| Emulators, x86 tablets | x86_64 | ∼55-65 MB |

Not sure? Try **arm64-v8a** first — works on most devices.

## ✨ Using OCR Features

### Activating OCR:

1. Open any image in Aves
2. Tap the **scan icon** (or OCR button) in the viewer
3. Wait for text recognition (∼1-3 seconds)
4. Text blocks appear as overlays on the image

### Working with Text:

- **Tap a text block** to select it (highlighted in blue)
- **Copy**: Tap the copy icon to copy selected text
- **Share**: Share selected text to other apps
- **Search**: Search selected text on the web
- **Select All**: Select all detected text blocks
- **View modes**: Toggle between blocks view and full text view

### First-Time Setup:

**Important**: ML Kit will download language models on first use:
- Latin model: ∼5 MB
- Chinese model: ∼8 MB
- Japanese/Korean models: ∼6-7 MB each

Models are cached and only downloaded once.

## 🔧 Troubleshooting

### Build Failures:

**Error: KEYSTORE_B64 secret not set**
- Solution: Add the keystore secret (see Prerequisites)

**Error: Keystore password incorrect**
- Solution: Verify `KEYSTORE_PASSWORD` and `KEY_PASSWORD` secrets match your keystore

**Error: flutter command not found**
- Solution: Workflow uses Flutter 3.22.1 automatically

### Installation Issues:

**App not installed / Parse error**
- Wrong APK for your device → Try arm64-v8a
- Corrupted download → Re-download APK
- Signature conflict → Uninstall old version first

**"App isn't compatible with your device"**
- You downloaded the wrong architecture APK
- Check device specs: Settings → About phone → Processor

### OCR Issues:

**OCR button doesn't appear**
- Only works on image files (not videos)
- Check if image is fully loaded

**Text not detected**
- Image quality too low → Try a clearer photo
- Text too small or blurry
- Unsupported script → Use supported languages

**"Model download failed"**
- No internet connection → Connect to WiFi/mobile data
- Google Play Services outdated → Update Play Services
- Play Services unavailable (custom ROM) → Use "libre" flavor instead

## 🔍 Comparing Flavors

| Feature | Play Flavor | Libre Flavor |
|---------|------------|-------------|
| **OCR Engine** | ML Kit (Play Services) | Bundled ML Kit |
| **Requires Play Services** | Yes | No |
| **Model Download** | Dynamic (on-demand) | Included in APK |
| **APK Size** | Smaller (∼50-60 MB) | Larger (∼80-100 MB) |
| **Works on Custom ROMs** | Maybe (needs Play Services) | Yes (fully offline) |
| **F-Droid Compatible** | No | Yes |

**Use Play flavor if**:
- ✅ You have Google Play Services
- ✅ You want smaller APK size
- ✅ Internet connection available for first use

**Use Libre flavor if**:
- ✅ Custom ROM without Play Services (LineageOS, GrapheneOS, etc.)
- ✅ Fully offline OCR needed
- ✅ F-Droid distribution

## 📨 Getting Updates

To build a new version with updates:

1. Sync your fork with upstream Aves changes
2. Merge changes into `feature/ocr-integration`
3. Run the `Build Play Flavor Release APK` workflow again
4. Download and install new APK

**Note**: Android will recognize it as an update if:
- Same package name (`deckers.thibault.aves`)
- Same signing key
- Higher version code

## ℹ️ Additional Information

### APK Signing:

All release APKs are:
- ✅ Signed with your release keystore
- ✅ Code obfuscated (R8)
- ✅ Resources shrunk
- ✅ Optimized for production

### Supported Languages:

Full OCR support for:
- **Latin**: English, French, German, Spanish, Portuguese, Italian, Dutch, etc.
- **Chinese**: Simplified 简体字, Traditional 繁體字
- **Devanagari**: हिंदी, मराठी, संस्कृत, नेपाली
- **Japanese**: 漢字, ひらがな, カタカナ
- **Korean**: 한글

### Performance:

- **Text detection**: 1-3 seconds for typical images
- **Memory usage**: +50-80 MB during OCR
- **Battery impact**: Minimal (only when actively scanning)

## 🐛 Reporting Issues

If you encounter problems:

1. Check this troubleshooting guide first
2. Verify your GitHub Secrets are correct
3. Check workflow logs for error messages
4. Open an issue with:
   - Device model and Android version
   - APK architecture used
   - Steps to reproduce
   - Error messages or screenshots

## 🆘 Version History

Check [commit history](https://github.com/osphvdhwj/aves/commits/feature/ocr-integration) for detailed changes.

Key milestones:
- ✅ ML Kit OCR integration
- ✅ Google Lens-style overlay
- ✅ Multi-language support
- ✅ GitHub Actions build automation

---

**Ready to build?** Follow the steps above and enjoy OCR-powered Aves! 🎉
