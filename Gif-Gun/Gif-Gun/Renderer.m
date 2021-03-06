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
#import "AAPLMathUtilities.h"
#import "shader_structs.h"
#import "DebugDrawManager.h"
#import "metal_utils.h"

const int IN_FLIGHT_FRAMES = 3;

const int MeshTypeCube = 1;
const int MeshTypeDragon = 2;

@interface Renderer()
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    dispatch_semaphore_t _inFlightSemaphore;
    NSLock* _sceneLock;
    
    id<MTLRenderPipelineState> _staticGeoPipeline;
    id<MTLRenderPipelineState> _lightingPassPipeline;
    id<MTLRenderPipelineState> _visTexturePipeline;

    id<MTLRenderPipelineState> _decalPipeline;
    id<MTLDepthStencilState> _depthState;
    id<MTLDepthStencilState> _decalDepthState;

    id<MTLDepthStencilState> _wireframeDepthState;
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

    id<MTLTexture> _gAlbedo;
    id<MTLTexture> _gNormal;
    id<MTLTexture> _gDepth;
    id<MTLBuffer>  _globalUniforms[IN_FLIGHT_FRAMES];
    
    id<MTLBuffer> _fsQuadVertBuffer;
    MTLVertexDescriptor* _fsQuadVertexDescriptor;
    int _loadedMeshes;
    
    NSMutableArray* _decalTextures;
  //  id<MTLTexture> _decalTexture;
    
    CGSize _currentResolution;
    float farClip;
    RenderMode _mode;
    
}

-(void)loadMeshes;
-(void)allocGBuffer;
-(void)buildPipelines;
-(Scene*)nextQueuedScene;
-(void)buildFullScreenQuad;

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
        _loadedMeshes = 0;
        _mode = Default;
        _decalTextures = [NSMutableArray new];
        
        [self loadMeshes];
        [self buildFullScreenQuad];
        [self buildPipelines];
        [self allocGBuffer];

    }
    return self;
}

-(void)allocGBuffer
{
    MTLTextureDescriptor* texDesc = [MTLTextureDescriptor new];
    texDesc.textureType = MTLTextureType2D;
    texDesc.width = _view.drawableSize.width;
    texDesc.height = _view.drawableSize.height;
    texDesc.pixelFormat = MTLPixelFormatRGBA32Float;
    texDesc.storageMode = MTLStorageModePrivate;
    texDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    
    MTLTextureDescriptor* depthBufferDesc = [MTLTextureDescriptor new];
    depthBufferDesc.textureType = MTLTextureType2D;
    depthBufferDesc.width = _view.drawableSize.width;
    depthBufferDesc.height = _view.drawableSize.height;
    depthBufferDesc.pixelFormat = MTLPixelFormatDepth32Float;
    depthBufferDesc.storageMode = MTLStorageModePrivate;
    depthBufferDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    
    _gAlbedo =   [_device newTextureWithDescriptor:texDesc];
    _gNormal =   [_device newTextureWithDescriptor:texDesc];
    _gDepth  =   [_device newTextureWithDescriptor:depthBufferDesc];
    
    for (int i = 0; i < IN_FLIGHT_FRAMES; ++i)
    {
        _globalUniforms[i] = [_device newBufferWithLength:sizeof(GlobalUniforms) options:MTLResourceStorageModeShared];
    }
    
}


-(void)buildFullScreenQuad
{
    float verts[8*6] =
    {
        -1,-1,0, 0,0,0, 0,0,
        1,-1,0, 0,0,0,1,0,
        1,1,0, 0,0,0,1,1,
        
        1,1,0, 0,0,0,1,1,
        -1,1,0, 0,0,0,0,1,
        -1,-1,0, 0,0,0,0,0
        
    };
    
    _fsQuadVertBuffer = [_device newBufferWithBytes:verts length:sizeof(float)*8*6 options:MTLResourceStorageModeShared];
    
    MDLVertexDescriptor* quadVD = [MDLVertexDescriptor new];
    quadVD.attributes[0] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:0 bufferIndex:0];
    
    quadVD.attributes[1] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeNormal format:MDLVertexFormatFloat3 offset:sizeof(float) * 3 bufferIndex:0];
    
    quadVD.attributes[2] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeTextureCoordinate format:MDLVertexFormatFloat2 offset:sizeof(float) * 6 bufferIndex:0];
    
    quadVD.layouts[0] = [[MDLVertexBufferLayout alloc] initWithStride:sizeof(float) * 8];
    
    _fsQuadVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(quadVD);
    
}

