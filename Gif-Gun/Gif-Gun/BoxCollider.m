//
//  BoxCollider.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/12/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "BoxCollider.h"

@implementation BoxCollider

-(nonnull instancetype)initWithMin:(simd_float3)inMin andMax:(simd_float3)inMax
{
    if (self = [super init])
    {
        min = inMin;
        max = inMax;
        size = inMax - inMin;
        center = inMin + (size * 0.5);
        
        model = (simd_float4x4)
        {{
            {size.x, 0, 0, 0},
            {0, size.y, 0, 0},
            {0, 0, size.z, 0},
            {center.x, center.y, center.z, 1.0}
        }};
    }
    return self;
}

-(nonnull instancetype)initWithSize:(simd_float3)inSize centeredAt:(simd_float3)inCenter
{
    if (self = [super init])
    {
        size = inSize;
        [self recenterAtPoint:inCenter];
    }
    return self;
}

-(void)recenterAtPoint:(simd_float3)inCenter
{
    center = inCenter;
    min = inCenter - size*0.5;
    max = inCenter + size*0.5;
    model = (simd_float4x4)
    {{
        {size.x, 0, 0, 0},
        {0, size.y, 0, 0},
        {0, 0, size.z, 0},
        {center.x, center.y, center.z, 1.0}
    }};

}

-(BOOL)intersectsBox:(BoxCollider*)box
{
    return (min.x <= box->max.x && max.x >= box->min.x) &&
    (min.y <= box->max.y && max.y >= box->min.y) &&
    (min.z <= box->max.z && max.z >= box->min.z);

    return true;
}

-(BOOL)containsPoint:(simd_float3)point
{
    return (point.x >= min.x && point.x <= max.x) &&
    (point.y >= min.y && point.y <= max.y) &&
    (point.z >= min.z && point.z <= max.z);
}

-(simd_float3)normalAtSurfacePoint:(simd_float3)point
{
    if (point.x == min.x)
    {
        return simd_make_float3(-1,0,0);
    }
    
    if (point.x == max.x)
    {
        return simd_make_float3(1,0,0);
    }
    
    if (point.z == max.z)
    {
        return simd_make_float3(0,0,1);
    }
    
    if (point.z == min.z)
    {
        return simd_make_float3(0,0,-1);
    }
    
    if (point.y == min.y)
    {
    
        return simd_make_float3(0,-1,0);
    }
    
    return simd_make_float3(0,1,0);
}

@end
