//
//  Renderer.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import "LoadingThread.h"
NS_ASSUME_NONNULL_BEGIN

@interface Scene : NSObject
{
@public
    matrix_float4x4 playerTransform;
    simd_float3 cubePositions[6]; //room is built by Axis aligned cubes
    simd_float3 cubeScales[6];
    simd_float3 cubeColors[6];
    
    simd_float3 decalPos;
    simd_float3 decalScale;
}

-(nonnull instancetype)initWithScene:(Scene*)scn;

@end

typedef enum
{
    Default = 0,
    VisualizePositionBuffer
}RenderMode;

@interface Renderer : NSObject<LoadingThreadDelegate>

-(nonnull instancetype)initWithView:(MTKView*)view;
-(void)drawInView:(MTKView*)view;
-(void)enqeueScene:(Scene*)scn;
-(void)handleSizeChange:(CGSize)size;
-(void)createDecalTextureWithSize:(CGSize)size data:(const uint8_t*)bytes;
-(void)updateDecalTexture:(CGSize)size data:(const uint8_t*)bytes;
-(void)setRenderMode:(RenderMode)mode;
@end

NS_ASSUME_NONNULL_END