-(void)setRenderMode:(RenderMode)mode
{
    _mode = mode;
}

-(void)buildPipelines
{
    _staticGeoPipeline = MTLPipelineStateMake(_device, @"StaticGeo", @"GBufferFillVSMain", @"GBufferFillFSMain", _view.sampleCount, @[@(MTLPixelFormatRGBA32Float),@(MTLPixelFormatRGBA32Float)], MTLPixelFormatDepth32Float, MTLPixelFormatInvalid, _vertexDescriptor);
    
    _decalPipeline = MTLPipelineStateMake(_device, @"Decals", @"DecalVSMain", @"DecalFSMain", _view.sampleCount, @[@(MTLPixelFormatRGBA32Float)], MTLPixelFormatInvalid, MTLPixelFormatInvalid, _vertexDescriptor);
    
    _visTexturePipeline = MTLPipelineStateMake(_device, @"VisTexture", @"FSQuadVSMain", @"VisualizeTextureFSMain", _view.sampleCount, @[@(_view.colorPixelFormat)], _view.depthStencilPixelFormat, _view.depthStencilPixelFormat,_fsQuadVertexDescriptor);
    
    _lightingPassPipeline = MTLPipelineStateMake(_device, @"StaticGeo", @"FSQuadVSMain", @"LightingPassFSMain", _view.sampleCount, @[@(_view.colorPixelFormat)], _view.depthStencilPixelFormat, _view.depthStencilPixelFormat,_fsQuadVertexDescriptor);

    
    _depthState = MTLDepthStateMake(_device, MTLCompareFunctionLess, YES);
    _decalDepthState = MTLDepthStateMake(_device, MTLCompareFunctionAlways, NO);
}

-(void)loadMeshes
{
    NSURL* meshes[3];
    meshes[0] = [[NSBundle mainBundle] URLForResource:@"cube" withExtension:@"obj"];
    meshes[1] = [[NSBundle mainBundle] URLForResource:@"dragon" withExtension:@"obj"];
    
    _mdlVertexDescriptor = [MDLVertexDescriptor new];
    _mdlVertexDescriptor.attributes[0] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributePosition format:MDLVertexFormatFloat3 offset:0 bufferIndex:0];
    _mdlVertexDescriptor.attributes[1] = [[MDLVertexAttribute alloc] initWithName:MDLVertexAttributeNormal format:MDLVertexFormatFloat3 offset:sizeof(float) * 3 bufferIndex:0];
    _mdlVertexDescriptor.layouts[0] = [[MDLVertexBufferLayout alloc] initWithStride:sizeof(float) * 6];
    _vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(_mdlVertexDescriptor);
    
    bufferAlloc = [[MTKMeshBufferAllocator alloc] initWithDevice:_device];
    _loadingThread = [[LoadingThread alloc] initWithBufferAllocator:bufferAlloc andVertexDesc:_mdlVertexDescriptor];
    _loadingThread.delegate = self;

    [_loadingThread enqueueMeshRequest:meshes[0]];
    [_loadingThread enqueueMeshRequest:meshes[1]];
}

-(void)enqeueScene:(Scene *)scn
{
    NSAssert(scn, @"attempting to enqueue null scene");
    
    [_sceneLock lock];
    [_queuedScenes addObject:scn];
    [_sceneLock unlock];

}

-(void)handleSizeChange:(CGSize)size
{
    float aspect = size.width / (float)size.height;
    float fovRadians = 65.0f * (M_PI / 180.0f);
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
        
    farClip = 100.0;
    _currentResolution = size;
}

-(Scene*)nextQueuedScene
{
    [_sceneLock lock];
    Scene* s = [_queuedScenes firstObject];
    if (s)
    {
        [_queuedScenes removeObjectAtIndex:0];
    }
    [_sceneLock unlock];
    return s;
}

