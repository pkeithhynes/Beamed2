//
//  Tile.h
//  Beamed
//
//  Created by pkeithhynes on 7/16/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//
//  Updated by pkeithhynes on 11/26/2020
//

#import "Definitions.h"
#import "BMDAppDelegate.h"
#import "BMDRenderer.h"
#import "Beam.h"
#import "Optics.h"
#include <AudioToolbox/AudioToolbox.h>


@class BMDAppDelegate;
@class Optics;
@class Beam;


API_AVAILABLE(ios(13.0))
@interface Tile : NSObject {
@public
    enum eTileShape        tileShape;
    
    // Current values
    enum eTileColors       tileColor;
    enum eObjectAngle      tileAngle;
    vector_int2          gridPosition;
    vector_int2          tilePositionInPixels;
    
    // Final values 
    enum eTileColors       finalTileColor;
    enum eObjectAngle      finalTileAngle;
    vector_int2          finalGridPosition;
    vector_int2          finalTilePositionInPixels;
    
    // Placed values
    enum eObjectAngle      placedTileAngle;
    vector_int2          placedGridPosition;
    vector_int2          placedTilePositionInPixels;

    // Inital values (used to support Tile motion)
    vector_int2          initialGridPosition;
    vector_int2          initialTilePositionInPixels;
    enum eObjectAngle      initialTileAngle;

    vector_int2          tileDimensionsInPixels;
    BOOL                hidden;
    BOOL                placed;                     // Means that the Tile was moved but not into a correct position
    BOOL                placedUsingHint;
    BOOL                placedManuallyMatchesHint;
    BOOL					fixed;
    BOOL                demoTile;
    BOOL                demoTileAtFinalGridPosition;
    uint                tag;     // Optional nonzero quantity unique to each game puzzle
                                // used to identify a particular Tile
    BOOL					energized;
    BOOL                    showEnergized;
    NSMutableArray			*incomingBeams[3];
    TextureRenderData      *textureRenderData;
    TextureRenderData      *jewelBackgroundtextureRenderData;
@private
    enum eTileAnimationContainers            animationContainer;        // The animation container currently in use
	enum eTileAnimations	currentAnimation;
    NSUInteger			animationFrame;			// Pointer to the current frame of the animation
	CGFloat				opacity;
	
	// These quantities support Tile motion
    enum eTileMotions		motionType;
    int                 motionPeriodInFrames;
    int                 motionRemainingTimeInFrames;
    CGFloat            dropDistanceInPixels;
    CGFloat            dropSpeedInPixelsPerFrame;
    CGFloat            dropAccelerationInPixelsPerFrameSquared;
	CGPoint				pivot;
	CGPoint				eccentricity;
	CGFloat				angularFrequency;
	CGFloat				motionRadius;
	CGFloat				initialAngle;
    
    // These quantities control the display of the PRISM spectrum
    BOOL                    showSpectrum;
    NSUInteger            spectrumAnimationContainer;
    enum eObjectAngle        spectrumAngle;
}

- (Tile *)initWithGridParameters:(Optics *)optics cx:(int)cx cy:(int)cy cz:(int)cz shape:(enum eTileShape)shape angle:(enum eObjectAngle)angle visible:(BOOL)visible color:(enum eTileColors)color fixed:(BOOL)fixed centerPositionInPixels:(vector_int2)center dimensionsInPixels:(vector_int2)dimensions;
- (TextureRenderData *)renderTile:(CGFloat)OPACITY paused:(BOOL)PAUSED lightSweep:(BOOL)lightSweep puzzleCompleted:(BOOL)puzzleCompleted puzzleCompletedCelebration:(BOOL)puzzleHasBeenCompletedCelebration;
- (TextureRenderData *)renderTileBackground;
- (void)updateTileEnergizedState;
- (void)setTileCoordinates:(CGFloat)px pixelY:(CGFloat)py;
- (void)snapTileToNewGridPosition:(vector_int2)position;
- (void)snapTileToNewGridPosition;
- (void)snapTileToPreviousGridPosition;
- (void)startTileMotionLinear:(vector_int2)initialPosition finalPosition:(vector_int2)finalPosition timeInFrames:(int)frames;
- (void)startTileMotionDrop:(vector_int2)initialPosition dropAcceleration:(CGFloat)g timeInFrames:(int)frames;
- (void)rotateTile;
- (void)changeTileColor;
- (void)lockInPlace;
- (void)tileIsInteractingWithBeam:(Beam *)beam direction:(enum eObjectAngle)direction color:(enum eBeamColors)beamColor;
- (BOOL)beamCanPassThroughTile:(Beam *)beam;

@end
