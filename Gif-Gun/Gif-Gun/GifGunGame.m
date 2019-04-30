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
}

@end

@implementation GifGunGame

-(nonnull instancetype)initWithRenderer:(Renderer*)renderer
{
    srand((unsigned int)time(NULL));
    if (self = [super init])
    {
        NSAssert(renderer, @"initializing SphereGame with nil renderer");
        _renderer = renderer;
       
    }
    
    return self;
}

-(void)tick:(double_t)deltaTime
{
    
}

@end
