//
//  CalibrateParameter.m
//  JumpMeasureApp
//
//  Created by jun.ogino on 2024/07/19.
//

#import "CalibrateParameter.h"

@implementation CalibrateParameter

// MEMO: テスト版ではiPhone 13 Pro Maxのカメラでキャリブレーションを行なった結果を仮の値として入れている
// 同機以外で撮影した場合、歪み補正はうまくいかない可能性が高い
- (instancetype)initWithRet:(NSNumber *)ret
                        mtx:(NSArray<NSArray<NSNumber *> *> *)mtx
                       dist:(NSArray<NSArray<NSNumber *> *> *)dist
                      rvecs:(NSArray<NSArray<NSNumber *> *> *)rvecs
                      tvecs:(NSArray<NSArray<NSNumber *> *> *)tvecs
                 totalError:(NSNumber *)totalError {
    self = [super init];
    if (self) {
        _ret = ret;
        _mtx = mtx;
        _dist = dist;
        _rvecs = rvecs;
        _tvecs = tvecs;
        _totalError = totalError;
    }
    return self;
}

@end
