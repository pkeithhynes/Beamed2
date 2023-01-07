//
//  BeamTextureRenderData.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 12/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "BeamTextureRenderData.h"

@import simd;
@import MetalKit;

@implementation BeamTextureRenderData
    @synthesize beamRenderTexture;

    id<MTLTexture> __strong beamRenderTexture;

- (BeamTextureRenderData *)init {
    if (self = [super init]) {
        // Initialize
        textureBeamsGridPosition.x = 0;
        textureBeamsGridPosition.y = 0;
        textureStartGridPosition.x = 0;
        textureStartGridPosition.y = 0;
        textureEndGridPosition.x = 0;
        textureEndGridPosition.y = 0;
        texturePositionInPixels.x = 0;
        texturePositionInPixels.y = 0;
        textureDimensionsInPixels.x = 0;
        textureDimensionsInPixels.y = 0;
        beamCountsByColor[0] = 0;
        beamCountsByColor[1] = 0;
        beamCountsByColor[2] = 0;
        beam = nil;
        beamRenderTexture = nil;
    }
    return self;
}

@end
