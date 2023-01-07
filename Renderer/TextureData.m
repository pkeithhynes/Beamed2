//
//  TextureData.m
//  BasicTexturing
//
//  This class associates a Texture with a source file and is used for storage of loaded Textures.
//
//  Created by Patrick Keith-Hynes on 11/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "TextureData.h"

@import simd;
@import MetalKit;

@implementation TextureData
    @synthesize textureFilename;
    @synthesize texture;

    NSString *textureFilename;
    id<MTLTexture> __strong texture;

@end
