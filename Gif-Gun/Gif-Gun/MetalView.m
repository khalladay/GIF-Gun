//
//  MetalView.m
//  MetalTextureArrays
//
//  Created by Kyle Halladay on 3/2/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "MetalView.h"

@interface MetalView()
-(void)initView;
@end

@implementation MetalView

- (nonnull instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self initView];
    }
    return self;
}

- (nonnull instancetype)init
{
    if (self = [super init])
    {
        [self initView];
    }
    
    return self;
}

- (nonnull instancetype)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        [self initView];
    }
    return self;
}

- (nonnull instancetype)initWithFrame:(CGRect)frameRect device:(id<MTLDevice>)device
{
    if (self = [super initWithFrame:frameRect device:device])
    {
        [self initView];
    }
    return self;
}

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)keyDown:(NSEvent *)event
{
    
}

- (void)initView
{
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    self.sampleCount = 1;
    
    NSArray* mtlDevices = MTLCopyAllDevices();
    CGDirectDisplayID viewDisplayID = (CGDirectDisplayID) [self.window.screen.deviceDescription[@"NSScreenNumber"] unsignedIntegerValue];
    
    self.device = CGDirectDisplayCopyCurrentMetalDevice(viewDisplayID);
    
    for (const id<MTLDevice> device in mtlDevices)
    {
        if (!device.isLowPower && !device.isRemovable)
        {
            self.device = device;
        }
    }
}




@end
