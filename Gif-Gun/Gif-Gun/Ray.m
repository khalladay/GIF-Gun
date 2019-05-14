//
//  Ray.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/12/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "Ray.h"

@implementation Ray

-(nonnull instancetype)initWithOrigin:(simd_float3)inOrigin andDirection:(simd_float3)inDirection
{
    if (self = [super init])
    {
        origin = inOrigin;
        direction = simd_normalize(inDirection);
    }
    return self;
}

-(simd_float3)positionAtDistanceFromOrigin:(float)distance
{
    return origin + direction * distance;
}

@end
