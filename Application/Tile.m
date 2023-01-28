//
//  Tile.m
//  Beamed
//
//  Created by pkeithhynes on 7/16/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import "Tile.h"
#import "TextureData.h"
#import "TextureRenderData.h"
#import "BMDAppDelegate.h"
#import "BMDRenderer.h"

API_AVAILABLE(ios(13.0))
@implementation Tile


- (Tile *)initWithGridParameters:(Optics *)optics cx:(int)cx cy:(int)cy cz:(int)cz shape:(enum eTileShape)shape angle:(enum eObjectAngle)angle visible:(BOOL)visible color:(enum eTileColors)color fixed:(BOOL)isFixed centerPositionInPixels:(vector_int2)center dimensionsInPixels:(vector_int2)dimensions {
    optics = optics;
    gridPosition.x = cx;
    gridPosition.y = cy;
    tilePositionInPixels = center;
    tileDimensionsInPixels = dimensions;
    energized = NO;
    placedUsingHint = NO;
    placedManuallyMatchesHint = NO;
    demoTile = NO;
    demoTileAtFinalGridPosition = NO;
    animationFrame = 0;
    fixed = isFixed;
    tileShape = shape;
    tileAngle = angle;
    tileColor = color;
    motionType = MOTION_NONE;
    textureRenderData = [[TextureRenderData alloc] init];
    jewelBackgroundtextureRenderData = [[TextureRenderData alloc] init];
    
    for (int ii=(int)BEAM_RED; ii<=(int)BEAM_BLUE; ii++) {
        incomingBeams[ii] = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    // Set animationContainer based upon eTileShape
    switch (tileShape) {
        case CIRCLE:
            animationContainer = TILE_AC_GLOWWHITE_CIRCLE;
            break;
        case BEAMSPLITTER:
            animationContainer = TILE_AC_BEAMSPLITTER;
            break;
        case MIRROR:
            animationContainer = TILE_AC_MIRROR;
            break;
        case PRISM:
            animationContainer = TILE_AC_PRISM;
            break;
        case JEWEL:
            animationContainer = TILE_AC_JEWEL;
            break;
        case LASER:
            animationContainer = TILE_AC_LASER;
            break;
        case RECTANGLE:
        default:
            animationContainer = TILE_AC_GLOWWHITE_RECTANGLE;
            break;
    }
    currentAnimation = TILE_A_WAITING;
    animationFrame = 0;
    return self;
}

- (void)snapTileToPreviousGridPosition {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    tilePositionInPixels = [optics gridPositionToIntPixelPosition:gridPosition];
    [self setTileCoordinates:tilePositionInPixels.x pixelY:tilePositionInPixels.y];
}

- (void)snapTileToPreviousGridPosition2 {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    tilePositionInPixels.x = gridPosition.x * optics->_squareTileSideLengthInPixels + optics->_tileHorizontalOffsetInPixels;
    tilePositionInPixels.y = gridPosition.y * optics->_squareTileSideLengthInPixels + optics->_tileVerticalOffsetInPixels;
    [self setTileCoordinates:tilePositionInPixels.x pixelY:tilePositionInPixels.y];
}

- (void)snapTileToNewGridPosition {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    gridPosition.x = optics->gridTouchGestures.gridPosition.x;
    gridPosition.y = optics->gridTouchGestures.gridPosition.y;
//    finalGridPosition.x = optics->gridTouchGestures.gridPosition.x;
//    finalGridPosition.y = optics->gridTouchGestures.gridPosition.y;
    placedGridPosition.x = optics->gridTouchGestures.gridPosition.x;
    placedGridPosition.y = optics->gridTouchGestures.gridPosition.y;
    tilePositionInPixels = [optics gridPositionToIntPixelPosition:gridPosition];
    [self setTileCoordinates:tilePositionInPixels.x pixelY:tilePositionInPixels.y];
}

//- (void)snapTileToNewGridPosition {
//    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
//    Optics *optics = appDelegate->optics;
//    gridPosition.x = optics->gridTouchGestures.gridPosition.x;
//    gridPosition.y = optics->gridTouchGestures.gridPosition.y;
//    tilePositionInPixels = [optics gridPositionToIntPixelPosition:gridPosition];
//    [self setTileCoordinates:tilePositionInPixels.x pixelY:tilePositionInPixels.y];
//}

- (void)snapTileToNewGridPosition:(vector_int2)position {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    gridPosition = position;
    tilePositionInPixels = [optics gridPositionToIntPixelPosition:gridPosition];
    [self setTileCoordinates:tilePositionInPixels.x pixelY:tilePositionInPixels.y];
}

- (void)snapTileToNewGridPosition2 {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    gridPosition.x = optics->gridTouchGestures.gridPosition.x;
    gridPosition.y = optics->gridTouchGestures.gridPosition.y;
    tilePositionInPixels.x = gridPosition.x * optics->_squareTileSideLengthInPixels + optics->_tileHorizontalOffsetInPixels;
    tilePositionInPixels.y = gridPosition.y * optics->_squareTileSideLengthInPixels + optics->_tileVerticalOffsetInPixels;
}

- (void)snapTileToNewGridPosition2:(vector_int2)position {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    gridPosition = position;
    //    gridPosition.x = optics->gridTouchGestures.gridPosition.x;
    //    gridPosition.y = optics->gridTouchGestures.gridPosition.y;
    tilePositionInPixels.x = gridPosition.x * optics->_squareTileSideLengthInPixels + optics->_tileHorizontalOffsetInPixels;
    tilePositionInPixels.y = gridPosition.y * optics->_squareTileSideLengthInPixels + optics->_tileVerticalOffsetInPixels;
}

- (void)setTileCoordinates:(CGFloat)px pixelY:(CGFloat)py {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    tilePositionInPixels.x = px;
    tilePositionInPixels.y = py;
    
    if (optics->gridTouchGestures.gridPosition.x != optics->gridTouchGestures.previousGridPosition.x ||
        optics->gridTouchGestures.gridPosition.y != optics->gridTouchGestures.previousGridPosition.y) {
        for (int ii=0; ii<3; ii++) {
            [optics resetAllBeams:ii];
        }
    }
}

- (BOOL)tileColorMatchesBeamColor:(Beam *)beam {
    BOOL retVal = NO;
    switch (tileColor) {
        case COLOR_RED:
            if (beam->beamColor == BEAM_RED) {
                retVal = YES;
            }
            break;
        case COLOR_GREEN:
            if (beam->beamColor == BEAM_GREEN) {
                retVal = YES;
            }
            break;
        case COLOR_BLUE:
            if (beam->beamColor == BEAM_BLUE) {
                retVal = YES;
            }
            break;
        case COLOR_YELLOW:
            if (beam->beamColor == BEAM_GREEN || beam->beamColor == BEAM_RED) {
                retVal = YES;
            }
            break;
        case COLOR_MAGENTA:
            if (beam->beamColor == BEAM_BLUE || beam->beamColor == BEAM_RED) {
                retVal = YES;
            }
            break;
        case COLOR_CYAN:
            if (beam->beamColor == BEAM_GREEN || beam->beamColor == BEAM_BLUE) {
                retVal = YES;
            }
            break;
        case COLOR_WHITE:
            retVal = YES;
            break;
        default:
            break;
    }
    return retVal;
}

- (void)lockInPlace {
    placedManuallyMatchesHint = YES;
    fixed = YES;
}

- (void)tileIsInteractingWithBeam:(Beam *)beam direction:(enum eObjectAngle)direction color:(enum eBeamColors)beamColor {
    Beam *myBeam;
    int color = (int)beamColor;
    vector_int2 beam_start;
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    // First check to see if the tile already knows about this beam
    //
    //		- and -
    //
    // We do not have too many levels of beams
    if (![incomingBeams[color] containsObject:beam] && beam->beamLevel<kNumberOfBeamLevels) {
        // Play a laser sound
//        if (!appDelegate->laserSoundCurrentlyPlaying){
//            [appDelegate playLaserSound];
//        }
        switch (tileShape) {
            case CIRCLE:			// These tiles block the beam so add the beam to the incomingBeams array but then do nothing
            case JEWEL:
                [incomingBeams[color] addObject:beam];
                break;
            case RECTANGLE:
                [incomingBeams[color] addObject:beam];
                // If tileColor = COLOR_OPAQUE then do not propogate any beams
                // - and -
                // Only propogate beams whose color matches one of the RECTANGLE colors.
                // PURPLE tile passes RED and BLUE beams but not GREEN beam
                if (tileColor!=COLOR_OPAQUE && [self tileColorMatchesBeamColor:beam]) {
                    beam_start.x = gridPosition.x;
                    beam_start.y = gridPosition.y;
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:beam->beamAngle
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                break;
            case PRISM:
                [incomingBeams[color] addObject:beam];
                beam_start.x = gridPosition.x;
                beam_start.y = gridPosition.y;
                if (tileAngle == (direction + 2) % 8) {
                    showSpectrum = YES;
                    spectrumAngle = (beam->beamAngle) %8 ;
                    spectrumAnimationContainer = TILE_AC_SPECTRUML;
                }
                else if (tileAngle == (direction - 2) % 8) {
                    showSpectrum = YES;
                    spectrumAngle = (beam->beamAngle) % 8;
                    spectrumAnimationContainer = TILE_AC_SPECTRUMR;
                }
                else {
                    showSpectrum = NO;
                }
                // Different colored beams bend differently
                myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                    direction:optics->prismRefractionArray[color][direction][tileAngle]
                                                      visible:YES
                                                       energy:1.0
                                                       isRoot:NO
                                                        color:color
                                                    beamLevel:(beam->beamLevel)+1
                                                    startTile:self endTile:nil];
                [optics putOpticsBeam:color beam:myBeam];
                break;
            case BEAMSPLITTER:
                [incomingBeams[color] addObject:beam];
                beam_start.x = gridPosition.x;
                beam_start.y = gridPosition.y;
                // Prism reflects at right angles only
                if ( direction == (tileAngle + 1) % 8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction + 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                else if ( direction == (tileAngle - 1) % 8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction - 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                else if ( direction == (tileAngle + 3) % 8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction - 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                else if ( direction == (tileAngle - 3) % 8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction + 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                
                // The prism adds one or more pass-through beams
                if (direction==(tileAngle + 1) % 8 || direction==(tileAngle - 1) % 8 || direction==(tileAngle + 3) % 8 || direction==(tileAngle - 3) % 8) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:beam->beamAngle
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    if (myBeam->beamStart.x != myBeam->beamEnd.x ||
                        myBeam->beamStart.y != myBeam->beamEnd.y){
                        [optics putOpticsBeam:color beam:myBeam];
                    }
                }
                else if ((int)direction==(int)tileAngle || (int)direction==((int)tileAngle+4)%8 ||
                         (int)direction==((int)tileAngle-6)%8 || (int)direction==((int)tileAngle+6)%8 ||
                         (int)direction==((int)tileAngle-2)%8 || (int)direction==((int)tileAngle+2)%8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:beam->beamAngle
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    if (myBeam->beamStart.x != myBeam->beamEnd.x ||
                        myBeam->beamStart.y != myBeam->beamEnd.y){
                        [optics putOpticsBeam:color beam:myBeam];
                    }
                }
                break;
            case MIRROR:
                [incomingBeams[color] addObject:beam];
                beam_start.x = gridPosition.x;
                beam_start.y = gridPosition.y;
                if ( ((int)tileAngle == (int)direction) || ( (tileAngle+4)%8 == direction) ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction + 4) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                else if ( direction == (tileAngle+1)%8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction + 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                else if ( direction == (tileAngle-1)%8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction - 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                else if ( direction == (tileAngle+3)%8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction - 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                else if ( direction == (tileAngle-3)%8 ) {
                    myBeam = [[Beam alloc] initWithGridParameters:beam_start
                                                        direction:(direction + 2) % 8
                                                          visible:YES
                                                           energy:1.0
                                                           isRoot:NO
                                                            color:color
                                                        beamLevel:(beam->beamLevel)+1
                                                        startTile:self endTile:nil];
                    [optics putOpticsBeam:color beam:myBeam];
                }
                break;
            default:
                break;
        }
    }
}

- (void)changeTileColor {
    if (tileShape == JEWEL) {
        if (++tileColor > COLOR_WHITE) {
            tileColor = COLOR_RED;
        }
    }
    else if (tileShape == RECTANGLE) {
        if (++tileColor > COLOR_OPAQUE) {
            tileColor = COLOR_RED;
        }
    }
    else {
        DLog("Error changeTileColor: eTileShape = %d\n", tileShape);
    }
}

- (void)rotateTile {
    //	BOOL resetBeams = NO;
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    int angle = --tileAngle;
    if (angle < 0) {
        tileAngle = ANGLE315;
    }
    // When in the editor we are setting the finalTileAngle
    if ([appDelegate editModeIsEnabled]){
        finalTileAngle = tileAngle;
        placedTileAngle = tileAngle;
    }
    
    for (int ii=0; ii<3; ii++) {
        [optics resetAllBeams:ii];
    }
}

// When we have an energized jewel use this method to draw a fixed jewel background, then animate on top.
- (TextureRenderData *)renderTileBackground {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *tileTextureDataArray = appDelegate.tileAnimationContainers;
    
    TextureData *textureData;
    switch(tileShape){
        case JEWEL:{
            textureData = [appDelegate.jewelTextures objectAtIndex:tileColor];
            break;
        }
        case PRISM:{
            textureData = [[[[tileTextureDataArray objectAtIndex:TILE_AC_PRISM] objectAtIndex:ANGLE0] objectAtIndex:TILE_A_STATIC] objectAtIndex:0];
            break;
        }
        case BEAMSPLITTER:
        default:{
            textureData = [[[[tileTextureDataArray objectAtIndex:TILE_AC_BEAMSPLITTER] objectAtIndex:ANGLE0] objectAtIndex:TILE_A_STATIC] objectAtIndex:0];
            break;
        }
    }
    jewelBackgroundtextureRenderData.renderTexture = textureData.texture;
    if (tileShape == JEWEL){
        jewelBackgroundtextureRenderData->textureDimensionsInPixels.x = 0.8*tileDimensionsInPixels.x;
        jewelBackgroundtextureRenderData->textureDimensionsInPixels.y = 0.8*tileDimensionsInPixels.y;
        jewelBackgroundtextureRenderData->texturePositionInPixels.x = tilePositionInPixels.x + 0.125*jewelBackgroundtextureRenderData->textureDimensionsInPixels.x;
        jewelBackgroundtextureRenderData->texturePositionInPixels.y = tilePositionInPixels.y + 0.125*jewelBackgroundtextureRenderData->textureDimensionsInPixels.y;
    }
    else {
        jewelBackgroundtextureRenderData->texturePositionInPixels.x = (int)tilePositionInPixels.x;
        jewelBackgroundtextureRenderData->texturePositionInPixels.y = (int)tilePositionInPixels.y;
        jewelBackgroundtextureRenderData->textureDimensionsInPixels = tileDimensionsInPixels;
    }
    jewelBackgroundtextureRenderData->tileShape = tileShape;
    jewelBackgroundtextureRenderData->tileColor = tileColor;
    jewelBackgroundtextureRenderData->angle = tileAngle;
    jewelBackgroundtextureRenderData->isJewelBackground = YES;
    return jewelBackgroundtextureRenderData;
}

- (void)updateTileEnergizedState {
    // Is a JEWEL or a RECTANGLE energized?
    energized = NO;
    
    // Determine the overall color of the incoming beams (if any)
    //
    // Calculate the sum of red, green and blue components in all incoming beams
    //
    int red=0, green=0, blue=0;
    for (int ii=BEAM_RED; ii<=BEAM_BLUE; ii++) {
        NSEnumerator *beamEnum = [incomingBeams[ii] objectEnumerator];
        Beam *aBeam;
        while (aBeam = [beamEnum nextObject]) {
            if (ii == BEAM_RED) {
                red++;
            }
            else if (ii == BEAM_GREEN) {
                green++;
            }
            else {
                blue++;
            }
        }
    }
    
    //
    // Calculate the combined beam color
    //
    enum eTileColors combinedBeamColor = 0;
    if (red>0 || green>0 || blue>0) {
        
        while (red>1 || green>1 || blue>1) {
            if (red>1) {
                red--;
            }
            if (green>1) {
                green--;
            }
            if (blue>1) {
                blue--;
            }
        }
        
        // Now map to a supported color
        if (red==0 && green==0 && blue==1) {
            combinedBeamColor = COLOR_BLUE;
        }
        else if (red==0 && green==1 && blue==0) {
            combinedBeamColor = COLOR_GREEN;
        }
        else if (red==1 && green==0 && blue==0) {
            combinedBeamColor = COLOR_RED;
        }
        else if (red==0 && green==1 && blue==1) {
            combinedBeamColor = COLOR_CYAN;
        }
        else if (red==1 && green==0 && blue==1) {
            combinedBeamColor = COLOR_MAGENTA;
        }
        else if (red==1 && green==1 && blue==0) {
            combinedBeamColor = COLOR_YELLOW;
        }
        else if (red==1 && green==1 && blue==1) {
            combinedBeamColor = COLOR_WHITE;
        }
        
        // combinedBeamColor now contains the effective color of the incoming beam to the tile
        if (tileShape==JEWEL) {
            // Does the combined beam color match the jewel coler?
            if (combinedBeamColor == tileColor) {
                energized = YES;
                currentAnimation = TILE_A_ENERGIZED;
            }
            else if (!showEnergized){
                energized = NO;
                if (currentAnimation != TILE_A_LIGHTSWEEP) {
                    currentAnimation = TILE_A_WAITING;
                    animationFrame = 0;
                }
            }
        }
        else if (tileShape==RECTANGLE) {
            if ((red>0 || green>0 || blue>0) && tileColor==COLOR_WHITE) {
                energized = YES;
                currentAnimation = TILE_A_ENERGIZED;
            }
            else if (red>0 && (tileColor==COLOR_RED || tileColor==COLOR_MAGENTA || tileColor==COLOR_YELLOW)) {
                energized = YES;
                currentAnimation = TILE_A_ENERGIZED;
            }
            else if (green>0 && (tileColor==COLOR_GREEN || tileColor==COLOR_YELLOW || tileColor==COLOR_CYAN)) {
                energized = YES;
                currentAnimation = TILE_A_ENERGIZED;
            }
            else if (blue>0 && (tileColor==COLOR_BLUE || tileColor==COLOR_MAGENTA || tileColor==COLOR_CYAN)) {
                energized = YES;
                currentAnimation = TILE_A_ENERGIZED;
            }
            else {
                energized = NO;
                currentAnimation = TILE_A_WAITING;
                animationFrame = 0;
            }
        }
    }
    else if (currentAnimation == TILE_A_LIGHTSWEEP) {
        energized = NO;
        showSpectrum = NO;
    }
    else if (!showEnergized){
        energized = NO;
        showSpectrum = NO;
        currentAnimation = TILE_A_WAITING;
        animationFrame = 0;
    }
}

- (TextureRenderData *)renderTile:(CGFloat)OPACITY paused:(BOOL)PAUSED lightSweep:(BOOL)lightSweep puzzleCompleted:(BOOL)puzzleCompleted puzzleCompletedCelebration:(BOOL)puzzleHasBeenCompletedCelebration
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    //    Optics *optics = appDelegate->optics;
    NSMutableArray *tileTextureDataArray = appDelegate.tileAnimationContainers;
    // Set up appropriate animation container based upon shape
    switch(tileShape) {
        case RECTANGLE:
            animationContainer = TILE_AC_GLOWWHITE_RECTANGLE;
            break;
        case CIRCLE:
            animationContainer = TILE_AC_GLOWWHITE_CIRCLE;
            break;
        case BEAMSPLITTER:
            animationContainer = TILE_AC_BEAMSPLITTER;
            break;
        case MIRROR:
            animationContainer = TILE_AC_MIRROR;
            break;
        case PRISM:
            animationContainer = TILE_AC_PRISM;
            break;
        case JEWEL:
            animationContainer = TILE_AC_JEWEL;
            break;
        case LASER:
            animationContainer = TILE_AC_LASER;
            break;
        default:
            DLog("Unknown tileShape %d\n", tileShape);
    }
    
    // Update the energized BOOL based on the overall color of the Beams crossing the Tile grid location
    [self updateTileEnergizedState];
    
    
    // Handle RECTANGLEs
    if (tileShape == RECTANGLE) {
        if (tileColor == COLOR_OPAQUE) {
            currentAnimation = TILE_A_STATIC;
            animationFrame = 0;
        }
        else if (!energized) {
            currentAnimation = TILE_A_WAITING;
            animationFrame = 0;
        }
    }
    
    // Handle light sweeps
    if (tileShape == LASER || tileShape == BEAMSPLITTER || tileShape == PRISM || (tileShape==JEWEL && energized==NO)) {
        if (lightSweep) {
            currentAnimation = TILE_A_LIGHTSWEEP;
        } else {
            currentAnimation = TILE_A_WAITING;
        }
    }
    
    // Handle showEnergized
    if (tileShape==JEWEL && showEnergized==YES){
        currentAnimation = TILE_A_ENERGIZED;
    }
    
    // Increment animationFrame, wrapping back to 0 if last animation
    NSMutableArray *frameArray = [[[tileTextureDataArray objectAtIndex:animationContainer] objectAtIndex:ANGLE0] objectAtIndex:currentAnimation];
    animationFrame++;
    if (animationFrame >= [frameArray count])
        animationFrame = 0;
    
    // Animated Jewels have staggered animations
    TextureData *textureData;
    // This renders just the particle effect on top of the Jewel.
    // The Jewel itself is rendered by the renderTileBackground method
    if ((tileShape == JEWEL && energized) ||
        (tileShape == JEWEL && showEnergized)) {
        switch (tileColor){
            case COLOR_RED:{
                textureData = [frameArray objectAtIndex:animationFrame];
                break;
            }
            case COLOR_GREEN:{
                textureData = [frameArray objectAtIndex:(animationFrame + 4) % [frameArray count]];
                break;
            }
            case COLOR_BLUE:{
                textureData = [frameArray objectAtIndex:(animationFrame + 8) % [frameArray count]];
                break;
            }
            case COLOR_YELLOW:{
                textureData = [frameArray objectAtIndex:(animationFrame + 12) % [frameArray count]];
                break;
            }
            case COLOR_MAGENTA:{
                textureData = [frameArray objectAtIndex:(animationFrame + 16) % [frameArray count]];
                break;
            }
            case COLOR_CYAN:{
                textureData = [frameArray objectAtIndex:(animationFrame + 20) % [frameArray count]];
                break;
            }
            case COLOR_WHITE:
            default:{
                textureData = [frameArray objectAtIndex:(animationFrame + 24) % [frameArray count]];
                break;
            }
        }
        textureRenderData.renderTexture = textureData.texture;
    }
    else if (tileShape != JEWEL) {
        textureData = [frameArray objectAtIndex:animationFrame];
        textureRenderData.renderTexture = textureData.texture;
    }

    if (tileShape == PRISM && textureRenderData->showSpectrum){
        textureData = [[[[tileTextureDataArray objectAtIndex:textureRenderData->spectrumAnimationContainer] objectAtIndex:ANGLE0] objectAtIndex:0] objectAtIndex:0];
        textureRenderData.spectrumTexture = textureData.texture;
    }
    
    switch(motionType){
        case MOTION_LINEAR:{
            [self updatePixelPositionOfMovingTile];
            break;
        }
        case MOTION_DROP:{
            [self updatePixelPositionOfDroppingTile];
            break;
        }
        default:{
            break;
        }
    }
    //    if (motionType != MOTION_NONE){
    //        [self updatePixelPositionOfMovingTile];
    //    }
    
    textureRenderData->textureGridPosition = gridPosition;
    textureRenderData->texturePositionInPixels = tilePositionInPixels;
    textureRenderData->textureDimensionsInPixels = tileDimensionsInPixels;
    if ((tileShape == JEWEL && energized) ||
        (tileShape == JEWEL && showEnergized)){
        textureRenderData->textureDimensionsInPixels.x = 2.0*tileDimensionsInPixels.x;
        textureRenderData->textureDimensionsInPixels.y = 2.0*tileDimensionsInPixels.y;
        textureRenderData->texturePositionInPixels.x = tilePositionInPixels.x - 0.25*textureRenderData->textureDimensionsInPixels.x;
        textureRenderData->texturePositionInPixels.y = tilePositionInPixels.y - 0.25*textureRenderData->textureDimensionsInPixels.y;
    }
    if (tileShape == RECTANGLE){
        textureRenderData->textureDimensionsInPixels.x = 0.9*tileDimensionsInPixels.x;
        textureRenderData->textureDimensionsInPixels.y = 0.9*tileDimensionsInPixels.y;
        textureRenderData->texturePositionInPixels.x = tilePositionInPixels.x + 0.056*textureRenderData->textureDimensionsInPixels.x;
        textureRenderData->texturePositionInPixels.y = tilePositionInPixels.y + 0.056*textureRenderData->textureDimensionsInPixels.y;
    }
    textureRenderData->isJewelBackground = NO;
    textureRenderData->tileColor = tileColor;
    textureRenderData->tileShape = tileShape;
    if (tileShape == BEAMSPLITTER){
        if (tileAngle % 2 == 1){
            textureRenderData->angle = (8 - tileAngle) % 8;
        }
        else {
            textureRenderData->angle = (tileAngle + 2) % 8;
        }
    }
    else {
        textureRenderData->angle = tileAngle;
    }
    textureRenderData->tileAnimationContainer = animationContainer;
    textureRenderData->tileAnimation = currentAnimation;
    textureRenderData->tile = self;
    // These are only used by Prisms
    textureRenderData->showSpectrum = showSpectrum;
    textureRenderData->spectrumAnimationContainer = spectrumAnimationContainer;
    textureRenderData->spectrumAngle = spectrumAngle;
    
    if (tileShape == JEWEL && energized && puzzleCompleted && !puzzleHasBeenCompletedCelebration)
        return nil;
    else
        return textureRenderData;
}

- (void)updatePixelPositionOfMovingTile {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    if (motionRemainingTimeInFrames > 0){
        // Motion ongoing
        motionRemainingTimeInFrames--;
        vector_int2 deltaFull = finalTilePositionInPixels - initialTilePositionInPixels;
        vector_float2 increment;
        increment.x = deltaFull.x / (float)motionPeriodInFrames;
        increment.y = deltaFull.y / (float)motionPeriodInFrames;
        tilePositionInPixels.x = tilePositionInPixels.x + (int)increment.x;
        tilePositionInPixels.y = tilePositionInPixels.y + (int)increment.y;
    }
    else {
        // Motion complete
        motionRemainingTimeInFrames = 0;
        motionType = MOTION_NONE;
        tilePositionInPixels = finalTilePositionInPixels;
        vector_int2 p;
        p.x = finalTilePositionInPixels.x;
        p.y = finalTilePositionInPixels.y;
        gridPosition = [optics pixelPositionToGridPosition:p];
        [optics finishPositionTileForHint:self];
        // Handle condition when all Tiles have dropped off the screen
        if (optics->puzzleHasBeenCompleted){
        }
    }
}


- (void)updatePixelPositionOfDroppingTile {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    if (motionRemainingTimeInFrames > 0){
        // Motion ongoing
        motionRemainingTimeInFrames--;
        
        dropSpeedInPixelsPerFrame = dropSpeedInPixelsPerFrame + dropAccelerationInPixelsPerFrameSquared*1.0;
        //        dropDistanceInPixels = dropDistanceInPixels + dropSpeedInPixelsPerFrame*1.0;
        
        //        dropDistanceInPixels = dropDistanceInPixels + dropSpeedInPixelsPerFrame*1.0;
        //        dropSpeedInPixelsPerFrame = sqrtf(2*dropAccelerationInPixelsPerFrameSquared*dropDistanceInPixels);
        
        vector_float2 increment;
        increment.x = 0.0;
        increment.y = dropSpeedInPixelsPerFrame*1.0;
        tilePositionInPixels.x = tilePositionInPixels.x + (int)increment.x;
        tilePositionInPixels.y = tilePositionInPixels.y + (int)increment.y;
    }
    else {
        // Motion complete
        motionRemainingTimeInFrames = 0;
        motionType = MOTION_NONE;
        //        tilePositionInPixels = finalTilePositionInPixels;
        //        vector_float2 p;
        //        p.x = (float)finalTilePositionInPixels.x;
        //        p.y = (float)finalTilePositionInPixels.y;
        //        gridPosition = [optics pixelPositionToGridPosition:p];
        // Handle condition when all Tiles have dropped off the screen
        if (optics->puzzleHasBeenCompleted){
        }
    }
}


- (void)startTileMotionLinear:(vector_int2)initialPosition finalPosition:(vector_int2)finalPosition
                 timeInFrames:(int)frames {
    initialTilePositionInPixels = initialPosition;
    finalTilePositionInPixels = finalPosition;
    motionPeriodInFrames = frames;
    motionRemainingTimeInFrames = frames;
    motionType = MOTION_LINEAR;
}


- (void)startTileMotionDrop:(vector_int2)initialPosition dropAcceleration:(CGFloat)g timeInFrames:(int)frames {
    initialTilePositionInPixels = initialPosition;
    dropDistanceInPixels = 0.0;
    dropSpeedInPixelsPerFrame = 0.0;
    dropAccelerationInPixelsPerFrameSquared = g;
    motionPeriodInFrames = frames;
    motionRemainingTimeInFrames = frames;
    motionType = MOTION_DROP;
}


- (BOOL)beamCanPassThroughTile:(Beam *)beam{
    BOOL retVal = NO;
    switch(tileShape){
        case LASER:{
            retVal = YES;
            break;
        }
        case RECTANGLE:{
            if (beam->beamColor == BEAM_RED){
                if (tileColor == COLOR_RED ||
                    tileColor == COLOR_YELLOW ||
                    tileColor == COLOR_MAGENTA ||
                    tileColor == COLOR_WHITE){
                    retVal = YES;
                }
            }
            else if (beam->beamColor == BEAM_GREEN){
                if (tileColor == COLOR_GREEN ||
                    tileColor == COLOR_YELLOW ||
                    tileColor == COLOR_CYAN ||
                    tileColor == COLOR_WHITE){
                    retVal = YES;
                }
            }
            else if (beam->beamColor == BEAM_BLUE){
                if (tileColor == COLOR_BLUE ||
                    tileColor == COLOR_MAGENTA ||
                    tileColor == COLOR_CYAN ||
                    tileColor == COLOR_WHITE){
                    retVal = YES;
                }
            }
            else {
                retVal = NO;
            }
            break;
        }
        default:{
            retVal = NO;
            break;
        }
    }
    return retVal;
}

@end
