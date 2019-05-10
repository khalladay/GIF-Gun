//
//  shaders.metal
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#include <metal_stdlib>
#include "shader_structs.h"
using namespace metal;

#pragma mark - Common Types

struct VertexIN
{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

struct Uniforms
{
    float4x4 projectionMatrix;
    float4x4 modelViewMatrix;
    float4x4 modelMatrix;
};

#pragma mark - Common Functions

float linearizeDepth(float d, float nearClip, float farClip)
{
    // Calculate our projection constants (you should of course do this in the app code, I'm just showing how to do it)
    float ProjectionA = farClip / (farClip - nearClip);
    float ProjectionB = (-farClip * nearClip) / (farClip - nearClip);
    
    // Sample the depth and convert to linear view space Z (assume it gets sampled as
    // a floating point value of the range [0,1])
    float linearDepth = ProjectionB / (d - ProjectionA);
    
    return linearDepth;

   
}

#pragma mark - GBufferFill

struct GBufferVertexOUT
{
    float4 position [[position]];
    float4 worldPos;
    float3 normal;
    float2 uv0;
};

struct GBufferOUT
{
    float4 albedo [[color(0)]];
    float4 normal [[color(1)]];
};

vertex GBufferVertexOUT GBufferFillVSMain(VertexIN vIN [[stage_in]],
                        constant Uniforms& uniforms [[buffer(1)]],
                        constant float3x3& normalMatrix [[buffer(2)]])
{
    GBufferVertexOUT vOUT;
    vOUT.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.normal = normalMatrix * vIN.normal;
    vOUT.worldPos = uniforms.modelMatrix * float4(vIN.position, 1.0);
    return vOUT;
}

fragment GBufferOUT GBufferFillFSMain(GBufferVertexOUT fIN [[stage_in]],
                       constant float3& _color [[buffer(1)]])
{
    GBufferOUT OUT;
    OUT.albedo = float4(_color,1);
    OUT.normal = float4( (normalize(fIN.normal) *0.5 + 0.5), 0.0);
    return OUT;
}

#pragma mark - Decals
struct DecalVertexOUT
{
    float4 position [[position]];
    float4 screenPos;
    float4 viewPos;
};


vertex DecalVertexOUT DecalVSMain(VertexIN vIN [[stage_in]],
                                  constant Uniforms& uniforms [[buffer(1)]])
{
    DecalVertexOUT vOUT;
    vOUT.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.viewPos = uniforms.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.screenPos = vOUT.position;
    return vOUT;
}

fragment float4 DecalFSMain(DecalVertexOUT fIN [[stage_in]],
                            constant float2& resolution [[buffer(0)]],
                            constant float& FarClip [[buffer(1)]],
                            constant float4x4& InvViewMatrix [[buffer(2)]],
                            constant float4x4& InvWorldMatrix [[buffer(3)]],
                            depth2d<float, access::sample> GDepth [[texture(0)]],
                            texture2d<float, access::sample> DecalTex [[texture(1)]]
                            )
{
    float2 screenPos = fIN.screenPos.xy / fIN.screenPos.w;
    
    //Convert into a texture coordinate
    float2 texCoord = float2(
                             (1 + screenPos.x) / 2 + (0.5 / resolution.x),
                             (1 - screenPos.y) / 2 + (0.5 / resolution.y)
                             );
    constexpr sampler samp;
    float4 depth = GDepth.sample(samp, texCoord);
    float linearDepth = linearizeDepth(depth.r, 0.1, FarClip);
    
    //creates a ray with a known z position (far clip), so that rather than normalizing
    //this ray and multiplying to scale the length to depth, we can multiply by a value which will
    //scale down ray to the appropriate length. saves a normalize() call
    float3 viewRay = ( float3(fIN.viewPos.xy / (fIN.viewPos.z), 1.0));
    float3 viewPosition = viewRay * linearDepth;
    float3 worldSpacePos = (InvViewMatrix* float4(viewPosition, 1)).xyz;
    
    //Convert from world space to object space
    float4 objectPosition = ( InvWorldMatrix* float4(worldSpacePos, 1));
    
    //Perform bounds check - cube verts are all at 0.5 increments, so if any dimension
    //of objectPosition is outside of -0.5, 0.5, it's not in the box
    float3 absPos = 0.5-abs(objectPosition.xyz);
    if (absPos.x < 0.0 || absPos.y < 0.0 || absPos.z < 0.0)
    {
       discard_fragment();
    }
    
    float2 textureCoordinate = objectPosition.xz + 0.5;

    return float4(textureCoordinate, 0,1);
}

#pragma mark - FullScreenQuad
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

vertex FSQuadVertexOUT FSQuadVSMain(FSQuadVertexIN vIN [[stage_in]])
{
    FSQuadVertexOUT vOUT;
    vOUT.position = float4(vIN.position, 1.0);
    vOUT.texcoord = vIN.texcoord;
    vOUT.texcoord.y = 1.0-vOUT.texcoord.y;
    return vOUT;
}

#pragma mark - FullScreenQuad::VisualizeTexture
fragment float4 VisualizeTextureFSMain(FSQuadVertexOUT fIN [[stage_in]],
                                       texture2d<float, access::sample> targetTexture [[texture(0)]])
{
    constexpr sampler samp;
    return targetTexture.sample(samp, fIN.texcoord);
}

#pragma mark - FullScreenQuad::LightingPass

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
