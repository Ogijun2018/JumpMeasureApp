//
//  MainViewController.swift
//  JumpMeasureApp
//
//  Created by Jun Ogino on 2024/07/10.
//

import UIKit
import AVFoundation
import Combine

class MainViewController: UIViewController {

    private let viewModel = MainViewModel()

    private let backTelephotoCameraPreviewLayer = AVCaptureVideoPreviewLayer()
    private let backCameraPreviewLayer = AVCaptureVideoPreviewLayer()
    private let backUltraWideCameraPreviewLayer = AVCaptureVideoPreviewLayer()

    // MEMO: 現在、Inputは1つのインスタンスを使い回さず、configureMultiCamSession()で毎回更新している
    private var telephotoCameraInput: AVCaptureDeviceInput?
    private var wideCameraInput: AVCaptureDeviceInput?
    private var ultraWideCameraInput: AVCaptureDeviceInput?

    // output
    private var telephotoCameraOutput: AVCapturePhotoOutput?
    private var wideCameraOutput: AVCapturePhotoOutput?
    private var ultraWideCameraOutput: AVCapturePhotoOutput?

    private let cameraPreviewView = UIView()

    private let loadingIndicatorView: UIActivityIndicatorView = {
        let loading = UIActivityIndicatorView()
        loading.style = .large
        loading.color = .white

        return loading
    }()
    private let loadingBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()

    let shutterButton: UIButton = {
        let button = UIButton()

        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .white
        config.background.backgroundInsets = .init(top: 7, leading: 7, bottom: 7, trailing: 7)

        config.cornerStyle = .capsule
        button.configuration = config
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 4

        return button
    }()

