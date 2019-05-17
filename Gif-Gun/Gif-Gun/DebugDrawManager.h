//
//  DebugDrawManager.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/15/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Ray.h"
#import "BoxCollider.h"
#import <Metal/Metal.h>
#import "Renderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DebugDrawManager : NSObject

+(DebugDrawManager*)sharedInstance;

-(void)registerRay:(Ray*)r;
-(void)registerBox:(BoxCollider*)b;
-(void)unregisterRay:(Ray*)r;
-(void)unregisterBox:(BoxCollider*)b;

-(void)drawScene:(Scene*)scn withDevice:(id<MTLDevice>)device andEncoder:(id<MTLRenderCommandEncoder>)commandEncoder;

@end

NS_ASSUME_NONNULL_END
