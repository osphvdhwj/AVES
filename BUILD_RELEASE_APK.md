# 🔐 Building Signed 64-bit Release APK

Complete guide for building production-ready, signed, 64-bit ARM release APK using GitHub Actions.

## ✨ What You Get

- ✅ Small APK size (only arm64-v8a, ~15-25 MB)
- ✅ Production-ready (signed, optimized, obfuscated)
- ✅ WhatsApp/Play Store compatible (64-bit required)
- ✅ Secure (secrets never exposed)
- ✅ Daily use ready (not debug APK)
- ✅ Google Lens-style OCR with text selection

---

## 🛠️ Step 1: Generate Release Keystore

### Using Termux on Android (No PC Required)

#### 1.1 Install Termux

Download from:
- [F-Droid](https://f-droid.org/packages/com.termux/) (recommended)
- [GitHub Releases](https://github.com/termux/termux-app/releases)

#### 1.2 Generate Keystore

Open Termux and run:

```bash
# Install Java
pkg install openjdk-17

# Generate keystore
keytool -genkey -v \
  -keystore my-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias my-key-alias
```

#### 1.3 Follow the Prompts

```
Enter keystore password: [create a password]
Re-enter new password: [same password]
What is your first and last name?
  [CN]: John Doe
What is the name of your organizational unit?
  [OU]: Development
What is the name of your organization?
  [O]: MyCompany
What is the name of your City or Locality?
  [L]: Mumbai
What is the name of your State or Province?
  [ST]: Maharashtra
What is the two-letter country code for this unit?
  [C]: IN
Is CN=John Doe, OU=Development, O=MyCompany, L=Mumbai, ST=Maharashtra, C=IN correct?
  [no]: yes

Enter key password for <my-key-alias>
  (RETURN if same as keystore password): [press Enter]
```

#### 1.4 Save Your Information

**Write these down securely:**
- Keystore password: `____________`
- Key alias: `my-key-alias` (or whatever you chose)
- Key password: `____________` (same as keystore if you pressed Enter)

---

## 🔑 Step 2: Encode Keystore for GitHub

### 2.1 Convert to Base64

**In Termux:**

```bash
# Encode the keystore
base64 my-release-key.jks > my-release-key.jks.b64

# Display the encoded content
cat my-release-key.jks.b64
```

### 2.2 Copy the Output

- You'll see a long string of letters and numbers
- This might be **several lines long**
- **Select and copy ALL of it** (from first character to last)
- This is your `KEYSTORE_B64` value

---

## 🔒 Step 3: Add GitHub Secrets

### 3.1 Navigate to Secrets Settings

1. Go to: https://github.com/osphvdhwj/aves/settings/secrets/actions
2. Or: Repository page > Settings > Secrets and variables > Actions

### 3.2 Add Four Secrets

Click **"New repository secret"** four times to create:

#### Secret 1: KEYSTORE_B64
```
Name: KEYSTORE_B64
Secret: [paste the entire base64 output from Step 2]
```

#### Secret 2: KEYSTORE_PASSWORD
```
Name: KEYSTORE_PASSWORD
Secret: [your keystore password from Step 1]
```

#### Secret 3: KEY_ALIAS
```
Name: KEY_ALIAS
Secret: my-key-alias
[or whatever alias you used in Step 1]
```

#### Secret 4: KEY_PASSWORD
```
Name: KEY_PASSWORD
Secret: [your key password, usually same as keystore password]
```

### 3.3 Verify

You should now see **4 secrets** listed:
- KEYSTORE_B64
- KEYSTORE_PASSWORD
- KEY_ALIAS  
- KEY_PASSWORD

⚠️ **Values will be hidden** - this is normal for security!

---

## 🚀 Step 4: Build Your APK

### 4.1 Trigger the Workflow

1. Go to **Actions** tab: https://github.com/osphvdhwj/aves/actions

2. In the left sidebar, click: **"Build 64-bit Release APK (Signed)"**

3. Click the **"Run workflow"** dropdown button (top right)

4. Ensure branch is: `feature/ocr-integration`

5. Click green **"Run workflow"** button

### 4.2 Monitor Progress

- Build will start automatically
- Click on the workflow run to see live progress
- Build typically takes **5-10 minutes**
- You'll see green checkmarks as each step completes

### 4.3 Download APK

1. Wait for **green checkmark** next to "Build ARM64 Release APK"

2. Scroll to **"Artifacts"** section (bottom of the page)

3. Click **"aves-ocr-arm64-release"** to download

4. Extract the downloaded ZIP file

5. Inside you'll find: **`aves-ocr-arm64-v8a-release.apk`**

---

## 📱 Step 5: Install on Your Device

### 5.1 Transfer APK

**Options:**
- USB cable
- Cloud storage (Google Drive, Dropbox)
- Email to yourself
- Bluetooth

### 5.2 Install

1. On your Android device, open the APK file
2. Android may show: **"For your security, your phone is not allowed to install unknown apps from this source"**
3. Tap **Settings**
4. Enable **"Allow from this source"**
5. Go back and tap **Install**
6. Tap **Open** when installation completes

### 5.3 First Launch

- Grant storage permissions when prompted
- Your photos will appear in the gallery
- Everything works exactly like the original Aves!

---

## 🎯 Using OCR Features

### Quick Start

1. Open any image in the viewer
2. **Long press** anywhere on the image
3. Wait 2-3 seconds for text extraction
4. Google Lens-style overlay appears!

### Text Selection

- **Tap any text block** to select it (turns blue)
- **Tap again** to deselect
- **"Select All"** button (top) selects everything
- **"Clear"** button deselects everything

### Actions

When text is selected:
- 📋 **Copy** - Copy to clipboard
- 🔗 **Share** - Share to other apps
- 🔍 **Search** - Search on Google

### View Modes

- **Block View** (default) - Text blocks over image
- **Full Text View** - Toggle with 📊 icon (top-right)
  - Scrollable full text
  - Native text selection
  - Easy to read long documents

---

## 🔄 Rebuilding After Changes

### When Code Changes

The workflow automatically triggers when you push changes to:
- `lib/**` (Dart code)
- `android/**` (Android code)
- `pubspec.yaml` (dependencies)

### Manual Trigger

You can also manually trigger from Actions tab anytime.

---

## ❓ Troubleshooting

### Build Errors

**Error: "Keystore file not found"**
- Check that all 4 secrets are added
- Verify KEYSTORE_B64 is complete (no truncation)
- Re-copy base64 content carefully

**Error: "Wrong password"**
- Verify passwords in secrets match what you used in keytool
- Check for typos
- Passwords are case-sensitive

**Error: "Invalid keystore format"**
- Regenerate base64: `base64 my-release-key.jks`
- Ensure you used `base64`, not other encoding
- Check file wasn't corrupted during transfer

### Installation Errors

**"App not installed"**
- Uninstall any previous debug version first
- Ensure device is 64-bit (check: Settings > About > CPU)
- Free up storage space if needed

**"Parse error"**
- APK file might be corrupted during download
- Re-download from GitHub Artifacts
- Verify file size matches (should be ~15-25 MB)

### OCR Not Working

**"No text found"**
- Image must have clear, readable text
- Ensure good lighting and contrast
- Try with a clearer image first

**Long press doesn't work**
- Ensure you're in the image viewer (not gallery view)
- Press and hold for ~1 second
- Don't move finger while holding

---

## 📚 Additional Resources

- [Flutter Release Build Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

## 📝 Quick Reference

### Your Keystore Info (Fill This In)

```
Keystore file: my-release-key.jks
Keystore password: _______________
Key alias: my-key-alias
Key password: _______________
Created: [date]
Valid until: [date + 10,000 days]
```

### GitHub Secrets Checklist

- [ ] KEYSTORE_B64 (base64 content)
- [ ] KEYSTORE_PASSWORD (your password)
- [ ] KEY_ALIAS (my-key-alias)
- [ ] KEY_PASSWORD (your password)

### Build Checklist

- [ ] Secrets added to GitHub
- [ ] Workflow file exists (.github/workflows/build-arm64-release.yml)
- [ ] Branch pushed to GitHub
- [ ] Workflow triggered
- [ ] Build completed successfully
- [ ] APK downloaded
- [ ] APK installed on device
- [ ] OCR tested and working

---

**🎉 Congratulations! You now have a secure, repeatable process for building production-ready APKs with cutting-edge OCR features!**
