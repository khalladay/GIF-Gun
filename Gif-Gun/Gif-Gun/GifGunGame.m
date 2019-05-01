//
//  GifGunGame.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "GifGunGame.h"
#import "Renderer.h"

@interface GifGunGame()
{
    Renderer* _renderer;
    Scene* _scn;
}

-(void)constructScene;

@end

@implementation GifGunGame

-(nonnull instancetype)initWithRenderer:(Renderer*)renderer
{
    srand((unsigned int)time(NULL));
    if (self = [super init])
    {
        NSAssert(renderer, @"initializing SphereGame with nil renderer");
        _renderer = renderer;
    
        
        [self constructScene];
    }
    
    return self;
}

-(void)constructScene
{
    _scn = [Scene new];
    _scn->cubePositions[0] = simd_make_float3(0,0,15);
    _scn->cubePositions[1] = simd_make_float3(0,0,-15);
    _scn->cubePositions[2] = simd_make_float3(15,0,0);
    _scn->cubePositions[3] = simd_make_float3(-15,0,0);
    _scn->cubePositions[4] = simd_make_float3(0,-5,0);
    _scn->cubePositions[5] = simd_make_float3(0,15,0);
    
    _scn->cubeScales[0] = simd_make_float3(10,10,10);
    _scn->cubeScales[1] = simd_make_float3(10,10,10);
    _scn->cubeScales[2] = simd_make_float3(10,10,10);
    _scn->cubeScales[3] = simd_make_float3(10,10,10);
    _scn->cubeScales[4] = simd_make_float3(10,10,10);
    _scn->cubeScales[5] = simd_make_float3(10,10,10);
    
    _scn->dragonPosition = simd_make_float3(0,0,0);
    _scn->playerPosition = simd_make_float3(0,3,-3);
}

-(void)tick:(double_t)deltaTime
{
    //todo - version scene struct 
    [_renderer enqeueScene:_scn];
}

@end
