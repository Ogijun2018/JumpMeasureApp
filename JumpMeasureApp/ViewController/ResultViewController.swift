//
//  ResultViewController.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/31.
//

import UIKit

class ResultViewController: UIViewController {

    private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    private var image: UIImage

//    private var containerStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.backgroundColor = .black.withAlphaComponent(0.8)
//        stackView.distribution = .fillEqually
//        stackView.layoutMargins = .init(top: 0, left: 20, bottom: 0, right: 20)
//        stackView.isLayoutMarginsRelativeArrangement = true
//        return stackView
//    }()
//    private var point1Label = makeLabel()
//    private var point2Label = makeLabel()

    private var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray.withAlphaComponent(0.5)
        view.layer.cornerRadius = 20

        return view
    }()
    private var distanceLabel = makeLabel()

    private static func makeLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .semibold)
        label.textColor = .white
        return label
    }

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        configureViews()
    }

    private func configureViews() {
        imageView.image = image

        containerView.addSubview(distanceLabel)
        [imageView, containerView].forEach {
            view.addSubview($0)
        }
        [imageView, containerView, distanceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // H: |-[imageView]-|
        // H: |-[distanceLabel]-|
        // V: |[imageView]|
        // V: ||-20-[distanceLabel]
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 250),
            containerView.heightAnchor.constraint(equalToConstant: 100),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            distanceLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            distanceLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        ])

        distanceLabel.text = "result: 0.323m"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
