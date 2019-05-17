//
//  metal_utils.c
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/15/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#include "metal_utils.h"

id<MTLRenderPipelineState> MTLPipelineStateMake(id<MTLDevice> device, NSString* label, NSString* vertFunc, NSString* fragFunc, unsigned long sampleCount, NSArray* colorFormats, MTLPixelFormat depthFormat, MTLPixelFormat stencilFormat, MTLVertexDescriptor* vertDesc)
{
    id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];

    MTLRenderPipelineDescriptor* d = [MTLRenderPipelineDescriptor new];
    d.label = label;
    d.vertexFunction = [defaultLibrary newFunctionWithName:vertFunc];
    d.fragmentFunction = [defaultLibrary newFunctionWithName:fragFunc];
    d.sampleCount = sampleCount;
    
    for (int i = 0; i < [colorFormats count]; ++i)
    {
        d.colorAttachments[i].pixelFormat = (MTLPixelFormat)[colorFormats[i] intValue];
    }
    
    d.depthAttachmentPixelFormat = depthFormat;
    d.stencilAttachmentPixelFormat = stencilFormat;
    
    d.vertexDescriptor = vertDesc;
    
    NSError* error = nil;
    id<MTLRenderPipelineState> pipeline = [device newRenderPipelineStateWithDescriptor:d error:&error];
    if (!pipeline)
    {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
    
    return pipeline;
}

id<MTLDepthStencilState> MTLDepthStateMake(id<MTLDevice> device, MTLCompareFunction depthCompare, bool depthWrite)
{
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = depthCompare;
    depthStateDesc.depthWriteEnabled = depthWrite;
    return [device newDepthStencilStateWithDescriptor:depthStateDesc];
}
