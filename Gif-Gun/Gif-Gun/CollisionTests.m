//
//  CollisionTests.m
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/14/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#import "CollisionTests.h"

simd_float3 ray2aabb(Ray* r, BoxCollider* b)
{
    if ([b containsPoint:r->origin])
    {
        return r->origin; //not sure what to do in this case in terms of collision point
    }
    
    float t[10];
    t[1] = (b->min.x - r->origin.x)/r->direction.x;
    t[2] = (b->max.x - r->origin.x)/r->direction.x;
    t[3] = (b->min.y - r->origin.y)/r->direction.y;
    t[4] = (b->max.y - r->origin.y)/r->direction.y;
    t[5] = (b->min.z - r->origin.z)/r->direction.z;
    t[6] = (b->max.z - r->origin.z)/r->direction.z;
    t[7] = fmax(fmax(fmin(t[1], t[2]), fmin(t[3], t[4])), fmin(t[5], t[6]));
    t[8] = fmin(fmin(fmax(t[1], t[2]), fmax(t[3], t[4])), fmax(t[5], t[6]));
    t[9] = (t[8] < 0 || t[7] > t[8]) ? -1 : t[7];
    
    if (t[9] == -1) return simd_make_float3(0,0,0);
    return r->origin + r->direction * t[9];
}
