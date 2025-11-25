# Aves Gallery with OCR - Play Flavor Build

🚀 **Quick-start guide for building the Play flavor APK with OCR features**

## 🎯 Features

This build includes:

- ✨ **ML Kit OCR** (Google Play Services-based)
- 🔍 **Google Lens-style text overlay** 
- 🌐 **Multi-language support** (Latin, Chinese, Devanagari, Japanese, Korean)
- 📝 **Copy, share, search text**
- 📦 **Optimized APK size** (split-per-abi)

## ⚡ Quick Build (3 Steps)

### 1️⃣ Set Up Secrets

Add these to your repository secrets (`Settings` → `Secrets and variables` → `Actions`):

```
KEYSTORE_B64       → Base64 of your .jks keystore file
KEYSTORE_PASSWORD  → Your keystore password
KEY_ALIAS          → Your key alias name
KEY_PASSWORD       → Your key password
GOOGLE_API_KEY     → (optional) Your Google API key
```

**Need a keystore?** See [Creating a Keystore](docs/BUILD_PLAY_APK.md#2-creating-a-keystore-if-you-dont-have-one)

### 2️⃣ Run Build Workflow

1. Go to **Actions** tab
2. Select **"Build Play Flavor Release APK"**
3. Click **"Run workflow"**
   - Branch: `feature/ocr-integration`
   - Version: `1.0.0-ocr` (or any name you want)
4. Click **"Run workflow"** button

### 3️⃣ Download & Install

Wait ~10-15 minutes, then:

1. Click on the completed workflow run
2. Scroll to **Artifacts** section
3. Download the APK for your device:
   - 📱 **arm64-v8a** → Most modern phones (recommended)
   - 📡 **armeabi-v7a** → Older 32-bit devices
   - 🖥️ **x86_64** → Emulators

4. Transfer to your phone and install

## 📚 Full Documentation

For detailed instructions, troubleshooting, and advanced options:

➡️ **[Complete Build Guide](docs/BUILD_PLAY_APK.md)**

## 🔑 Keystore Quick Setup (Termux)

If you don't have a keystore:

```bash
# Install Java
pkg install openjdk-17

# Generate keystore
keytool -genkey -v -keystore ~/aves.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aves-key

# Convert to base64
base64 ~/aves.jks > ~/aves-b64.txt

# Copy contents to GitHub Secret KEYSTORE_B64
cat ~/aves-b64.txt
```

Remember your passwords! You'll need them for the GitHub secrets.

## 🆚️ vs. Libre Flavor

| | Play Flavor | Libre Flavor |
|---|---|---|
| **OCR Engine** | ML Kit (Play Services) | Bundled ML Kit |
| **Requires Play Services** | ✅ Yes | ❌ No |
| **APK Size** | 👍 Smaller (50-60 MB) | 📦 Larger (80-100 MB) |
| **Custom ROMs** | ⚠️ Maybe | ✅ Yes |
| **Offline OCR** | ❌ First use needs internet | ✅ Fully offline |

**Choose Play** if you have Google Play Services (most phones).

**Choose Libre** if you use custom ROMs without Play Services.

## 🤔 Troubleshooting

### Build fails with "KEYSTORE_B64 not set"
➡️ Add the `KEYSTORE_B64` secret (see Step 1)

### "App not installed" on device
➡️ Try the **arm64-v8a** APK (works on 95% of modern phones)

### OCR button doesn't appear
➡️ Only works on images (not videos). Make sure the image is fully loaded.

### "Model download failed"
➡️ Connect to internet for first use. ML Kit downloads language models (~5-8 MB each).

**More help**: See [Troubleshooting Guide](docs/BUILD_PLAY_APK.md#-troubleshooting)

## 🚀 Using OCR

1. Open any image in Aves
2. Tap the **🔍 scan icon**
3. Tap text blocks to select them
4. Use **Copy**, **Share**, or **Search** buttons

## 💬 Support

- 📖 **Full Guide**: [BUILD_PLAY_APK.md](docs/BUILD_PLAY_APK.md)
- 🐛 **Issues**: Open an issue with device info and error logs
- 💻 **Source**: [feature/ocr-integration branch](https://github.com/osphvdhwj/aves/tree/feature/ocr-integration)

## ✨ What's New

Recent updates on this branch:
- ✅ Google Lens-style selectable text overlay
- ✅ Multi-language OCR (5 language families)
- ✅ GitHub Actions automated builds
- ✅ Split-per-ABI for smaller downloads
- ✅ Proper release signing and obfuscation

See [commit history](https://github.com/osphvdhwj/aves/commits/feature/ocr-integration) for details.

---

**Ready?** Head to the **Actions** tab and start your first build! 🎉
