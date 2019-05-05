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
   // float2 texcoord [[attribute(2)]];
};

struct VertexOUT
{
    float4 position [[position]];
    float3 normal;
    float2 uv0;
};

struct FSQuadVertexIN
{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texcoord [[attribute(2)]];
};

struct FSQuadVertexOUT
{
    float4 position [[position]];
    float2 texcoord;
};

struct Uniforms
{
    float4x4 projectionMatrix;
    float4x4 modelViewMatrix;
};

struct GBufferOUT
{
    float4 albedo [[color(0)]];
    float4 normal [[color(1)]];
};

vertex VertexOUT GBufferFillVSMain(VertexIN vIN [[stage_in]],
                        constant Uniforms& uniforms [[buffer(1)]],
                        constant float3x3& normalMatrix [[buffer(2)]])
{
    VertexOUT vOUT;
    vOUT.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.normal = normalMatrix * vIN.normal;
    return vOUT;
}

fragment GBufferOUT GBufferFillFSMain(VertexOUT fIN [[stage_in]],
                       constant float3& _color [[buffer(1)]])
{
    GBufferOUT OUT;
    OUT.albedo = float4(_color,1);
    OUT.normal = float4( (normalize(fIN.normal) *0.5 + 0.5), 0.0);
    return OUT;
}

vertex FSQuadVertexOUT LightingPassVSMain(FSQuadVertexIN vIN [[stage_in]])
{
    FSQuadVertexOUT vOUT;
    vOUT.position = float4(vIN.position, 1.0);
    vOUT.texcoord = vIN.texcoord;
    return vOUT;

}

fragment float4 LightingPassFSMain(FSQuadVertexOUT fIN [[stage_in]],
                                   texture2d<float, access::sample> GAlbedo [[texture(0)]],
                                   texture2d<float, access::sample> GNorm [[texture(1)]],
                                   depth2d<float, access::sample> GDepth [[texture(2)]])
{
    constexpr sampler samp;

    float3 lightDir = normalize(float3(0.2,0.5,-1.0));
    float4 albedo = GAlbedo.sample(samp, fIN.texcoord);
    float3 normal = (GNorm.sample(samp, fIN.texcoord).xyz * 2.0) - 1.0;
    float d = max(0.0,dot(normalize(normal), lightDir));

    return float4(albedo.xyz * d + albedo.xyz * 0.2, 1.0);
}
