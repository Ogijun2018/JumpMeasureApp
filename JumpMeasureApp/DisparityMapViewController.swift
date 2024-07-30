//
//  DisparityMapViewController.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/18.
//

import UIKit

class DisparityMapViewController: UIViewController {

    private var points: [CGPoint] = []

    private var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    private let disparityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let shortFocalImage: UIImage
    private let longFocalImage: UIImage

    init(shortFocalImage: UIImage, longFocalImage: UIImage) {
        self.shortFocalImage = shortFocalImage
        self.longFocalImage = longFocalImage
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "1点目の計測点を選択してください"
        scrollView.delegate = self
        configureViews()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 二点間の距離を選択するときは歪みの少ない焦点距離の長い方を採用する
        let scaledSize = scrollView.frame.size
        let scaledImage = UIGraphicsImageRenderer(size: scaledSize).image { _ in
            longFocalImage.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        disparityImageView.image = scaledImage
    }

    // MARK: - viewDidLoad private func
    private func configureViews() {
        view.backgroundColor = .white

        [scrollView, disparityImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(scrollView)
        scrollView.addSubview(disparityImageView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            disparityImageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            disparityImageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            disparityImageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            disparityImageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])

        // TODO: 特徴点の抽出ができなかったときにアプリがクラッシュする
        // 視差画像の生成
//        let disparityImage = ImageProcessor.transform(firstImage, andImage: secondImage)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }

    private func bind() {}

    // MARK: - GestureRecognizer
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: disparityImageView)

        if points.count < 2 {
            points.append(location)
        }

        // 2点が選ばれたら距離を計算
        if points.count == 2 {
            points.removeAll()
        }
    }

    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        switch scrollView.zoomScale {
        case scrollView.minimumZoomScale:
            scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
        default:
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        }
    }
}

extension DisparityMapViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return disparityImageView
    }
}
