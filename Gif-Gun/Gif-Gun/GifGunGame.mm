//
//  GifGunGame.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "GifGunGame.h"
#import "Renderer.h"
#import "AAPLMathUtilities.h"
#include "gif_read.h"
#include "Transform.h"
#define DEG2RAD 0.01745329251

@interface GifGunGame()
{
    Renderer* _renderer;
    Scene* _scn;
    
    simd_float3 _playerBounds; //player is modelled as a cube collider
    
    gif_read::StreamingCompressedGIF* _gif;
    
    bool _forward;
    bool _back;
    bool _left;
    bool _right;
    
    Transform* _playerTransform;
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
        _playerTransform = [Transform new];
        [_playerTransform setPosition:simd_make_float3(-4, 1.5, 0)];
        [_playerTransform rotateOnAxis:simd_make_float3(0, 1, 0) angle:45.0];
        
        NSURL* imgURL = [[NSBundle mainBundle] URLForResource:@"snoopy" withExtension:@"gif"];
        NSString* str = [imgURL path];
        
        FILE* fp = fopen([str cStringUsingEncoding:NSUTF8StringEncoding], "rb");
        fseek(fp, 0, SEEK_END);
        size_t len = ftell(fp);
        
        uint8_t* gifData = (uint8_t*)malloc(len);
        rewind(fp);
        fread(gifData, len, 1, fp);
        
        _gif = new gif_read::StreamingCompressedGIF(gifData);
        [_renderer createDecalTextureWithSize:CGSizeMake(_gif->getWidth(), _gif->getHeight()) data:_gif->getCurrentFrame()];
        
        free(gifData);
        fclose(fp);
        
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
    _scn->cubePositions[5] = simd_make_float3(0,12,0);
    
    _scn->cubeScales[0] = simd_make_float3(20,20,10);
    _scn->cubeScales[1] = simd_make_float3(20,20,10);
    _scn->cubeScales[2] = simd_make_float3(10,20,20);
    _scn->cubeScales[3] = simd_make_float3(10,20,20);
    _scn->cubeScales[4] = simd_make_float3(20,5,20);
    _scn->cubeScales[5] = simd_make_float3(20,10,20);
    
    _scn->cubeColors[0] = simd_make_float3(0.0,0.5,0.1);
    _scn->cubeColors[1] = simd_make_float3(1.0,0.1,0.0);
    _scn->cubeColors[2] = simd_make_float3(1.0,1.0,1.0);
    _scn->cubeColors[3] = simd_make_float3(0.75,0.53,1.0);
    _scn->cubeColors[4] = simd_make_float3(1.0,1.0,1.0);
    _scn->cubeColors[5] = simd_make_float3(1.0,0.75,0.75);

    _scn->decalPos = simd_make_float3(5, -2.5, 0);
    _scn->decalScale = simd_make_float3(3, 3, 3);
}

-(void)tick:(double_t)deltaTime
{
    const float speed = 0.1f;
    simd_float3 vel = simd_make_float3(0,0,0);
    
    if (_forward) vel += _playerTransform->forward;
    if (_back) vel -= _playerTransform->forward;
    if (_left) vel -= _playerTransform->right;
    if (_right) vel += _playerTransform->right;
    if (simd_length(vel) > 0) vel = simd_normalize(vel) * speed;
    [_playerTransform translate:vel];
    _scn->playerTransform = _playerTransform->matrix;

    Scene* nextScene = [[Scene alloc] initWithScene:_scn];
    _gif->tick(deltaTime);
    [_renderer updateDecalTexture:CGSizeMake(_gif->getWidth(), _gif->getHeight()) data:_gif->getCurrentFrame()];
    [_renderer enqeueScene:nextScene];
}

-(void)updateW:(bool)onoff
{
    _forward = onoff;
}

-(void)updateS:(bool)onoff
{
    _back = onoff;
}

-(void)updateA:(bool)onoff
{
    _left = onoff;
}

-(void)updateD:(bool)onoff
{
    _right = onoff;
}

-(bool)updateMouse:(CGPoint)mouseDelta
{    
    [_playerTransform rotateOnAxis:simd_make_float3(0,1,0) angle:mouseDelta.x*0.25];
    [_playerTransform rotateOnAxis:_playerTransform->right angle:mouseDelta.y*0.25];

    return true;
}

-(void)spray
{
    
}

@end
