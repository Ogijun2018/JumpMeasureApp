//
//  CalibrateParameter.h
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/19.
//

#ifndef CalibrateParameter_h
#define CalibrateParameter_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CalibrateParameter : NSObject

@property (nonatomic, strong) NSNumber *ret;
@property (nonatomic, strong) NSArray<NSArray<NSNumber *> *> *mtx;
@property (nonatomic, strong) NSArray<NSArray<NSNumber *> *> *dist;
@property (nonatomic, strong) NSArray<NSArray<NSNumber *> *> *rvecs;
@property (nonatomic, strong) NSArray<NSArray<NSNumber *> *> *tvecs;
@property (nonatomic, strong) NSNumber *totalError;

- (instancetype)initWithRet:(NSNumber *)ret
                        mtx:(NSArray<NSArray<NSNumber *> *> *)mtx
                       dist:(NSArray<NSArray<NSNumber *> *> *)dist
                      rvecs:(NSArray<NSArray<NSNumber *> *> *)rvecs
                      tvecs:(NSArray<NSArray<NSNumber *> *> *)tvecs
                 totalError:(NSNumber *)totalError;

@end

#endif /* CalibrateParameter_h */
