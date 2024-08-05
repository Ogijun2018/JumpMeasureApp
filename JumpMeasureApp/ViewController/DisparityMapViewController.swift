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

    private let scrollView: UIScrollView = {
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

    init(shortFocalImage: UIImage, longFocalImage: UIImage) {
        self.viewModel = .init(
            shortFocalImage: shortFocalImage,
            longFocalImage: longFocalImage
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        configureViews()
        bind()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.viewDidLayoutSubviews(scaledSize: scrollView.frame.size)
    }

    // MARK: - viewDidLoad private func
    private func configureViews() {
        view.backgroundColor = .white

        [scrollView, disparityImageView, loadingIndicatorView, loadingBackgroundView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(scrollView)
        view.addSubview(loadingBackgroundView)
        view.addSubview(loadingIndicatorView)
        scrollView.addSubview(disparityImageView)

        [scrollView, loadingBackgroundView, loadingIndicatorView].forEach {
            NSLayoutConstraint.activate([
                $0.topAnchor.constraint(equalTo: view.topAnchor),
                $0.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                $0.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        NSLayoutConstraint.activate([
            disparityImageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            disparityImageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
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
        viewModel.$displayImage.sink(receiveValue: { [weak self] image in
            guard let self, let image else { return }
            self.disparityImageView.image = image
        }).store(in: &cancellables)

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

        viewModel.$viewState.sink(receiveValue: { [weak self] state in
            guard let self else { return }
            switch state {
            case .image:
                stopLoading()
            case .modal:
                // 計測点の確認画面を開く
                UIGraphicsBeginImageContextWithOptions(disparityImageView.bounds.size, false, 0.0)
                disparityImageView.layer.render(in: UIGraphicsGetCurrentContext()!)
                guard let image = UIGraphicsGetImageFromCurrentImageContext() else { return }
                UIGraphicsEndImageContext()
                let vc = ModalViewController(
                    image: image,
                    confirmButtonTitle: "計測する",
                    didTapConfirm: { [weak self] in
                        self?.viewModel.didTapConfirm()
                    },
                    didTapSave: { [weak self] in
                        self?.viewModel.didTapSave()
                    }
                )
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.prefersEdgeAttachedInCompactHeight = true
                }
                present(vc, animated: true, completion: { [weak self] in
                    self?.clearSublayers()
                    self?.viewModel.closeModal()
                })
            case .loading:
                startLoading()
                navigationItem.title = "計測中"
            case .alert(_):
                // TODO: アラート
                viewModel.closeModal()
            case .result(let disparityImage):
                let vc = ResultViewController(image: disparityImage)
                navigationController?.pushViewController(vc, animated: true)
            }
        }).store(in: &cancellables)
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
