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

@interface DebugDrawManager()
{
    id<MTLRenderPipelineState> _debugLinePipeline;
    id<MTLDepthStencilState> _debugDepthState;
    
    id<MTLBuffer> _boxVertexBuffer;
    MTLVertexDescriptor* _boxVertexDescriptor;
    NSMutableArray<BoxCollider*>* _boxes;
    id<MTLDevice> _device;
}

-(void)buildDebugPipelines;
-(void)buildBoxMesh;

@end

@implementation DebugDrawManager

-(nonnull instancetype)init
{
    if (self = [super init])
    {
        _boxes = [NSMutableArray new];

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
    _debugLinePipeline = MTLPipelineStateMake(_device, @"DebugLines", @"DebugMeshVSMain", @"DebugMeshFSMain", 1, @[@(MTLPixelFormatBGRA8Unorm_sRGB)], MTLPixelFormatDepth32Float_Stencil8, MTLPixelFormatDepth32Float_Stencil8,_boxVertexDescriptor);
    
    _debugDepthState = MTLDepthStateMake(_device, MTLCompareFunctionAlways, NO);
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
    
    MDLVertexDescriptor* boxVD = [MDLVertexDescriptor new];
    boxVD.attributes[0] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:0 bufferIndex:0];
    boxVD.layouts[0] = [[MDLVertexBufferLayout alloc] initWithStride:sizeof(float) * 3];

    _boxVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(boxVD);
    
}
-(void)draw:(id<MTLDevice>)device andEncoder:(id<MTLRenderCommandEncoder>)commandEncoder
{
    if (!_debugLinePipeline)
    {
        _device = device;
        [self buildBoxMesh];
        [self buildDebugPipelines];
    }
    
    [commandEncoder pushDebugGroup:@"DebugBoxColliders"];
    [commandEncoder setRenderPipelineState:_debugLinePipeline];
    [commandEncoder setVertexBuffer:_boxVertexBuffer offset:0 atIndex:0];
    simd_float4 col = simd_make_float4(1,1,1, 1);
    [commandEncoder setFragmentBytes:&col length:sizeof(simd_float4) atIndex:0];
    [commandEncoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:24];

}

-(void)registerBox:(BoxCollider *)b
{
    
}

-(void)unregisterBox:(BoxCollider *)b
{
    
}

-(void)registerRay:(Ray *)r
{
    
}

-(void)unregisterRay:(Ray *)r
{
    
}

@end
