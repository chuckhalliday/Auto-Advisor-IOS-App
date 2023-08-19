//
//  Scanner.swift
//  Auto Advisor
//
//  Created by Charles Clark on 3/29/23.
//

import SwiftUI
import AVFoundation

struct VINScannerView: UIViewControllerRepresentable {
    @Binding var scannedVIN: String
    @Binding var isShowingScanner: Bool
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<VINScannerView>) -> ScannerViewController {
        return ScannerViewController(scannedVIN: $scannedVIN, isShowingScanner: $isShowingScanner)
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: UIViewControllerRepresentableContext<VINScannerView>) {}

    class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var scannedVIN: String
        @Binding var isShowingScanner: Bool
        
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!

        init(scannedVIN: Binding<String>, isShowingScanner: Binding<Bool>) {
            _scannedVIN = scannedVIN
            _isShowingScanner = isShowingScanner
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = UIColor.black
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }

            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                failed()
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.code39, .code128, .ean8, .ean13, .pdf417, .qr, .upce]
            } else {
                failed()
                return
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            captureSession.startRunning()
        }

        func failed() {
            let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            captureSession = nil
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            if (captureSession?.isRunning == false) {
                captureSession.startRunning()
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            if (captureSession?.isRunning == true) {
                captureSession.stopRunning()
            }
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            captureSession.stopRunning()

            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }

                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                scannedVIN = stringValue
            }

            dismiss(animated: true)
        }
    }
}
