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
    [_view becomeFirstResponder];
    _renderer = [[Renderer alloc] initWithView:_view];
    _game = [[GifGunGame alloc] initWithRenderer:_renderer];
    CGAssociateMouseAndMouseCursorPosition(false);
    CGDisplayMoveCursorToPoint(CGMainDisplayID(), CGPointMake([_view window].frame.origin.x + [_view window].frame.size.width*0.5, [_view window].frame.origin.y + [_view window].frame.size.height*0.5));
    [NSCursor hide];

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
        
        if ([[event characters] isEqualToString:@"a"])
        {
            [self->_game updateA:event.type==NSEventTypeKeyDown];
        }
        
        if ([[event characters] isEqualToString:@"d"])
        {
            [self->_game updateD:event.type==NSEventTypeKeyDown];
        }
        
        if ([[event characters] isEqualToString:@"e"])
        {
            [self->_game spray];
        }
        
        if ([[event characters] isEqualToString:@"0"])
        {
            [self->_renderer setRenderMode:Default];
        }

        if ([[event characters] isEqualToString:@"1"])
        {
            [self->_renderer setRenderMode:VisualizePositionBuffer];
        }

        return event;
        
    }];
    
}

#pragma mark - MetalViewDelegate

- (void)mouseMoved:(NSEvent *)event
{
    static bool first = false;
    if (first)
    {
        [_game updateMouse:CGPointMake(event.deltaX, event.deltaY)];
    }
    else
    {
        first = true;
    }
}

-(void)mouseExited:(NSEvent *)event
{

}

- (void)mouseDown:(NSEvent *)event
{
    [_game spray];
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
    [_game tick:0.016];
    [_renderer drawInView:view];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    [_renderer handleSizeChange:size];
}

@end
