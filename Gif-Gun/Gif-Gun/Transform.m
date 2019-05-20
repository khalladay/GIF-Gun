//
//  Transform.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/11/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "Transform.h"
#import "AAPLMathUtilities.h"
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

-(void)setRotation:(quaternion_float)rot
{
    rotation = rot;
    [self updateMatrix];
}

-(Transform*)copy
{
    Transform* t = [Transform new];
    t->scale = scale;
    t->rotation =rotation;
    t->position = position;
    [t updateMatrix];
    return t;
}

-(void)updateMatrix
{
    matrix =  matrix4x4_scale(scale);
    matrix = matrix_multiply(matrix4x4_from_quaternion(rotation), matrix);
    matrix = matrix_multiply(matrix4x4_translation(position), matrix);
    
    up = quaternion_rotate_vector(rotation, simd_make_float3(0,1,0));
    right = quaternion_rotate_vector(rotation, simd_make_float3(1,0,0));
    forward = quaternion_rotate_vector(rotation, simd_make_float3(0,0,1));
}

-(void)rotateOnAxis:(simd_float3)axis angle:(float)degrees
{
    quaternion_float q = quaternion_from_axis_angle(axis, degrees * DEG2RAD);
    
    rotation = quaternion_multiply(q,rotation);
    [self updateMatrix];
}

-(void)lookAt:(simd_float3)target
{
    //construct a rotation matrix to get to this point (look matrix without translation)
    //convert that to a quaterion
    //set rotation
    simd_float3 fwd = simd_normalize(position - target);
    simd_float3 world_up = simd_make_float3(0,1,0);
  
    float upDot = simd_dot(world_up, fwd);
    if (upDot == 1.0 || upDot < -1 + 0.000001) //looking straight up or down
    {
        world_up = simd_make_float3(0,0,1);
    }
    
    simd_float3 our_right = simd_normalize(simd_cross(world_up, fwd));
    simd_float3 cam_up = simd_normalize(simd_cross(fwd, our_right));

    matrix_float3x3 basis = (matrix_float3x3)
     {{
     {our_right.x, cam_up.x, fwd.x},
     {our_right.y, cam_up.y, fwd.y},
     {our_right.z, cam_up.z, fwd.z}
     }};

    rotation = quaternion_from_matrix3x3(basis);
    
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


-(simd_float3) getEuler
{
    //alg from wikipedia
    quaternion_float q = rotation;
    
    double sinr_cosp = +2.0 * (q.w * q.x + q.y * q.z);
    double cosr_cosp = +1.0 - 2.0 * (q.x * q.x + q.y * q.y);
    euler.z = atan2(sinr_cosp, cosr_cosp);
    
    // pitch (y-axis rotation)
    double sinp = +2.0 * (q.w * q.y - q.z * q.x);
    if (fabs(sinp) >= 1)
        euler.x = copysign(M_PI / 2, sinp); // use 90 degrees if out of range
    else
        euler.x = asin(sinp);
    
    // yaw (z-axis rotation)
    double siny_cosp = +2.0 * (q.w * q.z + q.x * q.y);
    double cosy_cosp = +1.0 - 2.0 * (q.y * q.y + q.z * q.z);
    euler.y = atan2(siny_cosp, cosy_cosp);

    return euler;
}

-(void)setRotationEuler:(simd_float3)euler
{
    [self setRotation:quaternion_from_euler(euler)];
}


@end
