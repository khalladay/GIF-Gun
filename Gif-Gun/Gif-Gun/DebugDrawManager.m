//
//  DebugDrawManager.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/15/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "DebugDrawManager.h"
#import "metal_utils.h"
#import <MetalKit/MetalKit.h>
#import "shader_structs.h"
#import "AAPLMathUtilities.h"

@interface DebugDrawManager()
{
    id<MTLRenderPipelineState> _debugLinePipeline;
    id<MTLDepthStencilState> _debugDepthState;
    
    id<MTLBuffer> _boxVertexBuffer;
    id<MTLBuffer> _rayVertexBuffer;
    
    MTLVertexDescriptor* _debugLineVertDesc;
    NSMutableArray<BoxCollider*>* _boxes;
    NSMutableArray<Ray*>* _rays;
    id<MTLDevice> _device;
}

-(void)buildDebugPipelines;
-(void)buildBoxMesh;
-(void)buildVertDesc;

@end

@implementation DebugDrawManager

-(nonnull instancetype)init
{
    if (self = [super init])
    {
        _boxes = [NSMutableArray new];
        _rays = [NSMutableArray new];

    }
    return self;
}

+(DebugDrawManager*)sharedInstance
{
    @synchronized (self) {
        static DebugDrawManager* instance = nil;
        if (!instance)
        {
            instance = [DebugDrawManager new];
        }
        return instance;
    }
}

-(void)buildDebugPipelines
{
    //hard code pixel formats to match view (hack)
    _debugLinePipeline = MTLPipelineStateMake(_device, @"DebugLines", @"DebugMeshVSMain", @"DebugMeshFSMain", 1, @[@(MTLPixelFormatBGRA8Unorm_sRGB)], MTLPixelFormatDepth32Float, MTLPixelFormatInvalid,_debugLineVertDesc);
    
    _debugDepthState = MTLDepthStateMake(_device, MTLCompareFunctionLessEqual, NO);
}

-(void)buildRayMesh
{
    float verts[6] =
    {
        0,0,0, 0,0,1
    };
    
    _rayVertexBuffer = [_device newBufferWithBytes:verts length:sizeof(float)*6 options:MTLResourceStorageModeShared];

}

-(void)buildVertDesc
{
    MDLVertexDescriptor* boxVD = [MDLVertexDescriptor new];
    boxVD.attributes[0] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:0 bufferIndex:0];
    boxVD.layouts[0] = [[MDLVertexBufferLayout alloc] initWithStride:sizeof(float) * 3];
    
    _debugLineVertDesc = MTKMetalVertexDescriptorFromModelIO(boxVD);

}

-(void)buildBoxMesh
{
    float w = 0.5;
    float verts[12*6] =
    {
        -w, -w, -w,     w, -w, -w,
        -w, -w, -w,     -w, w, -w,
        -w, -w, -w,     -w, -w, w,
        
        w, -w, -w,      w, w, -w,
        w, -w, -w,      w, -w, w,

        w, w, -w,       -w, w, -w,
        w, w, -w,       w, w, w,

        -w, w, -w,      -w, w, w,
        
        w, w, w,        -w, w, w,
        w, w, w,        w, -w, w,
        w,-w,w,          -w, -w, w,
        -w, w, w,       -w, -w, w
    };
    
    _boxVertexBuffer = [_device newBufferWithBytes:verts length:sizeof(float)*12*6 options:MTLResourceStorageModeShared];
}

-(void)drawScene:(Scene*)scn withDevice:(id<MTLDevice>)device andEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
{
    if (!_debugLinePipeline)
    {
        _device = device;
        [self buildVertDesc];
        [self buildBoxMesh];
        [self buildRayMesh];
        [self buildDebugPipelines];
    }
    
    
    matrix_float4x4 modelMatrix = (matrix_float4x4){ {
        {scn->decalScale.x, 0, 0, 0},
        {0, scn->decalScale.y, 0, 0},
        {0, 0, scn->decalScale.z, 0},
        {scn->decalPos.x, scn->decalPos.y, scn->decalPos.z, 1.0f}
    }};

    ObjectUniforms objectUniforms;
    objectUniforms.modelMatrix = modelMatrix;
    objectUniforms.inv_modelMatrix = matrix_invert(objectUniforms.modelMatrix);
    objectUniforms.normalMatrix = matrix_inverse_transpose(matrix3x3_upper_left(objectUniforms.modelMatrix));
    objectUniforms.modelViewMatrix = matrix_multiply(matrix_invert(scn->playerTransform), objectUniforms.modelMatrix);
    
    [commandEncoder setVertexBytes:&objectUniforms length:sizeof(ObjectUniforms) atIndex:OBJECT_UNIFORM_INDEX];
    [commandEncoder setFragmentBytes:&objectUniforms length:sizeof(ObjectUniforms) atIndex:OBJECT_UNIFORM_INDEX];

    [commandEncoder pushDebugGroup:@"DebugBoxColliders"];
    [commandEncoder setRenderPipelineState:_debugLinePipeline];
    [commandEncoder setVertexBuffer:_boxVertexBuffer offset:0 atIndex:0];
    simd_float4 col = simd_make_float4(1,1,1, 1);
    [commandEncoder setFragmentBytes:&col length:sizeof(simd_float4) atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:24];
    
    [commandEncoder pushDebugGroup:@"DebugRays"];

    for (int i = 0; i < [_rays count]; i++)
    {

        Ray* r = _rays[i];
        matrix_float4x4 modelMatrix = (matrix_float4x4){ {
            {r->len, 0, 0, 0},
            {0, r->len, 0, 0},
            {0, 0, r->len, 0},
            {r->origin.x, r->origin.y, r->origin.z, 1.0f}
        }};

        objectUniforms.modelMatrix = matrix_multiply( modelMatrix,r->rotationMatrix);
        objectUniforms.inv_modelMatrix = matrix_invert(objectUniforms.modelMatrix);
        objectUniforms.normalMatrix = matrix_inverse_transpose(matrix3x3_upper_left(objectUniforms.modelMatrix));
        objectUniforms.modelViewMatrix = matrix_multiply(matrix_invert(scn->playerTransform), objectUniforms.modelMatrix);
        
        
        [commandEncoder setVertexBytes:&objectUniforms length:sizeof(ObjectUniforms) atIndex:OBJECT_UNIFORM_INDEX];
        [commandEncoder setFragmentBytes:&objectUniforms length:sizeof(ObjectUniforms) atIndex:OBJECT_UNIFORM_INDEX];

        [commandEncoder setVertexBuffer:_rayVertexBuffer offset:0 atIndex:0];
        simd_float4 col = simd_make_float4(1,1,1, 1);
        [commandEncoder setFragmentBytes:&col length:sizeof(simd_float4) atIndex:0];
        [commandEncoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:2];
    }

}

-(void)registerBox:(BoxCollider *)b
{
    
}

-(void)unregisterBox:(BoxCollider *)b
{
    
}

-(void)registerRay:(Ray *)r
{
    [_rays addObject:r];
}

-(void)unregisterRay:(Ray *)r
{
    
}

@end
