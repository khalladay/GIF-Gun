//
//  shaders.metal
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

#pragma mark - Common Types

struct VertexIN
{
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
};

#define GLOBAL_UNIFORM_INDEX 1
#define OBJECT_UNIFORM_INDEX 2

//alignment rules: the largest alignment in the struct determines total struct alignment
//ie: float4x4 is 16 byte aligned, this is the largest alignment requirement of all types
//so the struct must be 16 byte aligned. Actual size of struct is 64 * 4 + 4 * 2, but that
//needs to be rounded up the the next 16 byte aligned value, which is 272
struct GlobalUniforms
{
    float4x4 projectionMatrix;
    float4x4 inv_projectionMatrix;
    float4x4 viewMatrix;
    float4x4 inv_viewMatrix;
    int2     resolution;
    float nearClip;
    float farClip;
    
};

static_assert(sizeof(GlobalUniforms) == 272, "Looks like the global uniform buffer size has changed, make sure to copy changes to this struct to the corresponding struct in shader_structs.h");

struct ObjectUniforms
{
    float4x4 modelViewMatrix;
    float4x4 modelMatrix;
    float4x4 inv_modelMatrix;
    float3x3 normalMatrix;
};

#pragma mark - Common Functions

float linearizeDepth(float d, float nearClip, float farClip)
{
    float ProjectionA = farClip / (farClip - nearClip);
    float ProjectionB = (-farClip * nearClip) / (farClip - nearClip);
    
    // Sample the depth and convert to linear view space Z (assume it gets sampled as
    // a floating point value of the range [0,1])
    float linearDepth = ProjectionB / (d - ProjectionA);
    return linearDepth;
}

#pragma mark - Debug Drawing

struct DebugVertexIN
{
    float3 position [[attribute(0)]];
};

struct DebugVertexOUT
{
    float4 pos [[position]];
};

vertex DebugVertexOUT DebugMeshVSMain(DebugVertexIN vIN [[stage_in]],
                                  constant GlobalUniforms& globals [[buffer(GLOBAL_UNIFORM_INDEX)]],
                                  constant ObjectUniforms& primitive [[buffer(OBJECT_UNIFORM_INDEX)]])
{
    DebugVertexOUT vOUT;
    vOUT.pos = globals.projectionMatrix * primitive.modelViewMatrix * float4(vIN.position, 1.0);
    return vOUT;
}

fragment float4 DebugMeshFSMain(DebugVertexOUT fIN [[stage_in]],
                                constant float4& color [[buffer(0)]])
{
    return color;
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
                                          constant GlobalUniforms& globals [[buffer(GLOBAL_UNIFORM_INDEX)]],
                                          constant ObjectUniforms& primitive [[buffer(OBJECT_UNIFORM_INDEX)]])
{
    GBufferVertexOUT vOUT;
    vOUT.position = globals.projectionMatrix * primitive.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.normal = primitive.normalMatrix * vIN.normal;
    vOUT.worldPos = primitive.modelMatrix * float4(vIN.position, 1.0);
    return vOUT;
}

fragment GBufferOUT GBufferFillFSMain(GBufferVertexOUT fIN [[stage_in]],
                                      constant float3& _color [[buffer(0)]])
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
                                  constant GlobalUniforms& globals [[buffer(GLOBAL_UNIFORM_INDEX)]],
                                  constant ObjectUniforms& primitive [[buffer(OBJECT_UNIFORM_INDEX)]])
{
    DecalVertexOUT vOUT;
    vOUT.position = globals.projectionMatrix * primitive.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.viewPos = primitive.modelViewMatrix * float4(vIN.position, 1.0);
    vOUT.screenPos = vOUT.position;
    return vOUT;
}

fragment float4 DecalFSMain(DecalVertexOUT fIN [[stage_in]],
                            constant GlobalUniforms& globals [[buffer(GLOBAL_UNIFORM_INDEX)]],
                            constant ObjectUniforms& primitive [[buffer(OBJECT_UNIFORM_INDEX)]],
                            depth2d<float, access::sample> GDepth [[texture(0)]],
                            texture2d<uint, access::sample> DecalTex [[texture(2)]]
                            )
{
    constexpr sampler samp(coord::normalized,address::repeat,filter::linear);

    float2 screenPos = fIN.screenPos.xy / fIN.screenPos.w;
    float2 texCoord = float2((1 + screenPos.x) / 2, (1 - screenPos.y) / 2);
    
    float4 depth = GDepth.sample(samp, texCoord);
    float linearDepth = linearizeDepth(depth.r, globals.nearClip, globals.farClip);
    
    //creates a ray with a known z position (far clip), so that rather than normalizing
    //this ray and multiplying to scale the length to depth, we can multiply by a value which will
    //scale down ray to the appropriate length. saves a normalize() call
    float3 viewRay = ( float3(fIN.viewPos.xy / (fIN.viewPos.z), 1.0));
    float3 viewPosition = viewRay * linearDepth;
    float3 worldSpacePos = (globals.inv_viewMatrix* float4(viewPosition, 1)).xyz;
    float4 objectPosition = ( primitive.inv_modelMatrix * float4(worldSpacePos, 1));
    
    //Perform bounds check - cube verts are all at 0.5 increments, so if any dimension
    //of objectPosition is outside of -0.5, 0.5, it's not in the box
    float3 absPos = 0.5-abs(objectPosition.xyz);
    if (absPos.x < 0.0 || absPos.y < 0.0 || absPos.z < 0.0)
    {
        discard_fragment();
    }
    
    //prevent any wrapping - this is a hack and only works because our scene is all 90 degree angles
    float2 zDeltVec = float2( (dfdx(objectPosition.z)), (dfdy(objectPosition.z)) );
    float2 zDeltAbs = (abs(zDeltVec));
    if (zDeltAbs.x > 0.0001 || zDeltAbs.y > 0.0001)
    {
        discard_fragment();
    }

    float2 textureCoordinate = objectPosition.xy + 0.5;
    textureCoordinate.xy = 1.0 - textureCoordinate.xy;
    
    uint4 tex = DecalTex.sample(samp, textureCoordinate);
    return float4(tex.x / 255.0, tex.y / 255.0f, tex.z / 255.0f, 1.0);
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
    constexpr sampler samp(coord::normalized,
                           address::repeat,
                           filter::linear);
    return targetTexture.sample(samp, fIN.texcoord);
}

#pragma mark - FullScreenQuad::LightingPass

fragment float4 LightingPassFSMain(FSQuadVertexOUT fIN [[stage_in]],
                                   texture2d<float, access::sample> GAlbedo [[texture(0)]],
                                   texture2d<float, access::sample> GNorm [[texture(1)]],
                                   depth2d<float, access::sample> GDepth [[texture(2)]])
{
    constexpr sampler samp(coord::normalized,
                           address::repeat,
                           filter::linear);
    
    float3 lightDir = normalize(float3(0.2,0.5,-1.0));
    float4 albedo = GAlbedo.sample(samp, fIN.texcoord);
    float3 normal = (GNorm.sample(samp, fIN.texcoord).xyz * 2.0) - 1.0;
    float d = max(0.0,dot(normalize(normal), lightDir));
    
    return float4(albedo.xyz * d + albedo.xyz * 0.2, 1.0);
}
