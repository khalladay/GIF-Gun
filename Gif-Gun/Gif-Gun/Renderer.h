//
//  Renderer.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Scene : NSObject
{
@public
    simd_float3 playerPosition;
}
@end

@interface Renderer : NSObject

-(nonnull instancetype)initWithView:(MTKView*)view;
-(void)drawInView:(MTKView*)view;
-(void)enqeueScene:(Scene*)scn;
-(void)handleSizeChange:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
