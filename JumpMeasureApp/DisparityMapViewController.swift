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

    private let disparityImageView = UIImageView()
    private let imageView = UIImageView()
    private let firstImage: UIImage
    private let secondImage: UIImage

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureViews()
        bind()
    }

    private func configureViews() {
        [disparityImageView, imageView, sampleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        [sampleLabel, disparityImageView, imageView].forEach {
            NSLayoutConstraint.activate([
                $0.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                $0.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                $0.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                $0.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }

        // 視差画像の生成
        let disparityImage = ImageProcessor.transform(firstImage, image2: secondImage, usingAKAZE: true)
        disparityImageView.image = disparityImage
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
