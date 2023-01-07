//
//  TextureRenderData.h
//  BasicTexturing
//
//  This class is used as an element in a render array for a particular instance of a Tile,
//  Beam or Background object.  At minimum it includes position, size and a pointer to a Texture.
//
//  Created by Patrick Keith-Hynes on 12/1/20.
//  Copyright © 2020 Apple. All rights reserved.
//
@import MetalKit;
@class Tile;
@class Beam;

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "Tile.h"
#import "Beam.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface TextureRenderData : NSObject {
    @public
    // Storage used when handling a Tile
    vector_int2 textureGridPosition;
    enum eTileColors  tileColor;
    enum eTileShape tileShape;
    enum eTileAnimationContainers tileAnimationContainer;
    enum eTileAnimations tileAnimation;
    Tile *tile;                             // Pointer to a Tile instance
    
    // Used to indicate Jewel backgrounds which carry color
    BOOL isJewelBackground;
    
    // Storage used when handling a Beam
    vector_int2 textureStartGridPosition;
    vector_int2 textureEndGridPosition;

    enum eBeamColors  beamColor;
    Beam *beam;                            // Pointer to a Beam instance

    // These quantities control the display of the PRISM spectrum
    BOOL                    showSpectrum;
    NSUInteger            spectrumAnimationContainer;
    enum eObjectAngle        spectrumAngle;

    // Used to handle the angle of an arrow
    CGFloat arrowAngle;
    
    // Common storage
    vector_int2 texturePositionInPixels;
    vector_int2 textureDimensionsInPixels;
    enum eObjectAngle angle;
}

    @property id<MTLTexture>  renderTexture;
    @property id<MTLTexture>  spectrumTexture;


@end

NS_ASSUME_NONNULL_END
