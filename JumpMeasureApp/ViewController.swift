//
//  ViewController.swift
//  JumpMeasureApp
//
//  Created by Jun Ogino on 2024/07/10.
//

import UIKit
import AVFoundation
import Combine

class ViewController: UIViewController {
    private let backTelephotoCameraPreviewLayer = AVCaptureVideoPreviewLayer()
    private let backCameraPreviewLayer = AVCaptureVideoPreviewLayer()
    private let backUltraWideCameraPreviewLayer = AVCaptureVideoPreviewLayer()
    private let back = AVCaptureVideoPreviewLayer()
    /// 複数カメラ用のセッション
    private var multiCamSession: AVCaptureMultiCamSession?

    private var telephotoCameraInput: AVCaptureDeviceInput?
    private var wideCameraInput: AVCaptureDeviceInput?
    private var ultraWideCameraInput: AVCaptureDeviceInput?

    private let cameraPreviewView = UIView()

    let shutterButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        return button
    }()
    let shutterButtonSize = CGFloat(80)

    let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 10
        return view
    }()

    enum CameraMode {
        case teleWide
        case wideUltraWide
    }

    @Published var cameraMode: CameraMode = .teleWide
    private lazy var teleWideButton: UIButton = makeButton(title: "Telephoto / Wide")
    private lazy var wideUltraWideButton: UIButton = makeButton(title: "Wide / UltraWide")

    func makeButton(title: String) -> UIButton {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor(hex: "E34234")
        config.background.backgroundInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)

        config.contentInsets = .init(top: 12, leading: 20, bottom: 12, trailing: 20)
        config.cornerStyle = .capsule
        button.configuration = config
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }

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

    private func removeAllInputs(from session: AVCaptureMultiCamSession) {
        for input in session.inputs {
            session.removeInput(input)
        }
    }

    private func configureViews() {
        [cameraPreviewView, shutterButton, stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        stackView.addArrangedSubview(teleWideButton)
        stackView.addArrangedSubview(wideUltraWideButton)
        shutterButton.layer.masksToBounds = true
        shutterButton.layer.cornerRadius = shutterButtonSize / 2
        
        // teleWideButton config
        teleWideButton.isHidden = true
        teleWideButton.addAction(.init { [weak self] _ in
            self?.cameraMode = .teleWide
        }, for: .touchUpInside)

        //wideUltraWideButton config
        wideUltraWideButton.isHidden = true
        wideUltraWideButton.addAction(.init { [weak self] _ in
            self?.cameraMode = .wideUltraWide
        }, for: .touchUpInside)

        // V: |[cameraPreviewView]|
        // H: |[cameraPreviewView]|
        NSLayoutConstraint.activate([
            cameraPreviewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraPreviewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraPreviewView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraPreviewView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // V: |-(>=0)-shutterButton(50)-100-|
        // H: |-(>=0)-shutterButton(50)-(>=0)-|
        NSLayoutConstraint.activate([
            shutterButton.heightAnchor.constraint(equalToConstant: shutterButtonSize),
            shutterButton.widthAnchor.constraint(equalToConstant: shutterButtonSize),
            shutterButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            shutterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -80),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50)
        ])
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        teleWideButton.layer.cornerRadius = teleWideButton.frame.height / 2
        wideUltraWideButton.layer.cornerRadius = wideUltraWideButton.frame.height / 2
    }

    private var cancellables: [AnyCancellable] = []

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTelephotoCameraSession() {
        multiCamSession = AVCaptureMultiCamSession()
        // |[backCameraPreviewLayer][backTelephotoCameraPreviewLayer]|
        
        guard let multiCamSession else { return }
        if multiCamSession.isRunning {
            multiCamSession.stopRunning()
        }
        // multiCamSessionからinputがあればremoveする
        removeAllInputs(from: multiCamSession)

        guard let telephotoCameraInput,
              let wideCameraInput else { return }

        if multiCamSession.canAddInput(telephotoCameraInput) {
            print("session追加可能！")
        }

        // Setting for wideCamera
        multiCamSession.addInput(wideCameraInput)
        backCameraPreviewLayer.session = multiCamSession
        backCameraPreviewLayer.connection?.videoRotationAngle = 0
        backCameraPreviewLayer.videoGravity = .resizeAspectFill
        backCameraPreviewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: cameraPreviewView.bounds.width / 2,
            height: cameraPreviewView.bounds.height
        )

        // Setting for telephotoCamera
        multiCamSession.addInput(telephotoCameraInput)
        backTelephotoCameraPreviewLayer.session = multiCamSession
        backTelephotoCameraPreviewLayer.connection?.videoRotationAngle = 0
        backTelephotoCameraPreviewLayer.videoGravity = .resizeAspectFill
        backTelephotoCameraPreviewLayer.frame = CGRect(
            x: cameraPreviewView.bounds.width / 2,
            y: 0,
            width: cameraPreviewView.bounds.width / 2,
            height: cameraPreviewView.bounds.height
        )
        cameraPreviewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        // addSublayer
        cameraPreviewView.layer.addSublayer(backTelephotoCameraPreviewLayer)
        cameraPreviewView.layer.addSublayer(backCameraPreviewLayer)
    }

    private func configureUltraWideCameraSession() {
        multiCamSession = AVCaptureMultiCamSession()
        // |[backCameraPreviewLayer][backUltraWideCameraPreviewLayer]|

        guard let multiCamSession else { return }
        if multiCamSession.isRunning {
            multiCamSession.stopRunning()
        }
        // multiCamSessionからinputがあればremoveする
        removeAllInputs(from: multiCamSession)

        guard let ultraWideCameraInput,
              let wideCameraInput else { return }

        // Setting for wideCamera
        if multiCamSession.canAddInput(wideCameraInput) {
            multiCamSession.addInput(wideCameraInput)
        }
        backCameraPreviewLayer.session = multiCamSession
        backCameraPreviewLayer.connection?.videoRotationAngle = 0
        backCameraPreviewLayer.videoGravity = .resizeAspectFill
        backCameraPreviewLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: cameraPreviewView.bounds.width / 2,
            height: cameraPreviewView.bounds.height
        )

        // Setting for ultraWideCamera
        if multiCamSession.canAddInput(ultraWideCameraInput) {
            multiCamSession.addInput(ultraWideCameraInput)
        }
        backUltraWideCameraPreviewLayer.session = multiCamSession
        backUltraWideCameraPreviewLayer.connection?.videoRotationAngle = 0
        backUltraWideCameraPreviewLayer.videoGravity = .resizeAspectFill
        backUltraWideCameraPreviewLayer.frame = CGRect(
            x: cameraPreviewView.bounds.width / 2,
            y: 0, 
            width: cameraPreviewView.bounds.width / 2,
            height: cameraPreviewView.bounds.height
        )
        cameraPreviewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        // addSublayer
        cameraPreviewView.layer.addSublayer(backCameraPreviewLayer)
        cameraPreviewView.layer.addSublayer(backUltraWideCameraPreviewLayer)
    }

    private func bind() {
        $cameraMode.sink { [weak self] mode in
            guard let self else { return }
            switch mode {
            case .teleWide:
                // button mode change
                self.teleWideButton.layer.borderWidth = 2
                self.wideUltraWideButton.layer.borderWidth = 0

                Task {
                    if await self.isAuthorized {
                        self.configureTelephotoCameraSession()
                        self.multiCamSession?.startRunning()
                    } else {
                        print("権限がありません")
                    }
                }
            case .wideUltraWide:
                // button mode change
                self.teleWideButton.layer.borderWidth = 0
                self.wideUltraWideButton.layer.borderWidth = 2
                
                Task {
                    if await self.isAuthorized {
                        self.configureUltraWideCameraSession()
                        self.multiCamSession?.startRunning()
                    } else {
                        print("権限がありません")
                    }
                }
            }
        }.store(in: &cancellables)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureViews()
        configureMultiCamSession()
        bind()
    }

    private func configureMultiCamSession() {
        if let telephotoCamera = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: telephotoCamera) {
            // 望遠カメラ使用可能
            teleWideButton.isHidden = false
            telephotoCameraInput = input
        }

        if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: wideCamera) {
            wideCameraInput = input
        }

        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: ultraWideCamera) {
            // 超広角カメラ使用可能
            wideUltraWideButton.isHidden = false
            ultraWideCameraInput = input
        }
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
