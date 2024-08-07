//
//  MainViewModel.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/08/06.
//

import UIKit
import AVFoundation

class MainViewModel {
    
    enum CameraMode {
        case teleWide
        case wideUltraWide
    }

    @Published var cameraMode: CameraMode = .teleWide
    @Published var teleWideButtonIsHidden = true
    @Published var wideUltraWideButtonIsHidden = true
    @Published var isLoading: Bool = true
    @Published var matchFeaturesImage: UIImage?
    @Published var adjustedImages: [UIImage]?

    private var ciImages: [CIImage] = []
    private var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }

    // MARK: public func
    func removeCiImages() {
        ciImages.removeAll()
    }

    func appendCiImage(image: CIImage) {
        ciImages.append(image)

        // ciImagesが2枚になったら画像のcalibrationを行い、特徴点を計算した画像を更新する
        if ciImages.count >= 2 {
            // 画像のキャリブレーションを行う
            let (images, scaleFactor) = calibrateImages()
            // 2つの画像を同じ倍率に変更する
            // calibrateImagesで返ってくるimagesは必ず1番目の焦点距離のほうが短い
            guard let images, let adjustedImages = adjustImagesToSameScale(images: images, scaleFactor: scaleFactor),
                  // 特徴点ありの画像
                  let matchFeaturesImage = ImageProcessor.matchFeaturesBetweenImage(adjustedImages[0],
                                                                                    andImage: adjustedImages[1]) else { return }
            self.matchFeaturesImage = matchFeaturesImage
            self.adjustedImages = adjustedImages
        }
    }

    func updateCameraMode(mode: CameraMode) {
        Task {
            isLoading = true
            try await self.sleepTask()
            if await self.isAuthorized {
                cameraMode = mode
            } else {
                print("権限がありません")
            }
            try await self.sleepTask()
            isLoading = false
        }
    }

    func saveButtonDidTap(completion: (UIImage, UIImage, UIImage) -> Void) {
        guard let shortFocalImage = adjustedImages?[0],
              let longFocalImage = adjustedImages?[1],
              let matchFeaturesImage else { return }
        completion(matchFeaturesImage, shortFocalImage, longFocalImage)
    }

    // MARK: - private func
    private func sleepTask() async throws {
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // wait for 0.5s
        } catch {
            print(error.localizedDescription)
        }
    }

    private func calibrateImages() -> ([UIImage]?, CGFloat?){
        guard let firstFocalLength = getFocalLength(from: ciImages[0]),
              let secondFocalLength = getFocalLength(from: ciImages[1]),
              let firstUIImage = ciImages[0].toUIImage(orientation: .up),
              let secondUIImage = ciImages[1].toUIImage(orientation: .up) else {
            return (nil, nil)
        }

        switch cameraMode {
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

    // 焦点距離の異なる二つの画像を同じ倍率に変更する
    private func adjustImagesToSameScale(images: [UIImage]?, scaleFactor: CGFloat?) -> [UIImage]? {
        guard let shortFocalImage = images?[0],
              let longFocalImage = images?[1],
              let scaleFactor else { return nil }

        let croppedWidth = shortFocalImage.size.width / (scaleFactor / 1.08)
        let croppedHeight = shortFocalImage.size.height / (scaleFactor / 1.08)
        print(shortFocalImage.size, croppedWidth, croppedHeight)
        // 焦点距離の短い方を拡大し、焦点距離の長い方に合わせる
        let cropRect = CGRect(
            x: (shortFocalImage.size.width - croppedWidth) / 2 - 110,
            y: (shortFocalImage.size.height - croppedHeight) / 2 - 40,
            width: croppedWidth,
            height: croppedHeight
        )

        guard let croppedImage = shortFocalImage.cgImage?.cropping(to: cropRect) else { return nil }
        let scaledImage = UIImage(cgImage: croppedImage, scale: shortFocalImage.scale, orientation: shortFocalImage.imageOrientation)

        // 拡大した焦点距離の短い画像の画像サイズを焦点距離の長い画像の画像サイズに合わせる
        // MEMO: resizedSizeをlongForcalImage.size.widthとするとscaledImageが 5760x3240 の画像になってしまった
        // 1920x1080に合わせるため、1/3のCGSizeを指定している
        let resizedSize = CGSize(width: longFocalImage.size.width/3, height: longFocalImage.size.height/3)
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0)
        scaledImage.draw(in: CGRect(origin: .zero, size: resizedSize))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }

        return [resizedImage, longFocalImage]
    }

}
