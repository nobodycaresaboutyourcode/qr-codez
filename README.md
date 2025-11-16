# qr-codez

An iOS app for quickly generating round QR codes from URLs, scanning QR codes with the camera, and copying/sharing the resulting images and text.

## Features

- **Generate QR from URL**
  - Enter any URL and tap `Generate QR`.
  - The app renders a **rounded** QR code preview.

- **Open URL**
  - Tap `Open URL` to open the current URL in the system browser (Safari).

- **Save / Share QR**
  - `Share / Save QR` opens the iOS share sheet so you can:
    - Save the QR image to Photos.
    - Share via Messages, Mail, AirDrop, etc.

- **Copy QR Image**
  - Copies the generated QR image to the clipboard so you can paste it into other apps.

- **Scan QR Codes**
  - Tap `Scan QR Code` to open a camera-based scanner.
  - Uses native `AVCaptureSession` / `AVCaptureMetadataOutput` to detect QR codes.
  - Decoded content (especially URLs) is displayed as text on the main screen.

- **Copy Scanned Text**
  - Tap `Copy Scanned Text` to copy the most recently scanned QR content to the clipboard.

The app **never automatically acts** on scanned QR content. If the scanned text is a URL, it is shown as plain text so you can manually open or paste it elsewhere.

## Requirements

- macOS with Xcode installed.
- iOS Simulator or a physical iOS device.
- Camera access is required to use the scan feature (on device).

## Project Layout

- `qr-codez.xcodeproj` – Xcode project file.
- `qr-codez/` – App sources and resources.
  - `AppDelegate.swift`, `SceneDelegate.swift` – Standard UIKit app wiring.
  - `ViewController.swift` – Main UI for generating, displaying, sharing, copying, and scanning QR codes.
  - `Assets.xcassets/AppIcon.appiconset` – App icon catalog.
- `icon-source.svg` – Source artwork for the app icon.

## Running the App

1. Open `qr-codez.xcodeproj` in Xcode.
2. Select the `qr-codez` scheme.
3. Choose a target device or iOS Simulator.
4. Press **Run**.

On first use of the scan feature, iOS will prompt for camera access.

## Using the Icon

This repo includes a vector icon source file:

- `icon-source.svg` – 1024×1024 SVG with a rounded-square background and stylized QR motif.

To use it as the app icon:

1. Export a **1024×1024** PNG from `icon-source.svg` using a tool like Preview, Sketch, Figma, or any vector editor.
2. In Xcode, open `Assets.xcassets` → `AppIcon`.
3. Drag the 1024×1024 PNG into the required 1024×1024 slot(s) in `AppIcon.appiconset`.
4. Clean and rebuild the project if needed.

On modern Xcode versions, a single 1024×1024 universal icon is enough; Xcode will derive sizes for targets that support it.

## Notes

- QR generation uses `CIQRCodeGenerator` with a higher error correction level (`Q`).
- Scanning uses the system camera via `AVCaptureSession` and only reads QR metadata; no additional processing or network calls are performed.
