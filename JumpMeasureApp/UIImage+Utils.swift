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

    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

extension CIImage {
    func toUIImage(orientation: UIImage.Orientation) -> UIImage? {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(self, from: self.extent) else { return nil }
        return .init(cgImage: cgImage, scale: 1.0, orientation: orientation)
    }
}
