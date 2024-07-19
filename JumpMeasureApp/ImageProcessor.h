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

@interface ImageProcessor : NSObject

+ (UIImage *)generateDisparityMapFromLeftImage:(UIImage *)leftImage rightImage:(UIImage *)rightImage;
+ (double)calculateDistanceFromDisparityMap:(UIImage *)disparityMap point1:(CGPoint)point1 point2:(CGPoint)point2 focalLength:(double)focalLength baseline:(double)baseline;

@end

#endif /* ImageProcessor_h */
