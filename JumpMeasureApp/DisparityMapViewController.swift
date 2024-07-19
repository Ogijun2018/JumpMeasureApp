//
//  DisparityMapViewController.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/18.
//

import UIKit

class DisparityMapViewController: UIViewController {

    private let sampleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 30, weight: .semibold)
        label.textColor = .white
        return label
    }()

    private var points: [CGPoint] = []

    private let disparityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private let firstImage: UIImage
    private let secondImage: UIImage

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureViews()
        bind()
    }

    private func configureViews() {
        [disparityImageView, sampleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        [sampleLabel, disparityImageView].forEach {
            NSLayoutConstraint.activate([
                $0.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }

        // 視差画像の生成
        let disparityImage = ImageProcessor.transform(firstImage, andImage: secondImage)
        // 二点間の距離を選択するときは歪みの少ない焦点距離の長い方を採用する
        disparityImageView.image = secondImage

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        disparityImageView.addGestureRecognizer(tapGesture)

        sampleLabel.textColor = .black
        sampleLabel.textAlignment = .center
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: disparityImageView)

        if points.count < 2 {
            points.append(location)
        }

        // 2点が選ばれたら距離を計算
        if points.count == 2 {
            sampleLabel.text = "Distance: 1"
            points.removeAll()
        }
    }

    private func bind() {

    }

    init(firstImage: UIImage, secondImage: UIImage) {
        self.firstImage = firstImage
        self.secondImage = secondImage
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
