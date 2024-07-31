//
//  DisparityMapViewModel.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/30.
//

import UIKit

final class DisparityMapViewModel {
    private var points: [CGPoint] = []
    @Published var pointState: State = .zeroPoint
    @Published var viewState: ViewState = .image
    // 視差計算のために使用する画像
    private let shortFocalImage: UIImage
    private let longFocalImage: UIImage
    // 2点選択のために使用する画像
    @Published var displayImage: UIImage?

    enum State {
        case zeroPoint
        case onePoint
        case twoPoint(CGPoint, CGPoint)
    }

    enum ViewState {
        /// 計測点を選択する画面
        case image
        /// 2点の選択が完了し計測するボタンがある画面
        case modal
        /// ローディング
        case loading
        /// アラート
        case alert(String)
        /// 結果
        case result(UIImage)
    }

    // MARK: - init
    init(shortFocalImage: UIImage, longFocalImage: UIImage) {
        self.shortFocalImage = shortFocalImage
        self.longFocalImage = longFocalImage
    }

    // MARK: - Public func
    func viewDidLayoutSubviews(scaledSize: CGSize) {
        // 指定されたサイズに収まるように画像のサイズを変更する
        // 二点間の距離を選択するときは歪みの少ない焦点距離の長い方を採用する
        let scaledImage = UIGraphicsImageRenderer(size: scaledSize).image { _ in
            longFocalImage.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        displayImage = scaledImage
    }

    func didTapPoint(location: CGPoint) {
        switch pointState {
        case .zeroPoint:
            points.append(location)
            pointState = .onePoint
        case .onePoint:
            points.append(location)
            pointState = .twoPoint(points[0], points[1])
        case .twoPoint: break
        }
    }

    // モーダルの計測するボタン押下時のイベント
    func didTapConfirm() {
        viewState = .loading
        // TODO: 特徴点の抽出ができなかったときにアプリがクラッシュする
        // 視差画像の生成
        Task { @MainActor in
            try await self.sleepTask()
            let disparityImage = ImageProcessor.generateDisparityMapBetweenImage(shortFocalImage, andImage: longFocalImage)
            try await self.sleepTask()
            guard let disparityImage else {
                viewState = .alert("disparityImage 生成失敗")
                return
            }
            viewState = .result(disparityImage)
        }
    }

    private func sleepTask() async throws {
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // wait for 0.5s
        } catch {
            print(error.localizedDescription)
        }
    }

    func didTapSave() {
        viewState = .alert("hogehoge")
    }

    func didTapOK() {
        viewState = .image
    }

    func openModal() {
        viewState = .modal
    }

    func closeModal() {
        viewState = .image
        points.removeAll()
        pointState = .zeroPoint
    }

    func startLoading() {
        viewState = .loading
    }

    func stopLoading() {
        viewState = .image
    }
}
