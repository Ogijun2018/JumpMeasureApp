//
//  ImageProcessor.m
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/18.
//

#import "opencv2/opencv.hpp"
#import "ImageProcessor.h"

@implementation ImageProcessor

+ (UIImage *)generateDisparityMapFromLeftImage:(UIImage *)leftImage rightImage:(UIImage *)rightImage {
    cv::Mat leftMat = [self UIImageToCVMat:leftImage];
    cv::Mat rightMat = [self UIImageToCVMat:rightImage];

    if (leftMat.size() != rightMat.size()) {
        printf("%s", "size is different");
        cv::resize(rightMat, rightMat, leftMat.size());
    }

    cv::cvtColor(leftMat, leftMat, cv::COLOR_RGBA2GRAY);
    cv::cvtColor(rightMat, rightMat, cv::COLOR_RGBA2GRAY);

//    cv::Ptr<cv::StereoSGBM> stereoSGBM = cv::StereoSGBM::create(
//        0, // minDisparity
//        16, // numDisparities
//        5, // blockSize
//        8 * 3 * 5 * 5, // P1
//        32 * 3 * 5 * 5, // P2
//        1, // disp12MaxDiff
//        63, // preFilterCap
//        10, // uniquenessRatio
//        100, // speckleWindowSize
//        32, // speckleRange
//        cv::StereoSGBM::MODE_SGBM // mode
//    );
    cv::Ptr<cv::StereoSGBM> stereoSGBM = cv::StereoSGBM::create(16, 5);
    cv::Mat disparity;
    stereoSGBM->compute(leftMat, rightMat, disparity);
//    cv::Ptr<cv::StereoBM> stereoBM = cv::StereoBM::create(16, 5);
//    cv::Mat disparity;
//    stereoBM->compute(leftMat, rightMat, disparity);

//    // 視差画像の正規化
//    double minVal, maxVal;
//    cv::minMaxLoc(disparity, &minVal, &maxVal);
//    disparity.convertTo(disparity, CV_8U, 255 / (maxVal - minVal));
//
//    // 視差画像をカラーマップに変換
//    cv::Mat colorDisparity;
//    applyColorMap(disparity, colorDisparity, cv::COLORMAP_JET);
//
//    // 元の左画像をカラーに戻す
////    cv::cvtColor(leftMat, leftMat, cv::COLOR_GRAY2RGBA);
//
//    // 視差画像と元の画像をブレンド
//    cv::Mat blendedImage;
//    double alpha = 0.5; // 透過率の調整
//    cv::addWeighted(leftMat, alpha, colorDisparity, 1 - alpha, 0.0, blendedImage);
//
//    return [self CVMatToUIImage:blendedImage];

    cv::normalize(disparity, disparity, 0, 255, cv::NORM_MINMAX, CV_8U);

    return [self CVMatToUIImage:disparity];
}

+ (double)calculateDistanceFromDisparityMap:(UIImage *)disparityMap point1:(CGPoint)point1 point2:(CGPoint)point2 focalLength:(double)focalLength baseline:(double)baseline {
    cv::Mat disparityMat = [self UIImageToCVMat:disparityMap];

    double disparity1 = disparityMat.at<uchar>(cv::Point(point1.x, point1.y));
    double disparity2 = disparityMat.at<uchar>(cv::Point(point2.x, point2.y));

    if (disparity1 == 0 || disparity2 == 0) {
        return -1; // Invalid disparity value
    }

    double distance1 = (focalLength * baseline) / disparity1;
    double distance2 = (focalLength * baseline) / disparity2;

    return fabs(distance1 - distance2);
}

/// UIImage を cv::Mat に変換する
+ (cv::Mat) UIImageToCVMat:(UIImage *) image {
    // UIImageをCGImageに変換
    CGImageRef imageRef = [image CGImage];

    // CGImageのデータを取得
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;

    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;

    CGContextRef context = CGBitmapContextCreate(
        rawData, width, height,
        bitsPerComponent, bytesPerRow, colorSpace,
        bitmapInfo
    );
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);

    // cv::Matオブジェクトを作成
    cv::Mat mat = cv::Mat(height, width, CV_8UC4, rawData);

    // メモリを解放
    free(rawData);

    return mat;
}

/// cv::Mat を UIImage に変換する
+ (UIImage *) CVMatToUIImage:(cv::Mat) cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];

    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    if (cvMat.elemSize() == 4) {
        bitmapInfo = kCGImageAlphaNoneSkipLast | kCGImageByteOrderDefault;
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(
        cvMat.cols,                 // Width
        cvMat.rows,                 // Height
        8,                          // Bits per component
        8 * cvMat.elemSize(),       // Bits per pixel
        cvMat.step[0],              // Bytes per row
        colorSpace,                 // Color space
        bitmapInfo,                 // Bitmap info
        provider,                   // CGDataProviderRef
        NULL,                       // Decode
        false,                      // Should interpolate
        kCGRenderingIntentDefault   // Intent
    );

    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return image;
}

@end
