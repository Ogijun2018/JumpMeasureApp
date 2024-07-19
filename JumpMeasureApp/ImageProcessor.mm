//
//  ImageProcessor.m
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/18.
//

#import "opencv2/opencv.hpp"
#import "ImageProcessor.h"
#import "CalibrateParameter.h"

@implementation ImageProcessor

+ (cv::Mat)undistortion:(cv::Mat)img
                    mtx:(NSArray<NSArray<NSNumber *> *> *)mtx
                    dist:(NSArray<NSArray<NSNumber *> *> *)dist
                    h:(int)h w:(int)w {
    // Convert NSArray to cv::Mat
    cv::Mat cameraMatrix(3, 3, CV_64F), distCoeffs(1, 5, CV_64F);
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            cameraMatrix.at<double>(i, j) = [[mtx objectAtIndex:i] objectAtIndex:j].doubleValue;
        }
    }
    for (int i = 0; i < dist[0].count; i++) {
        distCoeffs.at<double>(0, i) = [[dist objectAtIndex:0] objectAtIndex:i].doubleValue;
    }

    cv::Mat newCameraMatrix = cv::getOptimalNewCameraMatrix(cameraMatrix, distCoeffs, cv::Size(w, h), 0);
    cv::Mat undistorted;
    undistorted.create(img.size(), img.type());

    // Undistort the image
    cv::undistort(img, undistorted, cameraMatrix, distCoeffs, newCameraMatrix);
    return undistorted;
}

/// 画像の歪みを削除するfunc
+ (UIImage *)undistortionFromImage:(UIImage *)image
                        imageParam:(CalibrateParameter *)param {
    cv::Mat imageMat = [self UIImageToCVMat:image];
    int h = imageMat.rows, w = imageMat.cols;
    // 歪み除去
    cv::Mat undistortedMat = [self undistortion:imageMat mtx:param.mtx dist:param.dist h:h w:w];

    UIImage *undistortedImage = [self CVMatToUIImage:undistortedMat];
    return undistortedImage;
}

