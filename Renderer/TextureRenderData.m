//
//  TextureRenderData.m
//  BasicTexturing
//
//  This class is used as an element in a render array for a particular instance of a Tile,
//  Beam or Background object.  At minimum it includes position, size and a pointer to a Texture.
//  It may also include a pointer to a color filter Texture for belnding atop the Texture.
//
//  Created by Patrick Keith-Hynes on 12/1/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "TextureRenderData.h"

@import simd;
@import MetalKit;

@implementation TextureRenderData
    @synthesize renderTexture;
    @synthesize spectrumTexture;

    id<MTLTexture> __strong renderTexture;
    id<MTLTexture> __strong spectrumTexture;

@end
