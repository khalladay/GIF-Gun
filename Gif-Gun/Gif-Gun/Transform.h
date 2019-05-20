//
//  Transform.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/11/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIMD/simd.h>
#import "AAPLMathUtilities.h"

NS_ASSUME_NONNULL_BEGIN

@interface Transform : NSObject
{
    @public
    simd_float4x4 matrix;
    
    simd_float3 forward;
    simd_float3 right;
    simd_float3 up;
    
    simd_float3 position;
    simd_float3 scale;
    quaternion_float rotation;
    
@private
    simd_float3 euler;
}

-(Transform*)copy;
-(void)translate:(simd_float3)vector;
-(void)rotateOnAxis:(simd_float3)axis angle:(float)degrees;
-(void)setScale:(simd_float3)newScale;
-(void)setPosition:(simd_float3)newPosition;
-(void)lookAt:(simd_float3)target;
-(void)setRotation:(quaternion_float)rot;

-(simd_float3) getEuler;
-(void)setRotationEuler:(simd_float3)euler;

@end

NS_ASSUME_NONNULL_END
