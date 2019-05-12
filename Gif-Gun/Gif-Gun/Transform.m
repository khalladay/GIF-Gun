//
//  Transform.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/11/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "Transform.h"
#define DEG2RAD 0.01745329251

@interface Transform()
-(void)updateMatrix;
@end

@implementation Transform

-(nonnull instancetype)init
{
    if (self = [super init])
    {
        matrix = matrix_identity_float4x4;
        forward = simd_make_float3(0,0,1);
        right = simd_make_float3(1,0,0);
        up = simd_make_float3(0,1,0);
        scale = simd_make_float3(1,1,1);
        position = simd_make_float3(0,0,0);
        rotation = quaternion_identity();
    }
    return self;
}

-(void)updateMatrix
{
    matrix =  matrix4x4_scale(scale);
    matrix = matrix_multiply(matrix4x4_from_quaternion(rotation), matrix);
    matrix = matrix_multiply(matrix4x4_translation(position), matrix);
    

    up = matrix_multiply(matrix, (simd_make_float4(0,1,0,0))).xyz;
    right = quaternion_rotate_vector(rotation, simd_make_float3(1,0,0));// (matrix, (simd_make_float4(1,0,0,0))).xyz;
    forward = matrix_multiply(matrix, (simd_make_float4(0,0,1,0))).xyz;
}

-(void)rotateOnAxis:(simd_float3)axis angle:(float)degrees
{
    quaternion_float q = quaternion_from_axis_angle(axis, degrees * DEG2RAD);
    
    rotation = quaternion_multiply(q,rotation);
    [self updateMatrix];
}

-(void)translate:(simd_float3)vector
{
    position += vector;
    [self updateMatrix];
}

-(void)setPosition:(simd_float3)newPosition
{
    position = newPosition;
    [self updateMatrix];
}

-(void)setScale:(simd_float3)newScale
{
    scale = newScale;
    [self updateMatrix];
}

@end
