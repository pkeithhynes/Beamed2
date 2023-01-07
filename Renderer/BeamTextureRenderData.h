//
//  BeamTextureRenderData.h
//  Beamed
//
//  This class is used as an element in a render array for a particular instance of a Beam.
//  Unlike Tile objects which occupy a particular position on the TilesGrid game grid (x, y), beams extend between
//  two or more tiles.  At every render pass an instance of this class is created for every pair of tile/grid-locations
//  which are connected by a beam.  The number of beams of each color (R, G, B) connecting these grid locations
//  is stored in the instance and is used by the Renderer to choose a display color.
//
//  The direction of a beam is not considered in the rendering process.  This means that the BeamTextureRenderData
//  instance at location (s, e) is the same identical object as the instance at location (e, s).
//
//  Created by Patrick Keith-Hynes on 12/24/20.
//  Copyright © 2020 Apple. All rights reserved.
//

@import MetalKit;
@class Tile;
@class Beam;
@class BMDAppDelegate;
@class Optics;

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "Tile.h"
#import "Beam.h"
#import "BMDAppDelegate.h"
#import "Optics.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface BeamTextureRenderData : NSObject {
    @public
    // Coordinates in BeamsGrid space
    // (x_bg, y_bg)
    vector_int2 textureBeamsGridPosition;
    enum eObjectAngle angle;
    
    // Storage used in TilesGrid space
    vector_int2    textureStartGridPosition;          // (xs_tg, ys_tg)
    vector_int2    textureEndGridPosition;            // (xe_tg, ye_tg)

    vector_int2    texturePositionInPixels;
    vector_int2    textureDimensionsInPixels;
    // Count of R, G and B beams
    vector_uint3    beamCountsByColor;
    Beam          *beam;
}

// Beam texture
@property id<MTLTexture>  beamRenderTexture;

@end

NS_ASSUME_NONNULL_END
