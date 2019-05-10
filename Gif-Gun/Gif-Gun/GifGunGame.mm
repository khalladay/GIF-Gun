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
#define DEG2RAD 0.01745329251

@interface GifGunGame()
{
    Renderer* _renderer;
    Scene* _scn;
    quaternion_float _playerRotation;
    
    simd_float3 _playerBounds; //player is modelled as a cube collider
    
    CGPoint _lastMousePoint;
    CGPoint _mouseDelta;
    
    simd_float3 _playerPos;
    simd_float3 _playerRight;
    simd_float4 _playerForward;
        
    gif_read::StreamingCompressedGIF* _gifs;
    
    bool _gotFirstMousePoint;
    bool _forward;
    bool _back;
    float pitch;
    float yaw;
}

-(void)updatePlayerTransform;
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
        _playerRight = simd_make_float3(1,0,0);
        _playerForward = simd_make_float4(0,0,1,0);
        _playerPos = simd_make_float3(-4,1.5,0);
        _playerRotation = quaternion_identity();
        _gotFirstMousePoint = false;
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

    _scn->decalPos = simd_make_float3(10.5, -2.5, 0);
    _scn->decalScale = simd_make_float3(3, 3, 3);
    
    [self updatePlayerTransform];
}

-(void)tick:(double_t)deltaTime
{
    const float speed = 0.1f;
    simd_float3 vel = simd_make_float3(_playerForward.x *speed, _playerForward.y * speed, _playerForward.z * speed);
    
    if (_forward)_playerPos += vel;
    if (_back) _playerPos -=vel;
    [self updatePlayerTransform];

    Scene* nextScene = [[Scene alloc] initWithScene:_scn];
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


-(void)updatePlayerTransform
{
    simd_float4 front;
    
    front.x = cos(DEG2RAD*(pitch)) * cos(DEG2RAD*(yaw));
    front.y = sin(DEG2RAD*(pitch));
    front.z = cos(DEG2RAD*(pitch)) * sin(DEG2RAD*(yaw));
    front.w = 0;
    _playerForward = simd_normalize(front);
    _scn->playerTransform = matrix_look_at_left_hand(_playerPos, _playerPos + _playerForward.xyz, simd_make_float3(0,1,0));
}

-(void)updateMouse:(NSPoint)point
{
    if (!_gotFirstMousePoint)
    {
        _lastMousePoint = CGPointMake(point.x, point.y);
        _mouseDelta = CGPointMake(0, 0);
        _gotFirstMousePoint = true;
    }
    else
    {
        _mouseDelta = CGPointMake((_lastMousePoint.x - point.x) , (_lastMousePoint.y-point.y) );
        _lastMousePoint = CGPointMake(point.x, point.y);
        yaw += _mouseDelta.x;
        pitch += _mouseDelta.y;
    }
}

-(void)spray
{
    
}

@end
