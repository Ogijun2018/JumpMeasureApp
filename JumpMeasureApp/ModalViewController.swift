//
//  ModalViewController.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/15.
//

import UIKit

final class ModalViewController: UIViewController {

    private var didTapConfirm: (() -> Void)?

    private let imageContainerView = UIView()
    private let leftImageContainerView = UIView()
    private let rightImageContainerView = UIView()
    private lazy var leftImageView = UIImageView()
    private lazy var rightImageView = UIImageView()

    private let confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle("計測する", for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        button.layer.cornerRadius = 10
        return button
    }()

    private let saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("保存", for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        button.layer.cornerRadius = 10
        return button
    }()

    private let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("キャンセル", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()

    // 比較用の画像
    let images: [UIImage]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configureViews()
        cancelButton.addAction(.init { [weak self] _ in
            self?.didTapCancel()
        }, for: .touchUpInside)
        confirmButton.addAction(.init { [weak self] _ in
            self?.didTapConfirm?()
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
    }

    private func didTapCancel() {
        self.dismiss(animated: true)
    }

    private func configureViews() {
        [imageContainerView, confirmButton, cancelButton, leftImageContainerView, rightImageContainerView, leftImageView, rightImageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // addSubview
        [imageContainerView, confirmButton, cancelButton].forEach {
            view.addSubview($0)
        }
        leftImageContainerView.addSubview(leftImageView)
        rightImageContainerView.addSubview(rightImageView)
        imageContainerView.addSubview(leftImageContainerView)
        imageContainerView.addSubview(rightImageContainerView)

        [leftImageContainerView, rightImageContainerView].forEach {
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = 10
        }

        leftImageView.contentMode = .scaleAspectFill
        rightImageView.contentMode = .scaleAspectFill
        leftImageView.image = images[0]
        rightImageView.image = images[1]

        // V:|[leftImageContainerView]|
        // V:|[rightImageContainerView]|
        // H:|[leftImageContainerView]-10-[rightImageContainerView]|
        NSLayoutConstraint.activate([
            imageContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 25),
            imageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            imageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),

            leftImageContainerView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            leftImageContainerView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            leftImageContainerView.trailingAnchor.constraint(equalTo: imageContainerView.centerXAnchor, constant: -5),
            leftImageContainerView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),

            rightImageContainerView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            rightImageContainerView.leadingAnchor.constraint(equalTo: imageContainerView.centerXAnchor, constant: 5),
            rightImageContainerView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            rightImageContainerView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),

            leftImageView.topAnchor.constraint(equalTo: leftImageContainerView.topAnchor),
            leftImageView.leadingAnchor.constraint(equalTo: leftImageContainerView.leadingAnchor),
            leftImageView.trailingAnchor.constraint(equalTo: leftImageContainerView.trailingAnchor),
            leftImageView.bottomAnchor.constraint(equalTo: leftImageContainerView.bottomAnchor),

            rightImageView.topAnchor.constraint(equalTo: rightImageContainerView.topAnchor),
            rightImageView.leadingAnchor.constraint(equalTo: rightImageContainerView.leadingAnchor),
            rightImageView.trailingAnchor.constraint(equalTo: rightImageContainerView.trailingAnchor),
            rightImageView.bottomAnchor.constraint(equalTo: rightImageContainerView.bottomAnchor),

            confirmButton.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 20),
            confirmButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            cancelButton.topAnchor.constraint(equalTo: confirmButton.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    init(images: [UIImage], didTapConfirm: (() -> Void)?) {
        self.images = images
        self.didTapConfirm = didTapConfirm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
