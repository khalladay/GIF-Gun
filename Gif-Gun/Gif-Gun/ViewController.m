//
//  ViewController.m
//  MetalTextureArrays
//
//  Created by Kyle Halladay on 3/1/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "ViewController.h"
#import "Renderer.h"
#import "GifGunGame.h"
#import "MetalView.h"

@interface ViewController ()
{
    MetalView* _view;
    Renderer* _renderer;
    GifGunGame* _game;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _view = (MetalView*)self.view;
    _view.delegate = self;
    _renderer = [[Renderer alloc] initWithView:_view];
    _game = [[GifGunGame alloc] initWithRenderer:_renderer];
    
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                                options:NSTrackingMouseMoved | NSTrackingInVisibleRect | NSTrackingActiveAlways
                                                                  owner:self
                                                               userInfo:nil];
    [self.view addTrackingArea:trackingArea];
    
    NSEventMask eventMask = NSEventMaskKeyDown | NSEventMaskKeyUp | NSEventMaskFlagsChanged | NSEventTypeScrollWheel;
    [NSEvent addLocalMonitorForEventsMatchingMask:eventMask handler:^NSEvent * _Nullable(NSEvent *event) {
        
        if (event.type == NSEventTypeKeyDown)
        {
            if ([[event characters] isEqualToString:@"1"])
            {
            }
        }
        
        return event;
        
    }];
    
}

#pragma mark - MetalViewDelegate

- (void)mouseMoved:(NSEvent *)event
{
}

- (void)mouseDown:(NSEvent *)event
{
}

- (void)mouseUp:(NSEvent *)event
{
}

- (void)mouseDragged:(NSEvent *)event
{
}

- (void)scrollWheel:(NSEvent *)event
{
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(nonnull MTKView *)view
{
    [_game tick:0.16];
    [_renderer drawInView:view];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    [_renderer handleSizeChange:size];
}

@end
