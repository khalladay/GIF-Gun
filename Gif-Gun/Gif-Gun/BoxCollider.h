//
//  BoxCollider.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/12/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIMD/simd.h>
//to handle the spray, we're going to fire a ray into the world and hit box colliders (or sphere colliders I suppose,
//then generate a decal volume that intersects the hit point, pointed in the direction of the normal vector * -1

NS_ASSUME_NONNULL_BEGIN

@interface BoxCollider : NSObject
{
    @public
    simd_float3 min;
    simd_float3 max;
    simd_float3 size;
    simd_float3 center;
    
    simd_float4x4 model;
}

-(nonnull instancetype)initWithMin:(simd_float3)min andMax:(simd_float3)max;
-(nonnull instancetype)initWithSize:(simd_float3)size centeredAt:(simd_float3)center;
-(BOOL)doesIntersectBox:(BoxCollider*)box;
-(BOOL)isPointInside:(simd_float3)point;
@end

NS_ASSUME_NONNULL_END
