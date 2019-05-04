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
    
    NSEventMask eventMask = NSEventMaskKeyDown | NSEventMaskKeyUp;
    [NSEvent addLocalMonitorForEventsMatchingMask:eventMask handler:^NSEvent * _Nullable(NSEvent *event) {
        
        if ([[event characters] isEqualToString:@"w"])
        {
            [self->_game updateW:event.type==NSEventTypeKeyDown];
        }
        
        if ([[event characters] isEqualToString:@"s"])
        {
            [self->_game updateS:event.type==NSEventTypeKeyDown];
        }
        
        if ([[event characters] isEqualToString:@"e"])
        {
            [self->_game spray];
        }

        return event;
        
    }];
    
}

#pragma mark - MetalViewDelegate

- (void)mouseMoved:(NSEvent *)event
{
    NSPoint mousePoint = event.locationInWindow;
    mousePoint = [_view convertPoint:mousePoint fromView:nil];
    mousePoint = NSMakePoint(mousePoint.x, _view.bounds.size.height - mousePoint.y);
    [_game updateMouse:mousePoint];

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
