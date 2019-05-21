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
#import "BoxCollider.h"
#import "Ray.h"
#import "DebugDrawManager.h"
#import "CollisionTests.h"

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
    BoxCollider* _playerBox;
    BoxCollider* _candidateBox;
    
    Transform* _decalTransform;
    NSMutableArray* _boxes;
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
        [_playerTransform setPosition:simd_make_float3(0, 0, 0)];
        [_playerTransform rotateOnAxis:simd_make_float3(0, 1, 0) angle:45.0];
        _boxes = [NSMutableArray new];
        _playerBox = [[BoxCollider alloc] initWithMin:simd_make_float3(-1,-1, -1) andMax:simd_make_float3(1, 1, 1)];
        _candidateBox = [[BoxCollider alloc] initWithMin:simd_make_float3(-1,-1, -1) andMax:simd_make_float3(1, 1, 1)];
        
        _decalTransform = [Transform new];

        [_decalTransform setPosition:simd_make_float3(10, -2.5, -10.5 * 0)];
        [_decalTransform setScale:simd_make_float3(3, 3, 3)];
        
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
    
    _scn->decalTransform = _decalTransform->matrix;

    
    for (int i = 0; i < 6; ++i)
    {
        [_boxes addObject:[[BoxCollider alloc] initWithSize:_scn->cubeScales[i] centeredAt:_scn->cubePositions[i]]];
    }
    [[DebugDrawManager sharedInstance] registerBox:[[BoxCollider alloc] initWithSize:_decalTransform->scale centeredAt:_decalTransform->position]];
    
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
    
    [_candidateBox recenterAtPoint:_playerTransform->position + vel];
    
    bool hitsWall = false;
    for (int i = 0; i < 6; ++i)
    {
        if ([_boxes[i] intersectsBox:_candidateBox])
        {
            hitsWall = true;
        }
    }
    
    if (!hitsWall)
    {
        [_playerTransform translate:vel];
    }
    
    
    _scn->playerTransform = _playerTransform->matrix;
    _scn->decalTransform = _decalTransform->matrix;
    
    
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
    Ray *r = [[Ray alloc] initWithOrigin:_playerTransform->position andDirection:_playerTransform->forward];
    for (int i = 0; i < 6; ++i)
    {
        BoxCollider* b = _boxes[i];

        //ray/box collision test https://tavianator.com/fast-branchless-raybounding-box-intersections/
        const int NO_HIT = -1;
        
        float t[10];
        t[1] = (b->min.x - r->origin.x)/r->direction.x;
        t[2] = (b->max.x - r->origin.x)/r->direction.x;
        t[3] = (b->min.y - r->origin.y)/r->direction.y;
        t[4] = (b->max.y - r->origin.y)/r->direction.y;
        t[5] = (b->min.z - r->origin.z)/r->direction.z;
        t[6] = (b->max.z - r->origin.z)/r->direction.z;
        t[7] = fmax(fmax(fmin(t[1], t[2]), fmin(t[3], t[4])), fmin(t[5], t[6]));
        t[8] = fmin(fmin(fmax(t[1], t[2]), fmax(t[3], t[4])), fmax(t[5], t[6]));
        t[9] = (t[8] < 0 || t[7] > t[8]) ? NO_HIT : t[7];
        
        if (t[9] != NO_HIT) //in this scene, a ray should always hit
        {
            r->len = t[9];
            [[DebugDrawManager sharedInstance] registerRay:r];
            simd_float3 hitPoint = r->origin + r->direction*t[9];
            simd_float3 normalAtPoint = [b normalAtSurfacePoint:hitPoint];
            NSLog(@"Normal at point: %f %f %f",normalAtPoint.x, normalAtPoint.y, normalAtPoint.z);
            [_decalTransform setPosition:hitPoint + r->direction * 1.5];
            
            [_decalTransform lookAt:_decalTransform->position - normalAtPoint*5];
            
            float d = simd_dot(normalAtPoint, simd_make_float3(0, 1, 0));
            if (d > 0.999 || d < -0.999)
            {
                [_decalTransform lookAt:_decalTransform->position - normalAtPoint*5 withUpVector:_playerTransform->up];

            }
            
            
        }
    }

}

@end
