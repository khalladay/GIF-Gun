//
//  Renderer.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "Renderer.h"
#import <MetalKit/MetalKit.h>
#import "LoadingThread.h"

const int IN_FLIGHT_FRAMES = 3;

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
    NSMutableArray<Scene*>* _queuedScenes;
    
    MTLVertexDescriptor* _vertexDescriptor;
    MDLVertexDescriptor* _mdlVertexDescriptor;

    LoadingThread* _loadingThread;
    MTKMeshBufferAllocator* bufferAlloc;

}

-(void)loadMeshes;
-(void)buildPipelines;

@end

@implementation Renderer

-(nonnull instancetype)initWithView:(MTKView *)view
{
    if (self = [super init])
    {
        _device = view.device;
        _view = view;
        [self handleSizeChange:_view.drawableSize];
        _commandQueue = [_device newCommandQueue];
        _inFlightSemaphore = dispatch_semaphore_create(IN_FLIGHT_FRAMES);
        _queuedScenes = [NSMutableArray new];
        _sceneLock = [NSLock new];
        _nextFrameIdx = 0;
        
        [self loadMeshes];
        [self buildPipelines];

    }
    return self;
}

-(void)buildPipelines
{
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    
    //meshes
    {
        MTLRenderPipelineDescriptor* pipelineDesc = [MTLRenderPipelineDescriptor new];
        pipelineDesc.label = @"StaticGeo";
        pipelineDesc.vertexFunction = [defaultLibrary newFunctionWithName:@"VSMain"];
        pipelineDesc.fragmentFunction = [defaultLibrary newFunctionWithName:@"FSMain"];
        pipelineDesc.sampleCount = _view.sampleCount;
        pipelineDesc.colorAttachments[0].pixelFormat = _view.colorPixelFormat;
        pipelineDesc.depthAttachmentPixelFormat = _view.depthStencilPixelFormat;
        pipelineDesc.stencilAttachmentPixelFormat = _view.depthStencilPixelFormat;
        pipelineDesc.vertexDescriptor = _vertexDescriptor;
        
        NSError *error = Nil;
        _staticGeoPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
        if (!_staticGeoPipeline)
        {
            NSLog(@"Failed to created pipeline state, error %@", error);
        }
    }
    
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];


}

-(void)loadMeshes
{
    NSURL* meshes[3];
    meshes[0] = [[NSBundle mainBundle] URLForResource:@"cube" withExtension:@"obj"];
    meshes[1] = [[NSBundle mainBundle] URLForResource:@"dragon" withExtension:@"obj"];
    
    _mdlVertexDescriptor = [MDLVertexDescriptor new];
    _mdlVertexDescriptor.attributes[0] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:0 bufferIndex:0];
    _mdlVertexDescriptor.attributes[1] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeNormal format:MDLVertexFormatFloat3 offset:sizeof(float) * 3 bufferIndex:0];
    _mdlVertexDescriptor.attributes[2] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeTextureCoordinate format:MDLVertexFormatFloat2 offset:sizeof(float) * 2 bufferIndex:0];

    _mdlVertexDescriptor.layouts[0] = [[MDLVertexBufferLayout alloc] initWithStride:sizeof(float) * 8];
    
    _vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(_mdlVertexDescriptor);
    
    bufferAlloc = [[MTKMeshBufferAllocator alloc] initWithDevice:_device];
    _loadingThread = [[LoadingThread alloc] initWithBufferAllocator:bufferAlloc andVertexDesc:_mdlVertexDescriptor];
    _loadingThread.delegate = self;

}

-(void)enqeueScene:(Scene *)scn
{
    
}

-(void)handleSizeChange:(CGSize)size
{
    float aspect = size.width / (float)size.height;
    float fovRadians = 90.0f * (M_PI / 180.0f);
    float ys = 1 / tanf(fovRadians * 0.5);
    float xs = ys / aspect;
    float nearZ = 0.1;
    float farZ = 100.0;
    float zs = farZ / (farZ - nearZ);
    
    _projectionMatrix = (matrix_float4x4){ {
        { xs, 0, 0, 0 },
        { 0, ys, 0, 0 },
        { 0, 0, zs, 1 },
        { 0, 0, -nearZ * zs, 0 } } };
    
    _viewMatrix = (matrix_float4x4){ {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 5, 1 } } };
}

-(void)drawInView:(MTKView *)view
{
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Frame";
    
    MTLRenderPassDescriptor* renderPassDesc = _view.currentRenderPassDescriptor;
    renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 0.0);
    
    if (renderPassDesc != nil)
    {
        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        commandEncoder.label = @"RenderEncoder";
        [commandEncoder setRenderPipelineState:_staticGeoPipeline];
        [commandEncoder setDepthStencilState:_depthState];
        
        [commandEncoder pushDebugGroup:@"DrawStaticGeo"];
        [commandEncoder popDebugGroup];
        
        [commandEncoder endEncoding];
        [commandBuffer presentDrawable:_view.currentDrawable];
        
    }
    
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];
    
    // Finalize rendering here & push the command buffer to the GPU
    [commandBuffer commit];
    
    if (++_nextFrameIdx > (IN_FLIGHT_FRAMES-1)) _nextFrameIdx = 0;

}

- (void)onMeshLoaded:(nonnull MDLAsset *)asset
{
   
}

@end
