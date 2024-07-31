//
//  UIImage+Utils.swift
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/15.
//

import UIKit

extension UIImage {
    var centerX: CGFloat {
        return self.size.width / 2
    }
    var centerY: CGFloat {
        return self.size.height / 2
    }
}

extension CIImage {
    func toUIImage(orientation: UIImage.Orientation) -> UIImage? {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(self, from: self.extent) else { return nil }
        return .init(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}
