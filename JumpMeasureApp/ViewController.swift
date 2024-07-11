//
//  ViewController.swift
//  JumpMeasureApp
//
//  Created by Jun Ogino on 2024/07/10.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    /// プレビュー表示用のlayer
    private let cameraPreviewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer()
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    let shutterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .red
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2
        button.clipsToBounds = true
        button.layer.cornerRadius = min(button.frame.width, button.frame.height) / 2
        return button
    }()

    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }

    private func configureViews() {
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        view.layer.addSublayer(cameraPreviewLayer)
        view.addSubview(shutterButton)

        // V: |-(>=0)-shutterButton(50)-100-|
        // H: |-(>=0)-shutterButton(50)-(>=0)-|
        NSLayoutConstraint.activate([
            shutterButton.heightAnchor.constraint(equalToConstant: 50),
            shutterButton.widthAnchor.constraint(equalToConstant: 50),
            shutterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        let session = AVCaptureSession()
        cameraPreviewLayer.session = session

        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: .global())
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.connection(with: .video)?.videoOrientation = .portrait
        }
        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureViews()
        cameraPreviewLayer.frame = CGRect(origin: .zero, size: view.bounds.size)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // sampleBufferの処理
    }
}
