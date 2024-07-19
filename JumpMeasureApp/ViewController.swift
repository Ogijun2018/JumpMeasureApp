//
//  ViewController.swift
//  JumpMeasureApp
//
//  Created by Jun Ogino on 2024/07/10.
//

import UIKit
import AVFoundation
import Combine
import MobileCoreServices

class ViewController: UIViewController {
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
    let shutterButtonSize = CGFloat(80)

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
    
    enum CameraMode {
        case teleWide
        case wideUltraWide
    }

    enum Const {
        static let subViewEdgeInset: CGFloat = 20
    }

    @Published var cameraMode: CameraMode = .teleWide
    private lazy var teleWideButton: UIButton = makeButton(title: "Wide / Telephoto")
    private lazy var wideUltraWideButton: UIButton = makeButton(title: "Wide / UltraWide")

    @Published var ciImages: [CIImage] = []

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

    @Published var isLoading: Bool = true

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
            self?.cameraMode = .teleWide
        }, for: .touchUpInside)

        //wideUltraWideButton config
        wideUltraWideButton.isHidden = true
        wideUltraWideButton.addAction(.init { [weak self] _ in
            self?.cameraMode = .wideUltraWide
        }, for: .touchUpInside)

        calibrationButton.addAction(.init { [weak self] _ in
            print("button tapped")
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
            shutterButton.heightAnchor.constraint(equalToConstant: shutterButtonSize),
            shutterButton.widthAnchor.constraint(equalToConstant: shutterButtonSize),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            shutterButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50)
        ])

        shutterButton.addAction(.init { [weak self] _ in
            self?.shutterButtonTapped()
        }, for: .touchUpInside)
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
        switch cameraMode {
        case .teleWide:
            telephotoCameraOutput?.capturePhoto(with: settings, delegate: self)
            wideCameraOutput?.capturePhoto(with: settings, delegate: self)
        case .wideUltraWide:
            ultraWideCameraOutput?.capturePhoto(with: settings, delegate: self)
            wideCameraOutput?.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureCameraSession(mode: CameraMode) {
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
        $cameraMode.sink { [weak self] mode in
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
            Task {
                self.startLoading()
                try await self.sleepTask()
                if await self.isAuthorized {
                    self.configureMultiCamSession()
                    self.configureCameraSession(mode: mode)
                } else {
                    print("権限がありません")
                }
                try await self.sleepTask()
                self.stopLoading()
            }
        }.store(in: &cancellables)

        $ciImages.sink { [weak self] images in
            guard let self, images.count >= 2 else { return }
            // 画像のキャリブレーションを行う
            let (images, scaleFactor) = calibrateImages(images: images, mode: cameraMode)
            // 2つの画像を同じ倍率に変更する
            // calibrateImagesで返ってくるimagesは必ず1番目の焦点距離のほうが短い
            guard let adjustedImages = adjustImagesToSameScale(images: images, scaleFactor: scaleFactor) else { return }
            showPhotoPreviewModal(images: adjustedImages)
        }.store(in: &cancellables)
    }

    func sleepTask() async throws {
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // wait for 0.5s
        } catch {
            print(error.localizedDescription)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureViews()
        startLoading()
        bind()
        stopLoading()
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

    private func configureMultiCamSession() {
        if let telephotoCamera = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: telephotoCamera) {
            // 望遠カメラ使用可能
            teleWideButton.isHidden = false
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
            wideUltraWideButton.isHidden = false
            ultraWideCameraInput = input
            // 出力設定
            ultraWideCameraOutput = AVCapturePhotoOutput()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ViewController {
    private func showPhotoPreviewModal(images: [UIImage]) {
        let vc = ModalViewController(images: images, didTapConfirm: { [weak self] in
//            self?.saveImageToPhotosAlbum(images[0])
//            self?.saveImageToPhotosAlbum(images[1])
            let vc = DisparityMapViewController(images: images)
            self?.navigationController?.pushViewController(vc, animated: true)
        })
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
        present(vc, animated: true, completion: {  [weak self] in
            // MEMO:
            // ciImagesは撮影のタイミングで2回appendされ、2枚になったときにモーダルを表示する
            // sink内でciImagesを削除すると、2回目のappendはguardによって発動せずciImagesに画像が1枚残ってしまう
            // モーダルのcompletionでciImagesを初期化することで確実に一回の撮影ごとにciImagesを削除している
            self?.ciImages = []
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

    // MARK: - Utils private func
    /// EXIFデータから35mm換算の焦点距離を取得
    private func getFocalLength(from image: CIImage) -> CGFloat? {
        guard let exifDict = image.properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let focalLength = exifDict[kCGImagePropertyExifFocalLenIn35mmFilm as String] as? CGFloat
        else { return nil }
        print("🚧 focalLength \(focalLength)")
        return focalLength
    }

    private func trimmingImage(_ image: UIImage, trimmingArea: CGRect) -> UIImage? {
        guard let croppedImage = image.cgImage?.cropping(to: trimmingArea) else {
            return nil
        }
        return .init(cgImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func calibrateImages(images: [CIImage], mode: CameraMode) -> ([UIImage]?, CGFloat?){
        guard let firstFocalLength = getFocalLength(from: images[0]),
              let secondFocalLength = getFocalLength(from: images[1]),
              let firstUIImage = images[0].toUIImage(orientation: .up),
              let secondUIImage = images[1].toUIImage(orientation: .up) else {
            return (nil, nil)
        }

        switch mode {
        case .teleWide:
            // 焦点距離が短い方が広角カメラ
            if firstFocalLength <= secondFocalLength {
                // firstUIImageが広角の場合
                guard let wide = ImageProcessor.undistortion(from: firstUIImage, imageParam: Constant.wideCameraParameter),
                      let telephoto = ImageProcessor.undistortion(from: secondUIImage, imageParam: Constant.telephotoCameraParameter) else { return (nil, nil) }
                return ([wide, telephoto], secondFocalLength/firstFocalLength)
            } else {
                // secondUIImageが広角の場合
                guard let telephoto = ImageProcessor.undistortion(from: firstUIImage, imageParam: Constant.telephotoCameraParameter),
                      let wide = ImageProcessor.undistortion(from: secondUIImage, imageParam: Constant.wideCameraParameter) else { return (nil, nil) }
                return ([wide, telephoto], firstFocalLength/secondFocalLength)
            }
        case .wideUltraWide:
            // 焦点距離が短い方が超広角カメラ
            if firstFocalLength <= secondFocalLength {
                // firstUIImageが超広角の場合
                guard let ultraWide = ImageProcessor.undistortion(from: firstUIImage, imageParam: Constant.ultraWideCameraParameter),
                      let wide = ImageProcessor.undistortion(from: secondUIImage, imageParam: Constant.wideCameraParameter) else { return (nil, nil) }
                return ([ultraWide, wide], secondFocalLength/firstFocalLength)
            } else {
                // secondUIImageが超広角の場合
                guard let wide = ImageProcessor.undistortion(from: firstUIImage, imageParam: Constant.wideCameraParameter),
                      let ultraWide = ImageProcessor.undistortion(from: secondUIImage, imageParam: Constant.ultraWideCameraParameter) else { return (nil, nil) }
                return ([ultraWide, wide], firstFocalLength/secondFocalLength)
            }
        }
    }

    // 焦点距離の異なる二つの画像を同じ倍率に変更する
    private func adjustImagesToSameScale(images: [UIImage]?, scaleFactor: CGFloat?) -> [UIImage]? {
        guard let shortFocalImage = images?[0],
              let longFocalImage = images?[1],
              let scaleFactor else { return nil }

        // 焦点距離の短い方を拡大し、焦点距離の長い方に合わせる
        let trimmingArea = CGRect(
            x: shortFocalImage.centerX - shortFocalImage.size.width / scaleFactor / 2,
            y: shortFocalImage.centerY - shortFocalImage.size.height / scaleFactor / 2 - 30,
            width: shortFocalImage.size.width / scaleFactor,
            height: shortFocalImage.size.height / scaleFactor
        )
        print(scaleFactor)
        print(trimmingArea)
        guard let scaledImage = trimmingImage(shortFocalImage, trimmingArea: trimmingArea) else {
            return nil
        }

        // 拡大した焦点距離の短い画像の画像サイズを焦点距離の長い画像の画像サイズに合わせる
        // MEMO: resizedSizeをlongForcalImage.size.widthとするとscaledImageが 5760x3240 の画像になってしまった
        // 1920x1080に合わせるため、1/3のCGSizeを指定している
        let resizedSize = CGSize(width: longFocalImage.size.width/3, height: longFocalImage.size.height/3)
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0)
        scaledImage.draw(in: CGRect(origin: .zero, size: resizedSize))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        return [longFocalImage, resizedImage]
    }

}

extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: imageData) else { return }
        ciImages.append(ciImage)
    }
}
