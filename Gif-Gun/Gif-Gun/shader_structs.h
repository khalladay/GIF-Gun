//
//  shader_structs.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/10/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#ifndef shader_structs_h
#define shader_structs_h
#import <Metal/Metal.h>

#define GLOBAL_UNIFORM_INDEX 1
#define OBJECT_UNIFORM_INDEX 2

typedef struct
{
    simd_float4x4 projectionMatrix;
    simd_float4x4 inv_projectionMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 inv_viewMatrix;
    simd_int2     resolution;
    float nearClip;
    float farClip;
}GlobalUniforms;

static_assert(sizeof(GlobalUniforms) == 272, "Looks like the global uniform buffer size has changed, make sure to copy changes to this struct to the corresponding struct in shaders.metal");

typedef struct
{
    simd_float4x4 modelViewMatrix;
    simd_float4x4 modelMatrix;
    simd_float4x4 inv_modelMatrix;
    simd_float3x3 normalMatrix;
}ObjectUniforms;

#endif /* shader_structs_h */
