//
//  ModalViewController.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/15.
//

import UIKit

final class ModalViewController: UIViewController {

    private var didTapConfirm: (() -> Void)?
    private var didTapSave: (() -> Void)?

    private let imageContainerView = UIView()
    private lazy var imageView = UIImageView()

    private let confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle("計測する", for: .normal)
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .semibold)
        button.layer.cornerRadius = 10
        return button
    }()

    private let saveToCameraButton: UIButton = {
        let button = UIButton()
        button.setTitle("カメラロールに保存", for: .normal)
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
    let image: UIImage

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
        saveToCameraButton.addAction(.init { [weak self] _ in
            self?.didTapSave?()
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
    }

    private func didTapCancel() {
        self.dismiss(animated: true)
    }

    private func configureViews() {
        [imageContainerView, confirmButton, cancelButton, saveToCameraButton, imageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        // addSubview
        [imageContainerView, confirmButton, cancelButton, saveToCameraButton].forEach {
            view.addSubview($0)
        }
        imageContainerView.addSubview(imageView)
        imageContainerView.layer.masksToBounds = true
        imageContainerView.layer.cornerRadius = 10

        imageView.contentMode = .scaleAspectFill
        imageView.image = image

        // V:|[leftImageContainerView]|
        // V:|[rightImageContainerView]|
        // H:|[leftImageContainerView]-10-[rightImageContainerView]|
        NSLayoutConstraint.activate([
            imageContainerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 25),
            imageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            imageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),

            imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),

            confirmButton.topAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 20),
            confirmButton.widthAnchor.constraint(equalToConstant: 200),
            confirmButton.heightAnchor.constraint(equalToConstant: 50),
            confirmButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),

            saveToCameraButton.topAnchor.constraint(equalTo: confirmButton.topAnchor),
            saveToCameraButton.widthAnchor.constraint(equalToConstant: 200),
            saveToCameraButton.heightAnchor.constraint(equalToConstant: 50),
            saveToCameraButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),

            cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            cancelButton.topAnchor.constraint(equalTo: confirmButton.bottomAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    init(image: UIImage, didTapConfirm: (() -> Void)?, didTapSave: (() -> Void)?) {
        self.image = image
        self.didTapConfirm = didTapConfirm
        self.didTapSave = didTapSave
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
