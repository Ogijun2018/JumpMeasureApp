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
    }

    // MARK: - Public func
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
//                let disparityImage = ImageProcessor.transform(firstImage, andImage: secondImage)
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
