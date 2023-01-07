//
//  Beam.h
//  Beamed
//
//  Created by pkeithhynes on 7/14/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import "Definitions.h"
#import "BMDAppDelegate.h"
#import "Tile.h"
#import "Optics.h"
#import "TextureRenderData.h"
#import "BeamTextureRenderData.h"


@class BMDAppDelegate;
@class Optics;
@class Tile;
@class TextureRenderData;
@class BeamTextureRenderData;


API_AVAILABLE(ios(13.0))
@interface Beam : UIView 
{
@public
    vector_int2			beamStart;
    vector_int2			beamEnd;
	enum eBeamColors	beamColor;
	enum eObjectAngle	beamAngle;
	CGFloat				beamEnergy;
	Tile				*startTile;		// The beam starts here
	Tile				*endTile;		// Beam ends here
	BOOL				root;			// If YES then this is the root beam - very special!
    unsigned int		beamLevel;		// Root beam is beamLevel 0.
                                        // Each child beam has beamLevel that is one larger.
                                        // Beams can only be created if beamLevel < kNumberOfBeamLevels
    TextureRenderData      *textureRenderData;
@private
	CGFloat			animationInterval;
	enum eBeamAnimations	        currentAnimation;
	enum eBeamAnimationContainers		animationContainer;
	BOOL				beamVisible;
	CGFloat			beamScale;
}

- (Beam *)initWithGridParameters:(vector_int2)start
                         direction:(enum eObjectAngle)direction
                         visible:(BOOL)visible
                          energy:(CGFloat)energy
                          isRoot:(BOOL)isRoot
                           color:(enum eBeamColors)color
                       beamLevel:(int)level
                       startTile:(Tile *)startT
                         endTile:(Tile *)endT;
- (void)renderBeam:(NSMutableArray *)beamsRenderArray frameCounter:(uint16_t)animationFrame;
- (BOOL)checkIfBeamInteractsWithTile;
- (NSMutableDictionary *)checkIfBeamIntersectsGridPosition:(vector_int2)position;

@end
