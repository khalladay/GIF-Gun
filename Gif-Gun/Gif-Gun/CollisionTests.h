//
//  CollisionTests.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/14/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#ifndef CollisionTests_h
#define CollisionTests_h
#import "BoxCollider.h"
#import "Ray.h"
#import <SIMD/simd.h>

simd_float3 ray2aabb(Ray* r, BoxCollider* b);


#endif /* CollisionTests_h */
