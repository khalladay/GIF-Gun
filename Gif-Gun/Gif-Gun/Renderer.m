//
//  Renderer.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "Renderer.h"
#import <MetalKit/MetalKit.h>

const int IN_FLIGHT_FRAMES = 0;

@interface Renderer()
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    dispatch_semaphore_t _inFlightSemaphore;
    NSLock* _sceneLock;
    
    id<MTLRenderPipelineState> _staticGeoPipeline;
    id<MTLRenderPipelineState> _decalPipeline;
    id<MTLDepthStencilState> _depthState;
    
    MTKView* _view;
    MTKMesh* _cubeMesh;
    
    simd_float4x4 _projectionMatrix;
    simd_float4x4 _viewMatrix;

    uint32_t _nextFrameIdx;

}
@end

@implementation Renderer

-(nonnull instancetype)initWithView:(MTKView *)view
{
    if (self = [super init])
    {
        
    }
    return self;
}

-(void)enqeueScene:(Scene *)scn
{
    
}

-(void)handleSizeChange:(CGSize)size
{
    
}

-(void)drawInView:(MTKView *)view
{
    
}

@end
