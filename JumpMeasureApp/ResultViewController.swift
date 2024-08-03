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
        return imageView
    }()
    private var image: UIImage

    private var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.backgroundColor = .black.withAlphaComponent(0.8)
        stackView.distribution = .fillEqually
        stackView.layoutMargins = .init(top: 0, left: 20, bottom: 0, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    private var point1Label = makeLabel()
    private var point2Label = makeLabel()
    private var distanceLabel = makeLabel()

    private static func makeLabel() -> UILabel {
        let label = UILabel()
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
        view.addSubview(imageView)
        view.addSubview(containerStackView)
        [point1Label, point2Label, distanceLabel].forEach {
            containerStackView.addArrangedSubview($0)
        }
        [imageView, containerStackView, point1Label, point2Label, distanceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // H: |[imageView]|
        // H: ||-20-[containerStackView](centerX)|
        // V: |[imageView]|
        // V: |(centerY)[containerStackView]||
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            containerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            containerStackView.topAnchor.constraint(equalTo: view.centerYAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        point1Label.text = "point1: 4.52342m"
        point2Label.text = "point2: 3.53121m"
        distanceLabel.text = "result: 6.45m"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
