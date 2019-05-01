//
//  shaders.metal
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIN
{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texcoord [[attribute(2)]];
};

struct VertexOUT
{
    float4 position [[position]];
    float3 normal;
    float2 uv0;
};

struct Uniforms
{
    float4x4 projectionMatrix;
    float4x4 modelViewMatrix;
};

vertex VertexOUT VSMain(VertexIN vIN [[stage_in]],
                        constant Uniforms& uniforms [[buffer(1)]])
{
    VertexOUT vOUT;
    vOUT.uv0 = vIN.texcoord;
    vOUT.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.normal = vIN.normal;
    return vOUT;
}

fragment float4 FSMain(VertexOUT fIN [[stage_in]],
                            constant float4& _color [[buffer(1)]])
{
    float3 lightDir = normalize(float3(1,1,-1));
    float d = max(0.0,dot(normalize(fIN.normal), lightDir));
    float4 color = float4(d*_color);
    return color;
}
