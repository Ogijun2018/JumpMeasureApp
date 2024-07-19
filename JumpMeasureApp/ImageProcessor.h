//
//  ImageProcessor.h
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/18.
//

#ifndef ImageProcessor_h
#define ImageProcessor_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CalibrateParameter.h"

@interface ImageProcessor : NSObject

+ (UIImage *)undistortionFromImage:(UIImage *)image
                        imageParam:(CalibrateParameter *)param;
+ (double)calculateDistanceFromDisparityMap:(UIImage *)disparityMap point1:(CGPoint)point1 point2:(CGPoint)point2 focalLength:(double)focalLength baseline:(double)baseline;
+ (UIImage *)detectAndDrawKeypointsInImage:(UIImage *)image usingAKAZE:(BOOL)useAKAZE;
+ (UIImage *)matchFeaturesBetweenImage:(UIImage *)image1 andImage:(UIImage *)image2 usingAKAZE:(BOOL)useAKAZE;
+ (UIImage *)transformImage:(UIImage *)image1 andImage:(UIImage *)image2 usingAKAZE:(BOOL)useAKAZE;

@end

#endif /* ImageProcessor_h */