-(void)drawInView:(MTKView *)view
{
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    if ([_queuedScenes count] < 1) return;
    
    Scene* scn = [self nextQueuedScene];
    
    GlobalUniforms globalUniforms;
    globalUniforms.viewMatrix = matrix_invert(scn->playerTransform);
    globalUniforms.projectionMatrix = _projectionMatrix;
    globalUniforms.inv_viewMatrix = matrix_invert(globalUniforms.viewMatrix);
    globalUniforms.inv_projectionMatrix = matrix_invert(globalUniforms.projectionMatrix);
    globalUniforms.farClip = farClip;
    globalUniforms.nearClip = 0.1;
    globalUniforms.resolution.x = _currentResolution.width;
    globalUniforms.resolution.y = _currentResolution.height;
    memcpy(_globalUniforms[_nextFrameIdx].contents, &globalUniforms, sizeof(GlobalUniforms));


    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Frame";
    
    ObjectUniforms objectUniforms;

    {
        {
            MTLRenderPassDescriptor* renderPassDesc = view.currentRenderPassDescriptor;
            renderPassDesc.colorAttachments[0].texture = _gAlbedo;
            renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 0.0);
            renderPassDesc.colorAttachments[1].texture = _gNormal;
            renderPassDesc.depthAttachment.texture = _gDepth;
            renderPassDesc.depthAttachment.loadAction = MTLLoadActionClear;
            renderPassDesc.depthAttachment.storeAction = MTLStoreActionStore;
            renderPassDesc.stencilAttachment.texture = nil;
            renderPassDesc.stencilAttachment.loadAction = MTLLoadActionDontCare;
            renderPassDesc.stencilAttachment.storeAction = MTLLoadActionDontCare;


            if (renderPassDesc != nil)
            {
                id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
                commandEncoder.label = @"RenderEncoder";

                [commandEncoder pushDebugGroup:@"DrawStaticGeo"];

                if (_loadedMeshes >= MeshTypeCube)
                {
                    [commandEncoder pushDebugGroup:@"Cubes"];
                    [commandEncoder setRenderPipelineState:_staticGeoPipeline];
                    [commandEncoder setDepthStencilState:_depthState];
                    [commandEncoder setCullMode:MTLCullModeBack];
                    //fill first
                    [commandEncoder setTriangleFillMode:MTLTriangleFillModeFill];
                    [commandEncoder setVertexBuffer:_cubeMesh.vertexBuffers[0].buffer offset:0 atIndex:0];
                    [commandEncoder setVertexBuffer:_globalUniforms[_nextFrameIdx] offset:0 atIndex:GLOBAL_UNIFORM_INDEX];

                    for (int i = 0; i < 6; ++i)
                    {
                        matrix_float4x4 modelMatrix = (matrix_float4x4){ {
                            {scn->cubeScales[i].x, 0, 0, 0},
                            {0, scn->cubeScales[i].y, 0, 0},
                            {0, 0, scn->cubeScales[i].z, 0},
                            {scn->cubePositions[i].x, scn->cubePositions[i].y, scn->cubePositions[i].z, 1.0f}
                        }};
                        
                        objectUniforms.modelMatrix = modelMatrix;
                        objectUniforms.inv_modelMatrix = matrix_invert(modelMatrix);
                        objectUniforms.normalMatrix = matrix_inverse_transpose(matrix3x3_upper_left(modelMatrix));
                        objectUniforms.modelViewMatrix = matrix_multiply(globalUniforms.viewMatrix, modelMatrix);
                
                        [commandEncoder setVertexBytes:&objectUniforms length:sizeof(ObjectUniforms) atIndex:OBJECT_UNIFORM_INDEX];
                        [commandEncoder setFragmentBytes:&scn->cubeColors[i] length:sizeof(simd_float3) atIndex:0];
                        
                        for (const MTKSubmesh* submesh in _cubeMesh.submeshes)
                        {
                            [commandEncoder drawIndexedPrimitives:submesh.primitiveType indexCount:submesh.indexCount indexType:submesh.indexType indexBuffer:submesh.indexBuffer.buffer indexBufferOffset:submesh.indexBuffer.offset];
                        }

                    }
                    [commandEncoder popDebugGroup];

                }
                
                [commandEncoder popDebugGroup];

                [commandEncoder endEncoding];
                
            }
        }
        
        //draw decals into color buffer - needs new render pass to commit the depth buffer store
        {
            MTLRenderPassDescriptor* renderPassDesc = view.currentRenderPassDescriptor;
            renderPassDesc.colorAttachments[0].texture = _gAlbedo;
            renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 0.0);
            renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
            renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
            renderPassDesc.depthAttachment.texture = nil;
            renderPassDesc.stencilAttachment.texture = nil;
        
            if (renderPassDesc != nil)
            {
                id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];

                for (int i = 0; i < [scn->decals count]; ++i)
                {
                    matrix_float4x4 modelMatrix = scn->decals[i]->transform->matrix;
                    
                    [commandEncoder pushDebugGroup:@"DrawDecals"];
                    [commandEncoder setRenderPipelineState:_decalPipeline];
                    [commandEncoder setDepthStencilState:_decalDepthState];
                    [commandEncoder setVertexBuffer:_cubeMesh.vertexBuffers[0].buffer offset:0 atIndex:0];
                    [commandEncoder setCullMode:MTLCullModeNone];
                    [commandEncoder setVertexBuffer:_globalUniforms[_nextFrameIdx] offset:0 atIndex:GLOBAL_UNIFORM_INDEX];
                    [commandEncoder setFragmentBuffer:_globalUniforms[_nextFrameIdx] offset:0 atIndex:GLOBAL_UNIFORM_INDEX];

                    objectUniforms.modelMatrix = modelMatrix;
                    objectUniforms.inv_modelMatrix = matrix_invert(modelMatrix);
                    objectUniforms.normalMatrix = matrix_inverse_transpose(matrix3x3_upper_left(modelMatrix));
                    objectUniforms.modelViewMatrix = matrix_multiply(globalUniforms.viewMatrix, modelMatrix);
                    
                    [commandEncoder setVertexBytes:&objectUniforms length:sizeof(ObjectUniforms) atIndex:OBJECT_UNIFORM_INDEX];
                    [commandEncoder setFragmentBytes:&objectUniforms length:sizeof(ObjectUniforms) atIndex:OBJECT_UNIFORM_INDEX];

                    [commandEncoder setFragmentTexture:_gDepth atIndex:0];
                    [commandEncoder setFragmentTexture:_decalTextures[scn->decals[i]->textureHandle] atIndex:2];

                    for (const MTKSubmesh* submesh in _cubeMesh.submeshes)
                    {
                        [commandEncoder drawIndexedPrimitives:submesh.primitiveType indexCount:submesh.indexCount indexType:submesh.indexType indexBuffer:submesh.indexBuffer.buffer indexBufferOffset:submesh.indexBuffer.offset];
                    }
                }
                [commandEncoder endEncoding];
            }
        }
        
        {
            MTLRenderPassDescriptor* renderPassDesc = view.currentRenderPassDescriptor;
            renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 0.0);
            renderPassDesc.depthAttachment.loadAction = MTLLoadActionLoad;
            renderPassDesc.depthAttachment.storeAction = MTLStoreActionStore;
            if (renderPassDesc != nil)
            {
                id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
                commandEncoder.label = @"Full Screen Encoder";
                [commandEncoder pushDebugGroup:@"LightingPass"];
                
                [commandEncoder setRenderPipelineState:_lightingPassPipeline];
                [commandEncoder setFragmentTexture:_gAlbedo atIndex:0];
                [commandEncoder setFragmentTexture:_gNormal atIndex:1];
                [commandEncoder setFragmentTexture:_gDepth atIndex:2];

                [commandEncoder setVertexBuffer:_fsQuadVertBuffer offset:0 atIndex:0];
                [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
                [commandEncoder endEncoding];
            }
        }
    }
    
    if (_mode == VisualizePositionBuffer)
    {
        MTLRenderPassDescriptor* renderPassDesc = view.currentRenderPassDescriptor;
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 0.0);
        renderPassDesc.depthAttachment.loadAction = MTLLoadActionLoad;
        renderPassDesc.depthAttachment.storeAction = MTLStoreActionStore;
        
        if (renderPassDesc != nil)
        {
            id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
            commandEncoder.label = @"Vis Tex Encoder";
            [commandEncoder pushDebugGroup:@"VisualizeTexture"];
            
            [commandEncoder setRenderPipelineState:_visTexturePipeline];
            [commandEncoder setFragmentTexture:_gNormal atIndex:0];
            
            [commandEncoder setVertexBuffer:_fsQuadVertBuffer offset:0 atIndex:0];
            [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
            [commandEncoder endEncoding];
        }

    }
    
    if (_mode == DebugDraw)
    {
        MTLRenderPassDescriptor* renderPassDesc = view.currentRenderPassDescriptor;
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
        renderPassDesc.colorAttachments[0].loadAction = MTLLoadActionLoad;
        renderPassDesc.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDesc.depthAttachment.texture = _gDepth;
        renderPassDesc.depthAttachment.loadAction = MTLLoadActionLoad;
        renderPassDesc.depthAttachment.storeAction = MTLStoreActionDontCare;
        renderPassDesc.stencilAttachment.texture = nil;
        renderPassDesc.stencilAttachment.loadAction = MTLLoadActionDontCare;
        renderPassDesc.stencilAttachment.storeAction = MTLLoadActionDontCare;

        id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
        commandEncoder.label = @"DebugDrawing";
        
        [commandEncoder setVertexBuffer:_globalUniforms[_nextFrameIdx] offset:0 atIndex:GLOBAL_UNIFORM_INDEX];
        [commandEncoder setFragmentBuffer:_globalUniforms[_nextFrameIdx] offset:0 atIndex:GLOBAL_UNIFORM_INDEX];

        [[DebugDrawManager sharedInstance] drawScene:scn withDevice:_device andEncoder:commandEncoder];
        [commandEncoder endEncoding];

    }
    
    
    [commandBuffer presentDrawable:_view.currentDrawable];

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
    _loadedMeshes++;
    if (_loadedMeshes == MeshTypeCube)
    {
        NSArray* meshes = [MTKMesh newMeshesFromAsset:asset device:_device sourceMeshes:nil error:nil];
        
        _cubeMesh = meshes[0];
        
    }
}

