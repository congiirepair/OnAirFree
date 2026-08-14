# OnAirFree — iOS port (no login)

A native **Swift + SwiftUI + CoreBluetooth** rebuild of the MyOnair air-suspension
app, with **no login/account gate** — free for anyone with the hardware.

> **Why this is a rebuild, not a conversion.** Your original app is native Android.
> An iOS app can't be extracted from an APK — it has to be written in Swift against
> Apple's frameworks. The hard part (the exact Bluetooth protocol) was recovered
> from your APK and is reproduced here byte-for-byte, so this speaks to your
> controller identically to the Android app.

---

## What's implemented

| Area | Status |
|------|--------|
| First-run **model picker** (Model 3 / Y / XPeng P7), no login | ✅ |
| **Scan** for devices named "OnAir", connect | ✅ |
| Standard **FFE0/FFE1** UART **and** custom-service fallback | ✅ |
| Notifications + **frame reassembly** (0D 0A terminated) | ✅ |
| Ride height **Low / OnAir / High** | ✅ |
| Manual **wheel up/down** (front / rear / all) — press & hold | ✅ |
| **All Down** — hold-to-activate (3 s safety) | ✅ |
| **Auto** on/off | ✅ |
| **Save memory** M1 / M2 / M3 | ✅ |
| Live **status**: height, tank pressure, speed, warnings | ✅ |
| Full command set incl. secondary `AA…EE` frames | ✅ (in `OnAirCommands.swift`) |

The protocol layer is a faithful port of your recovered `CommandConstant.java`
and `UtilsViewStatus.java`. Every byte-level detail (bit positions, end-indexed
parsing, pressure special-case) matches the Android source.

## Source layout

```
Sources/
  OnAirFreeApp.swift          app entry
  Protocol/OnAirCommands.swift  all command frames + hex<->Data
  Models/SuspensionState.swift  observable state + FrameParser (status decode)
  BLE/BLEManager.swift          CoreBluetooth: scan/connect/notify/write
  Views/RootView.swift          routing (model picker → scan → controller)
  Views/ModelPickerView.swift   first-run model choice
  Views/ScanView.swift          device list
  Views/ControllerView.swift    main controls
  Views/HoldButton.swift        press-and-hold / timed-hold button
project.yml                     XcodeGen project spec
```

---

## Building it — you need a Mac (or a cloud Mac)

Apple only allows compiling iOS apps on macOS with Xcode. Three options:

### A. On a Mac (easiest)
```bash
brew install xcodegen        # one time
cd ios-OnAirFree
xcodegen generate            # creates OnAirFree.xcodeproj
open OnAirFree.xcodeproj
```
Then in Xcode: select your device, set your **Signing Team** (free Apple ID works
for personal install), and press **Run**.

### B. No Mac — rent one in the cloud
- **MacStadium**, **MacinCloud**, or an **AWS EC2 mac** instance: remote into
  macOS, install Xcode, follow option A.

### C. No Mac — build in CI (produces an installable build without you owning a Mac)
- **Codemagic** or **GitHub Actions** (`macos-latest` runner) can run `xcodegen`
  + `xcodebuild` and output the app. For a real signed `.ipa` you still need an
  **Apple Developer account** ($99/yr) and signing certificates configured in the
  CI. This is the standard path to TestFlight / App Store.

### Manual Xcode project (if you skip XcodeGen)
Create a new **iOS App** (SwiftUI, name `OnAirFree`), delete its starter files,
drag in everything under `Sources/`, and add these to the target's Info settings:
- `NSBluetoothAlwaysUsageDescription` = "OnAir uses Bluetooth to connect to your air-suspension controller."
- `NSBluetoothPeripheralUsageDescription` = same string
Deployment target **iOS 17+**.

---

## Distributing it free on iOS

Unlike Android (where anyone can install your APK), iOS is locked down:

- **App Store** (recommended for "free to the public"): needs an Apple Developer
  account; Apple reviews the app. Free to download once published.
- **TestFlight**: up to 10,000 public testers via a link; also needs the dev
  account; builds expire every 90 days.
- **AltStore / sideloading**: users install it themselves, but a free Apple ID
  build must be re-signed every 7 days — not practical for the public.

So for genuine free public distribution, an **Apple Developer account + App Store**
is the realistic route.

---

## ⚠️ Test before you trust it

This controls real hardware on a real car. The protocol is faithfully ported, but
**it has not been run against a physical controller yet.** Before relying on it or
sharing it: connect to your own vehicle, verify each control does exactly what the
Android app does, and confirm the status readouts (height, pressure, warnings)
match. Treat the first on-car run as a test, with the car safely supported.