+ (UIImage *)generateDisparityMapFromLeftImage:(UIImage *)leftImage rightImage:(UIImage *)rightImage {
    cv::Mat leftMat = [self UIImageToCVMat:leftImage];
    cv::Mat rightMat = [self UIImageToCVMat:rightImage];

    if (leftMat.size() != rightMat.size()) {
        printf("%s", "size is different");
        cv::resize(rightMat, rightMat, leftMat.size());
    }

    cv::cvtColor(leftMat, leftMat, cv::COLOR_RGBA2GRAY);
    cv::cvtColor(rightMat, rightMat, cv::COLOR_RGBA2GRAY);

    cv::Ptr<cv::StereoSGBM> stereoSGBM = cv::StereoSGBM::create(16, 5);
    cv::Mat disparity;
    stereoSGBM->compute(leftMat, rightMat, disparity);

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
    cv::Mat mat = cv::Mat(height, width, CV_8UC4, rawData).clone();

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

+ (UIImage *)detectAndDrawKeypointsInImage:(UIImage *)image usingAKAZE:(BOOL)useAKAZE {
    cv::Mat img = [self UIImageToCVMat:image];

    // Convert to grayscale
    cv::Mat gray;
    cv::cvtColor(img, gray, cv::COLOR_RGBA2GRAY);

    // Feature detector configuration
    cv::Ptr<cv::Feature2D> detector;
    if (useAKAZE) {
        detector = cv::AKAZE::create();
    } else {
//        detector = cv::SIFT::create();
    }

    // Detect keypoints
    std::vector<cv::KeyPoint> keypoints;
    cv::Mat descriptors;
    detector->detectAndCompute(gray, cv::noArray(), keypoints, descriptors);

    // Draw keypoints
    cv::Mat img_with_keypoints;
    cv::drawKeypoints(img, keypoints, img_with_keypoints, cv::Scalar::all(-1), cv::DrawMatchesFlags::DRAW_RICH_KEYPOINTS);

    // Convert back to UIImage
    UIImage *resultImage = [self CVMatToUIImage:img_with_keypoints];
    return resultImage;
}

/// 特徴点マッチング
+ (UIImage *)matchFeaturesBetweenImage:(UIImage *)image1 andImage:(UIImage *)image2 usingAKAZE:(BOOL)useAKAZE {
    cv::Mat img1 = [self UIImageToCVMat:image1];
    cv::Mat img2 = [self UIImageToCVMat:image2];

    // Convert to grayscale
    cv::Mat gray1, gray2;
    cv::cvtColor(img1, gray1, cv::COLOR_RGBA2GRAY);
    cv::cvtColor(img2, gray2, cv::COLOR_RGBA2GRAY);

    // Feature detector and matcher
    cv::Ptr<cv::Feature2D> detector= cv::AKAZE::create();
    std::vector<cv::KeyPoint> keypoints1, keypoints2;
    cv::Mat descriptors1, descriptors2;
    detector->detectAndCompute(gray1, cv::noArray(), keypoints1, descriptors1);
    detector->detectAndCompute(gray2, cv::noArray(), keypoints2, descriptors2);

    // Matching descriptors
    cv::BFMatcher matcher(cv::NORM_HAMMING, true);
    std::vector<cv::DMatch> matches;
    matcher.match(descriptors1, descriptors2, matches);

    // Sort matches by score
    std::sort(matches.begin(), matches.end(), [](const cv::DMatch &a, const cv::DMatch &b) {
        return a.distance < b.distance;
    });

    // Draw top matches
    std::vector<cv::DMatch> goodMatches(matches.begin(), matches.begin() + round(matches.size() * 0.1));
    cv::Mat imgMatches;
    cv::drawMatches(img1, keypoints1, img2, keypoints2, goodMatches, imgMatches, cv::Scalar::all(-1), cv::Scalar::all(-1), std::vector<char>(), cv::DrawMatchesFlags::NOT_DRAW_SINGLE_POINTS);

    return [self CVMatToUIImage:imgMatches];
}

+ (UIImage *)transformImage:(UIImage *)image1 andImage:(UIImage *)image2 usingAKAZE:(BOOL)useAKAZE {
    cv::Mat img1 = [self UIImageToCVMat:image1];
    cv::Mat img2 = [self UIImageToCVMat:image2];

    // Convert to grayscale
    cv::Mat gray1, gray2;
    cv::cvtColor(img1, gray1, cv::COLOR_RGBA2GRAY);
    cv::cvtColor(img2, gray2, cv::COLOR_RGBA2GRAY);

    // Ensure images are in CV_8U for color mapping
    gray1.convertTo(gray1, CV_8UC1);
    gray2.convertTo(gray2, CV_8UC1);

    // Feature detector and matcher
    cv::Ptr<cv::Feature2D> detector = cv::AKAZE::create();
    std::vector<cv::KeyPoint> keypoints1, keypoints2;
    cv::Mat descriptors1, descriptors2;

    detector->detectAndCompute(gray1, cv::noArray(), keypoints1, descriptors1);
    detector->detectAndCompute(gray2, cv::noArray(), keypoints2, descriptors2);

    // Matching descriptors using BFMatcher
    cv::BFMatcher matcher(cv::NORM_HAMMING, true);
    std::vector<cv::DMatch> matches;
    matcher.match(descriptors1, descriptors2, matches);

    // Sort matches by score
    std::sort(matches.begin(), matches.end(), [](const cv::DMatch &a, const cv::DMatch &b) {
        return a.distance < b.distance;
    });

    // マッチングコストの高い上位 10% を描画用に抽出する
    std::vector<cv::DMatch> goodMatches(matches.begin(), matches.begin() + round(matches.size() * 0.1));

    // 位置合わせ
    std::vector<cv::Point2f> srcPoints, dstPoints;
    for (const auto& match : goodMatches) {
        srcPoints.push_back(keypoints1[match.queryIdx].pt);
        dstPoints.push_back(keypoints2[match.trainIdx].pt);
    }

    cv::Mat mask, H = cv::findHomography(srcPoints, dstPoints, cv::RANSAC, 5.0, mask);
    cv::Mat Re_img2;

    // Ensure Re_img2 is in grayscale and then convert to CV_8UC1 if it's not already
    cv::warpPerspective(img2, Re_img2, H, img1.size());
    if (Re_img2.channels() > 1) {
        cv::cvtColor(Re_img2, Re_img2, cv::COLOR_BGR2GRAY);
    }
    Re_img2.convertTo(Re_img2, CV_8UC1);
    
    // Ensure img1 is in grayscale and then convert to CV_8UC1 if it's not already
    if (img1.channels() > 1) {
        cv::cvtColor(img1, img1, cv::COLOR_BGR2GRAY);
    }
    img1.convertTo(img1, CV_8UC1);


    // Extract matches used in the homography computation
    std::vector<cv::DMatch> usedMatches;
    for (int i = 0; i < mask.rows; i++) {
        if (mask.at<uchar>(i) == 1) {
            usedMatches.push_back(goodMatches[i]);
        }
    }

    // Prepare images for overlap and disparity computation
    cv::Mat img1Jet, Re_img2HSV;
    cv::applyColorMap(img1, img1Jet, cv::COLORMAP_JET);
    cv::applyColorMap(Re_img2, Re_img2HSV, cv::COLORMAP_HSV);
    cv::Mat overlapImg;
    cv::addWeighted(img1Jet, 0.5, Re_img2HSV, 0.5, 0, overlapImg);

    // Return the combined image as UIImage
    return [self CVMatToUIImage:overlapImg];
}

@end
