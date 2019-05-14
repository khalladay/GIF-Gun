//
//  Ray.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/12/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIMD/simd.h>

NS_ASSUME_NONNULL_BEGIN

@interface Ray : NSObject
{
    @public
    simd_float3 origin;
    simd_float3 direction;
}

-(nonnull instancetype)initWithOrigin:(simd_float3)origin andDirection:(simd_float3)direction;
-(simd_float3) positionAtDistanceFromOrigin:(float)distance;
@end

NS_ASSUME_NONNULL_END
