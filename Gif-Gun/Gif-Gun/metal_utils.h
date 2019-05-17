//
//  metal_utils.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/15/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#ifndef metal_utils_h
#define metal_utils_h
#import <Metal/Metal.h>

id<MTLRenderPipelineState> MTLPipelineStateMake(id<MTLDevice> device, NSString* label, NSString* vertFunc, NSString* fragFunc, unsigned long sampleCount, NSArray* colorFormats, MTLPixelFormat depthFormat, MTLPixelFormat stencilFormat, MTLVertexDescriptor* vertDesc);

id<MTLDepthStencilState> MTLDepthStateMake(id<MTLDevice> device, MTLCompareFunction depthCompare, bool depthWrite);


#endif /* metal_utils_h */
