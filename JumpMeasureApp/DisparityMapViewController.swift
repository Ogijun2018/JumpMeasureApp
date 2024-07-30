//
//  DisparityMapViewController.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/18.
//

import UIKit
import Combine

class DisparityMapViewController: UIViewController {

    private var viewModel: DisparityMapViewModel
    private var cancellables: [AnyCancellable] = []

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
        self.viewModel = .init()
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

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_ :)))
        scrollView.addGestureRecognizer(tap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        tap.require(toFail: doubleTap)
    }

    private func bind() {
        viewModel.$pointState.sink(receiveValue: { [weak self] state in
            switch state {
            case .zeroPoint:
                self?.navigationItem.title = "1点目の計測点を選択してください"
            case .onePoint:
                self?.navigationItem.title = "2点目の計測点を選択してください"
            case .twoPoint(let point1, let point2):
                self?.drawLineBetweenPoints(points: (point1, point2))
                self?.viewModel.openModal()
            }
        }).store(in: &cancellables)

        viewModel.$route.sink(receiveValue: { [weak self] route in
            guard let self, let route else { return }
            switch route {
            case .modal:
                // 計測点の確認画面を開く
                UIGraphicsBeginImageContextWithOptions(disparityImageView.bounds.size, false, 0.0)
                disparityImageView.layer.render(in: UIGraphicsGetCurrentContext()!)
                guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }
                UIGraphicsEndImageContext()
                let vc = ModalViewController(
                    image: image,
                    confirmButtonTitle: "計測する",
                    didTapConfirm: {
                        // TODO: 特徴点の抽出ができなかったときにアプリがクラッシュする
                        // 視差画像の生成
        //                let disparityImage = ImageProcessor.transform(firstImage, andImage: secondImage)
                    },
                    didTapSave: nil
                )
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.prefersEdgeAttachedInCompactHeight = true
                }
                present(vc, animated: true, completion: { [weak self] in
                    self?.clearSublayers()
                    self?.viewModel.closeModal()
                })
            case .back: 
                break
            }
        }).store(in: &cancellables)
    }

    // MARK: - GestureRecognizer
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: disparityImageView)
        addCircle(at: location)
        viewModel.didTapPoint(location: location)
    }

    private func addCircle(at point: CGPoint) {
        let circlePath = UIBezierPath(arcCenter: point,
                                      radius: 5.0,
                                      startAngle: 0,
                                      endAngle: CGFloat(2 * Double.pi),
                                      clockwise: true)
        let circleLayer = CAShapeLayer()
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.red.cgColor
        disparityImageView.layer.addSublayer(circleLayer)
    }

    private func drawLineBetweenPoints(points: (CGPoint, CGPoint)) {
        let path = UIBezierPath()
        path.move(to: points.0)
        path.addLine(to: points.1)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 2.0
        disparityImageView.layer.addSublayer(shapeLayer)
    }

    private func clearSublayers() {
        if let sublayers = disparityImageView.layer.sublayers {
            for layer in sublayers {
                layer.removeFromSuperlayer()
            }
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
