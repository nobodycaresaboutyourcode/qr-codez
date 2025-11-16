//
//  ViewController.swift
//  qr-codez
//
//  Created by Jed Deaver on 11/15/25.
//

import UIKit
import CoreImage
import AVFoundation

class ViewController: UIViewController {

    private let urlTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter URL (https://...)"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .URL
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        return textField
    }()

    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Generate QR", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return button
    }()

    private let openURLButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Open URL", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return button
    }()

    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share / Save QR", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return button
    }()

    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy QR Image", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return button
    }()

    private let scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scan QR Code", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return button
    }()

    private let scannedResultLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.text = "Scanned result will appear here."
        return label
    }()

    private let copyScannedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy Scanned Text", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return button
    }()

    private let qrImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.systemGray6
        return imageView
    }()

    private let context = CIContext()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupLayout()

        generateButton.addTarget(self, action: #selector(didTapGenerate), for: .touchUpInside)
        openURLButton.addTarget(self, action: #selector(didTapOpenURL), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(didTapCopy), for: .touchUpInside)
        scanButton.addTarget(self, action: #selector(didTapScan), for: .touchUpInside)
        copyScannedButton.addTarget(self, action: #selector(didTapCopyScanned), for: .touchUpInside)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let side = min(qrImageView.bounds.width, qrImageView.bounds.height)
        qrImageView.layer.cornerRadius = side / 2.0
    }

    private func setupLayout() {
        let buttonRow = UIStackView(arrangedSubviews: [openURLButton, shareButton, copyButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 12

        let scannedRow = UIStackView(arrangedSubviews: [scannedResultLabel, copyScannedButton])
        scannedRow.axis = .horizontal
        scannedRow.alignment = .top
        scannedRow.spacing = 8

        let stackView = UIStackView(arrangedSubviews: [urlTextField, generateButton, buttonRow, qrImageView, scanButton, scannedRow])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill

        stackView.translatesAutoresizingMaskIntoConstraints = false
        qrImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            qrImageView.heightAnchor.constraint(equalTo: qrImageView.widthAnchor),
            qrImageView.heightAnchor.constraint(equalToConstant: 260)
        ])
    }

    @objc
    private func didTapGenerate() {
        guard let text = urlTextField.text, !text.isEmpty else {
            qrImageView.image = nil
            return
        }

        guard let url = URL(string: text), !url.absoluteString.isEmpty else {
            qrImageView.image = nil
            return
        }

        qrImageView.image = generateQRCode(from: url.absoluteString)
    }

    @objc
    private func didTapOpenURL() {
        guard let text = urlTextField.text, let url = URL(string: text) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @objc
    private func didTapShare() {
        guard let image = qrImageView.image else {
            return
        }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        present(activityVC, animated: true, completion: nil)
    }

    @objc
    private func didTapCopy() {
        guard let image = qrImageView.image else {
            return
        }

        UIPasteboard.general.image = image
    }

    @objc
    private func didTapScan() {
        let scanner = QRScannerViewController()
        scanner.onCodeScanned = { [weak self] code in
            DispatchQueue.main.async {
                self?.scannedResultLabel.text = code
            }
        }
        present(scanner, animated: true, completion: nil)
    }

    @objc
    private func didTapCopyScanned() {
        guard let text = scannedResultLabel.text, !text.isEmpty else {
            return
        }
        UIPasteboard.general.string = text
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let scaleX: CGFloat = 10.0
        let scaleY: CGFloat = 10.0
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var onCodeScanned: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func configureSession() {
        guard let videoDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            return
        }
        session.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        session.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let stringValue = object.stringValue else {
            return
        }

        session.stopRunning()
        onCodeScanned?(stringValue)
        dismiss(animated: true, completion: nil)
    }
}
