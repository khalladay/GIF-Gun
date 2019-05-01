//
//  LoadingThread.m
//  ThreadedMeshLoader
//
//  Created by Kyle Halladay on 2/24/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "LoadingThread.h"
#import <MetalKit/MetalKit.h>

@interface LoadingThread()
{
    NSMutableArray* _pendingMeshLoadRequests;
    NSLock* _queueLock;
    NSThread* _thread;
    
    MTKMeshBufferAllocator* _alloc;
    MDLVertexDescriptor* _vertexDesc;
};

-(void)loadingThreadMain;
-(NSURL*)nextMeshLoadRequest;

@end

@implementation LoadingThread

-(nonnull instancetype)initWithBufferAllocator:(MTKMeshBufferAllocator*)alloc andVertexDesc:(MDLVertexDescriptor*)vertexDesc
{
    
    if (self = [super init])
    {
        _vertexDesc = vertexDesc;
        _alloc = alloc;
        
        _pendingMeshLoadRequests = [NSMutableArray new];
        _queueLock = [NSLock new];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(loadingThreadMain) object:nil];
        [_thread start];
    }
    
    return self;
}

-(void)enqueueMeshRequest:(NSURL*)fileURL
{
    [_queueLock lock];
    [_pendingMeshLoadRequests addObject:fileURL];
    [_queueLock unlock];
}

-(NSURL*)nextMeshLoadRequest
{
    [_queueLock lock];
    NSURL* file = [_pendingMeshLoadRequests firstObject];
    if (file != nil) [_pendingMeshLoadRequests removeObjectAtIndex:0];
    [_queueLock unlock];
    return file;
}

-(void)loadingThreadMain
{
    while(true)
    {
        NSURL* nextFile = [self nextMeshLoadRequest];
        if (nextFile != nil)
        {
            MDLAsset* asset = [[MDLAsset alloc] initWithURL:nextFile vertexDescriptor:_vertexDesc bufferAllocator:_alloc];
            [self.delegate onMeshLoaded:asset];
        }
        
        [NSThread sleepForTimeInterval:0.05];
    }
}

@end
