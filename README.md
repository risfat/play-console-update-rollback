# Android AAB Rollback / Version Patcher (PowerShell)

This PowerShell script allows you to **patch an Android App Bundle (AAB)** file with a new `versionCode` and `versionName`, then re-sign and align it with your existing keystore.
It’s useful for **rollback builds, hotfix releases, or reusing an existing AAB with updated version info**.

---

## ✨ Features

* 🔍 Reads signing configuration automatically from `key.properties`
* 📦 Unpacks an AAB and patches `AndroidManifest.xml`
* 🧹 Removes old signatures from `META-INF`
* 🗜 Rebuilds and aligns the AAB with `zipalign`
* 🔑 Re-signs the AAB using `jarsigner`
* ✅ Outputs a fresh, signed, aligned `.aab` ready for upload to Play Console

---

## 🚀 Usage

```powershell
.\Rollback-Aab.ps1 -InputAab "app-release.aab" -OutputAab "rollback.aab" -VersionCode "122" -VersionName "1.0.8"
```

### Parameters

* **`-InputAab`**: Path to the input AAB file (default: `app-release.aab`)
* **`-OutputAab`**: Name of the output AAB file (default: `rollback.aab`)
* **`-VersionCode`**: New version code to set in `AndroidManifest.xml`
* **`-VersionName`**: New version name to set in `AndroidManifest.xml`

---

## 🔑 Keystore Setup

The script expects a `key.properties` file in the same directory, with contents like:

```properties
storeFile=my-release-key.jks
storePassword=your-store-password
keyAlias=your-key-alias
keyPassword=your-key-password
```

---

## ⚙️ Requirements

Make sure the following tools are installed and available in your **PATH**:

* **Java** (`java`)
* **Jarsigner** (`jarsigner`) – usually comes with the JDK
* **Zipalign** (`zipalign`) – part of Android SDK Build Tools

---

## 📂 Output

After running the script, you’ll get:

* **`aligned-rollback.aab`** (signed and ready for Play Console upload)

---

## ⚠️ Notes

* This script only supports **XML manifests** (`AndroidManifest.xml`).
  If your AAB uses a **proto manifest** (`AndroidManifest.xml.pb`), patching is not supported out of the box.
* Tested on **Windows PowerShell**. Should work in PowerShell 7+, but not tested on Linux/macOS.

---

## 📝 License

MIT License – feel free to use and adapt.