-(int)createDecalTextureWithSize:(CGSize)size data:(const uint8_t*)bytes
{
    MTLTextureDescriptor* texDesc = [MTLTextureDescriptor new];
    texDesc.textureType = MTLTextureType2D;
    texDesc.pixelFormat = MTLPixelFormatRGBA8Uint;
    texDesc.height = size.height;
    texDesc.width = size.width;
    texDesc.storageMode = MTLStorageModeManaged;
    texDesc.usage = MTLTextureUsageShaderRead;

    [_decalTextures addObject: [_device newTextureWithDescriptor:texDesc]];
    [self updateDecalTexture:[_decalTextures count]-1 size:size data:bytes];
    
    return [_decalTextures count]-1;

}

-(void)updateDecalTexture:(int)index size:(CGSize)size data:(const uint8_t *)bytes
{
    [_decalTextures[index] replaceRegion:MTLRegionMake2D(0, 0, size.width, size.height) mipmapLevel:0 slice:0 withBytes:bytes bytesPerRow:size.width*4 bytesPerImage:size.width * size.height * 4];
}

@end

@implementation Scene
-(nonnull instancetype)initWithScene:(Scene *)scn
{
    NSAssert(scn != nil, @"Attempting to init scene with null source scene");
    if (self = [super init])
    {
        for (int i = 0; i < 6; ++i)
        {
            cubePositions[i] = scn->cubePositions[i];
            cubeColors[i] = scn->cubeColors[i];
            cubeScales[i] = scn->cubeScales[i];
        }
    
        decals = [[NSMutableArray alloc] init];
        for (int i = 0; i < [scn->decals count]; ++i)
        {
            [decals addObject:scn->decals[i]];
        }
        playerTransform = matrix_multiply(matrix_identity_float4x4, scn->playerTransform);
    }
    return self;
}
@end

@implementation DecalInstance



@end
