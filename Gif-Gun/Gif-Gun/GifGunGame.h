//
//  GifGunGame.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 4/30/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Renderer;

@interface GifGunGame : NSObject

-(nonnull instancetype)initWithRenderer:(Renderer*)renderer;
-(void)tick:(double_t)deltaTime;
-(void)updateMouse:(NSPoint)point;
-(void)updateW:(bool)onoff;
-(void)updateS:(bool)onoff;
-(void)spray;
@end

NS_ASSUME_NONNULL_END
