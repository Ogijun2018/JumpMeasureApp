//
//  ViewController.swift
//  JumpMeasureApp
//
//  Created by Jun Ogino on 2024/07/10.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    /// デバイスからの入力と出力を管理するsession
    var captureSession = AVCaptureSession()
    var mainCamera: AVCaptureDevice?
    var innerCamera: AVCaptureDevice?
    /// 現在使用しているdevice
    var currentDevice: AVCaptureDevice?
    /// キャプチャーの出力データを受け付けるobject
    var photoOutput: AVCapturePhotoOutput?
    /// プレビュー表示用のlayer
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?

    private func setupDevice() {
        /// デバイス設定
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        /// プロパティの条件を満たしたカメラデバイスの取得
        let devices = deviceDiscoverySession.devices

        for device in devices {
            switch device.position {
            case .back:
                mainCamera = device
            case .front:
                innerCamera = device
            case .unspecified:
                break
            @unknown default:
                fatalError()
            }
        }

        // 起動時のカメラ設定
        currentDevice = mainCamera
    }

    /// 入出力データの設定
    private func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput!.setPreparedPhotoSettingsArray(
                [.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])],
                completionHandler: nil
            )
            captureSession.addOutput(photoOutput!)
        } catch {
            print(error)
        }
    }

    /// カメラのプレビューを表示するレイヤーの設定
    private func setupPreviewLayer() {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(sessionWithNoConnection: captureSession)
        cameraPreviewLayer?.videoGravity = .resize
        cameraPreviewLayer?.connection?.videoRotationAngle = 0
        cameraPreviewLayer?.frame = view.frame
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)

    }
    /// カメラ画質の設定
    private func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
    }
}
