//
//  shader_structs.h
//  Gif-Gun
//
//  Created by Kyle Halladay on 5/10/19.
//  Copyright © 2019 Kyle Halladay. All rights reserved.
//

#ifndef shader_structs_h
#define shader_structs_h

struct GlobalRenderData
{
    float nearClip;
    float farClip;
    
    metal::float4x4 projectionMatrix;
    metal::float4x4 inv_projectionMatrix;
    metal::float4x4 viewMatrix;
    metal::float4x4 inv_viewMatrix;
};


#endif /* shader_structs_h */