    let stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 10
        return view
    }()

    private let calibrationButton: UIButton = {
        let button = UIButton()
        button.setImage(.init(systemName: "camera.metering.center.weighted"), for: .normal)
        button.tintColor = .white
        return button
    }()

    enum Const {
        static let subViewEdgeInset: CGFloat = 20
        static let shutterButtonSize: CGFloat = 80
    }

    private lazy var teleWideButton: UIButton = makeButton(title: "Wide / Telephoto")
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

    private func configureViews() {
        [cameraPreviewView,
         shutterButton,
         stackView,
         loadingBackgroundView,
         loadingIndicatorView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        stackView.addArrangedSubview(teleWideButton)
        stackView.addArrangedSubview(wideUltraWideButton)
        stackView.addArrangedSubview(calibrationButton)

        // teleWideButton config
        teleWideButton.isHidden = true
        teleWideButton.addAction(.init { [weak self] _ in
            self?.viewModel.updateCameraMode(mode: .teleWide)
        }, for: .touchUpInside)

        //wideUltraWideButton config
        wideUltraWideButton.isHidden = true
        wideUltraWideButton.addAction(.init { [weak self] _ in
            self?.viewModel.updateCameraMode(mode: .wideUltraWide)
        }, for: .touchUpInside)

        calibrationButton.addAction(.init { _ in
            // TODO: アプリ内でキャリブレーションを行いカメラ行列を取得できるようにする
            // seeAlso: https://qiita.com/koba_tomtom/items/8c7ff3ebcc77b29b465c
        }, for: .touchUpInside)

        [cameraPreviewView, 
         loadingBackgroundView,
         loadingIndicatorView].forEach {
            NSLayoutConstraint.activate([
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        // V: |-(>=0)-shutterButton(50)-100-|
        // H: |-(>=0)-shutterButton(50)-(>=0)-|
        NSLayoutConstraint.activate([
            shutterButton.heightAnchor.constraint(equalToConstant: Const.shutterButtonSize),
            shutterButton.widthAnchor.constraint(equalToConstant: Const.shutterButtonSize),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            shutterButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50)
        ])

        shutterButton.addAction(.init { [weak self] _ in
            self?.shutterButtonTapped()
        }, for: .touchUpInside)
    }

    private func configureMultiCamSession() {
        if let telephotoCamera = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: telephotoCamera) {
            // 望遠カメラ使用可能
            viewModel.teleWideButtonIsHidden = false
            telephotoCameraInput = input
            // 出力設定
            telephotoCameraOutput = AVCapturePhotoOutput()
        }

        if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: wideCamera) {
            wideCameraInput = input
            // 出力設定
            wideCameraOutput = AVCapturePhotoOutput()
        }

        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: ultraWideCamera) {
            // 超広角カメラ使用可能
            viewModel.wideUltraWideButtonIsHidden = false
            ultraWideCameraInput = input
            // 出力設定
            ultraWideCameraOutput = AVCapturePhotoOutput()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        teleWideButton.layer.cornerRadius = teleWideButton.frame.height / 2
        wideUltraWideButton.layer.cornerRadius = wideUltraWideButton.frame.height / 2
        shutterButton.layer.cornerRadius = shutterButton.frame.height / 2
    }

    private var cancellables: [AnyCancellable] = []

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func shutterButtonTapped() {
        // 静止画として現在の映像を保存する
        let settings = AVCapturePhotoSettings()
        // 各モードに合わせたoutputからcaptureを行う
        switch viewModel.cameraMode {
        case .teleWide:
            telephotoCameraOutput?.capturePhoto(with: settings, delegate: self)
            wideCameraOutput?.capturePhoto(with: settings, delegate: self)
        case .wideUltraWide:
            ultraWideCameraOutput?.capturePhoto(with: settings, delegate: self)
            wideCameraOutput?.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureCameraSession(mode: MainViewModel.CameraMode) {
        let multiCamSession = AVCaptureMultiCamSession()

        // メインの画面に表示させるカメラ映像は倍率の高い方を採用する

        switch mode {
        case .teleWide:
            // メイン映像: 望遠カメラ
            // サブ映像: 広角カメラ
            guard let wideCameraInput,
                  let wideCameraOutput,
                  let telephotoCameraInput,
                  let telephotoCameraOutput else { return }
            // Setting for wideCamera
            multiCamSession.addInput(wideCameraInput)
            multiCamSession.addOutput(wideCameraOutput)
            settingPreviewLayer(layer: backCameraPreviewLayer, session: multiCamSession)

            let subViewWidth = cameraPreviewView.bounds.width / 4
            let subViewHeight = cameraPreviewView.bounds.height / 3
            backCameraPreviewLayer.frame = CGRect(
                x: cameraPreviewView.safeAreaLayoutGuide.layoutFrame.maxX - subViewWidth - Const.subViewEdgeInset,
                y: cameraPreviewView.safeAreaLayoutGuide.layoutFrame.minY + Const.subViewEdgeInset,
                width: subViewWidth,
                height: subViewHeight
            )

            // Setting for telephotoCamera
            multiCamSession.addInput(telephotoCameraInput)
            multiCamSession.addOutput(telephotoCameraOutput)
            settingPreviewLayer(layer: backTelephotoCameraPreviewLayer, session: multiCamSession)
            backTelephotoCameraPreviewLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: cameraPreviewView.bounds.width,
                height: cameraPreviewView.bounds.height
            )

            backTelephotoCameraPreviewLayer.opacity = 1.0
            backCameraPreviewLayer.opacity = 0.5
            backTelephotoCameraPreviewLayer.cornerRadius = 0
            backCameraPreviewLayer.cornerRadius = 10

            cameraPreviewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            // addSublayer
            cameraPreviewView.layer.addSublayer(backTelephotoCameraPreviewLayer)
            cameraPreviewView.layer.addSublayer(backCameraPreviewLayer)
        case .wideUltraWide:
            // メイン映像: 広角カメラ
            // サブ映像: 超広角カメラ
            guard let wideCameraInput,
                  let wideCameraOutput,
                  let ultraWideCameraInput,
                  let ultraWideCameraOutput else { return }
            // Setting for wideCamera
            multiCamSession.addInput(wideCameraInput)
            multiCamSession.addOutput(wideCameraOutput)
            settingPreviewLayer(layer: backCameraPreviewLayer, session: multiCamSession)
            backCameraPreviewLayer.frame = CGRect(
                x: 0,
                y: 0,
                width: cameraPreviewView.bounds.width,
                height: cameraPreviewView.bounds.height
            )

            // Setting for ultraWideCamera
            multiCamSession.addInput(ultraWideCameraInput)
            multiCamSession.addOutput(ultraWideCameraOutput)
            settingPreviewLayer(layer: backUltraWideCameraPreviewLayer, session: multiCamSession)

            let subViewWidth = cameraPreviewView.bounds.width / 4
            let subViewHeight = cameraPreviewView.bounds.height / 3
            backUltraWideCameraPreviewLayer.frame = CGRect(
                x: cameraPreviewView.safeAreaLayoutGuide.layoutFrame.maxX - subViewWidth - Const.subViewEdgeInset,
                y: cameraPreviewView.safeAreaLayoutGuide.layoutFrame.minY + Const.subViewEdgeInset,
                width: subViewWidth,
                height: subViewHeight
            )
            
            backCameraPreviewLayer.opacity = 1.0
            backUltraWideCameraPreviewLayer.opacity = 0.5
            backCameraPreviewLayer.cornerRadius = 0
            backUltraWideCameraPreviewLayer.cornerRadius = 10

            cameraPreviewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            // addSublayer
            cameraPreviewView.layer.addSublayer(backCameraPreviewLayer)
            cameraPreviewView.layer.addSublayer(backUltraWideCameraPreviewLayer)
        }

        multiCamSession.startRunning()
    }

    private func settingPreviewLayer(layer: AVCaptureVideoPreviewLayer, session: AVCaptureSession) {
        layer.session = session
        layer.connection?.videoRotationAngle = 0
        layer.videoGravity = .resizeAspectFill
    }

    private func bind() {

        viewModel.$cameraMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
            guard let self else { return }
            switch mode {
            case .teleWide:
                // button mode change
                self.teleWideButton.layer.borderWidth = 2
                self.wideUltraWideButton.layer.borderWidth = 0
            case .wideUltraWide:
                // button mode change
                self.teleWideButton.layer.borderWidth = 0
                self.wideUltraWideButton.layer.borderWidth = 2
            }
            configureMultiCamSession()
            configureCameraSession(mode: mode)
        }.store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$matchFeaturesImage, viewModel.$adjustedImages).sink { [weak self] matchFeaturesImage, adjustedImages in
            guard let self, let matchFeaturesImage,
                  let shortFocalImage = adjustedImages?[0],
                  let longFocalImage = adjustedImages?[1] else { return }
            showPhotoPreviewModal(image: matchFeaturesImage, shortFocalImage: shortFocalImage, longFocalImage: longFocalImage)
        }.store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
            guard let self else { return }
            if status {
                self.startLoading()
            } else {
                self.stopLoading()
            }
        }.store(in: &cancellables)

        viewModel.$teleWideButtonIsHidden.sink { [weak self] isHidden in
            self?.teleWideButton.isHidden = isHidden
        }.store(in: &cancellables)

        viewModel.$wideUltraWideButtonIsHidden.sink { [weak self] isHidden in
            self?.wideUltraWideButton.isHidden = isHidden
        }.store(in: &cancellables)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureViews()
        bind()
        viewModel.updateCameraMode(mode: viewModel.cameraMode)
    }

    private func startLoading() {
        loadingIndicatorView.startAnimating()
        loadingBackgroundView.alpha = 0.0
        UIView.animate(withDuration: 0.2) {
            self.loadingBackgroundView.alpha = 1.0
        }
    }

    private func stopLoading() {
        loadingIndicatorView.stopAnimating()
        loadingBackgroundView.alpha = 1.0
        UIView.animate(withDuration: 0.2) {
            self.loadingBackgroundView.alpha = 0.0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension MainViewController {
    private func showPhotoPreviewModal(image: UIImage, shortFocalImage: UIImage, longFocalImage: UIImage) {
        let vc = ModalViewController(
            image: image,
            confirmButtonTitle: "計測点を指定する",
            didTapConfirm: { [weak self] in
                let vc = DisparityMapViewController(
                    shortFocalImage: shortFocalImage,
                    longFocalImage: longFocalImage
                )
                self?.navigationController?.pushViewController(vc, animated: true)
            },
            didTapSave: { [weak self] in
                self?.viewModel.saveButtonDidTap(completion: { matchFeaturesImage, shortFocalImage, longFocalImage in
                    self?.saveImageToPhotosAlbum(matchFeaturesImage)
                    self?.saveImageToPhotosAlbum(shortFocalImage)
                    self?.saveImageToPhotosAlbum(longFocalImage)
                })
            }
        )
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
        present(vc, animated: true, completion: {  [weak self] in
            // MEMO:
            // ciImagesは撮影のタイミングで2回appendされ、2枚になったときにモーダルを表示する
            // sink内でciImagesを削除すると、2回目のappendはguardによって発動せずciImagesに画像が1枚残ってしまう
            // モーダルのcompletionでciImagesを初期化することで確実に一回の撮影ごとにciImagesを削除している
            self?.viewModel.removeCiImages()
        })
    }

    private func saveImageToPhotosAlbum(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Successfully saved image to Photos album")
        }
    }
}

extension MainViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: imageData) else { return }
        viewModel.appendCiImage(image: ciImage)
    }
}
