//
//  LoadingThread.h
//  ThreadedMeshLoader
//
//  Created by Kyle Halladay on 2/24/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>
#import <ModelIO/ModelIO.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LoadingThreadDelegate;

@interface LoadingThread : NSObject
{
}

-(nonnull instancetype)initWithBufferAllocator:(MTKMeshBufferAllocator*)alloc andVertexDesc:(MDLVertexDescriptor*)vertexDesc;
-(void)enqueueMeshRequest:(NSURL*)fileURL;

@property(nonatomic, assign) id<LoadingThreadDelegate> delegate;

@end

@protocol LoadingThreadDelegate
-(void)onMeshLoaded:(MDLAsset*)asset;
@end

NS_ASSUME_NONNULL_END
