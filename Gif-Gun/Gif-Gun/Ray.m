//
//  Ray.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/12/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "Ray.h"
#import "AAPLMathUtilities.h"

@implementation Ray

-(nonnull instancetype)initWithOrigin:(simd_float3)inOrigin andDirection:(simd_float3)inDirection
{
    if (self = [super init])
    {
        origin = inOrigin;
        direction = simd_normalize(inDirection);
        len = 1;
        
        const simd_float3 fwd = simd_make_float3(0,0,1);
        float dot = simd_dot(direction, fwd);
        
        if (dot >= 1.0f) //vectors are the same
        {
            rotationMatrix = matrix_identity_float4x4;
        }
        else if (dot <= (-1.0f + 0.000001) ) //vectors are inverse of each other
        {
            //in the inverse case, we just need to rotate our fwd vector 180 around
            //any orthogonal axis, we just can't rotate around a colinear one
            //since we know that the fwd vector is the z axis, just rotate around the y
            quaternion_float rot = quaternion_from_axis_angle(simd_make_float3(0,1,0), 3.14159f); //PI is 180 degrees in radians
            rotationMatrix = matrix4x4_from_quaternion(rot);
        }
        else //regular case
        {
            //rotating one vector to another is a 2D rotation in the plane defined by the normal a X b
            simd_float3 v = simd_cross(fwd, direction); //axis of rotation
            
            float s = sqrtf((1+dot)*2);
            float invs = 1/s;
            
            quaternion_float rot;
            rot.x = v.x*invs;
            rot.y = v.y*invs;
            rot.z = v.z*invs;
            rot.w = s * 0.5f;
            
            rot = simd_normalize(rot);
            rotationMatrix = matrix4x4_from_quaternion(rot);

        }
    }
    return self;
}

-(simd_float3)positionAtDistanceFromOrigin:(float)distance
{
    return origin + direction * distance;
}

@end
