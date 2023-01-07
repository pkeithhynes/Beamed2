//
//  Beam.m
//  Beamed
//
//  Created by pkeithhynes on 7/14/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import "Beam.h"


@implementation Beam


- (Beam *)initWithGridParameters:(vector_int2)start
                       direction:(enum eObjectAngle)direction
                         visible:(BOOL)visible
                          energy:(CGFloat)energy
                          isRoot:(BOOL)isRoot
                           color:(enum eBeamColors)color
                       beamLevel:(int)level
                       startTile:(Tile *)startT
                         endTile:(Tile *)endT {
    if (beamLevel < kNumberOfBeamLevels){
//        DLog("Beam init level = %d", beamLevel);
        root = isRoot;
        beamStart = start;
        beamAngle = direction;
        startTile = startT;
        endTile = endT;
        beamVisible = visible;
        beamEnergy = energy;
        beamColor = color;
        textureRenderData = [[TextureRenderData alloc] init];
        beamLevel = level;
        beamEnergy = 1.0;                // Override beamEnergy to keep beams at full color for now
        
        animationContainer = BEAM_AC_GLOWWHITE_RECTANGLE_HORIZONTAL;
        currentAnimation = BEAM_A_STEADY;
        
        [self checkIfBeamInteractsWithTile];
        return self;
    }
    else {
        return nil;
    }
}


// - Adjusts beam length to accomodate tile interactions
// - Updates numberOfBeamsCrossingGridPoint when beam is initialized
// - Laser tiles do not interact with beams
- (BOOL)checkIfBeamInteractsWithTile  {
    BOOL retValue = NO;
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    int MAXX = optics->masterGrid.sizeX-1;
    int MAXY = optics->masterGrid.sizeY-1;
    int tileIndex;
    int start_index, end_index;
    Tile *myTile, *blockingTile;
    // Determine whether the beam strikes a tile
    int blockingPosition;
    int blockingPositionX, blockingPositionY;
    blockingTile = nil;
    // Horizontal beam: BeamDirection = ANGLE0
    if (beamAngle == ANGLE0) {
        blockingPosition = MAXX;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.y==beamStart.y && myTile->gridPosition.x>beamStart.x) {
                if (myTile->gridPosition.x <= blockingPosition && myTile->tileShape!=LASER) {
                    blockingPosition = myTile->gridPosition.x;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.x = blockingPosition;
        beamEnd.y = beamStart.y;
        if (blockingTile && blockingTile->tileShape!=LASER) {			// A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE0 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        start_index = beamStart.x;
        end_index = beamEnd.x;
    }
    else if (beamAngle == ANGLE45) {
        int deltaX = optics->masterGrid.sizeX-1 - beamStart.x;
        int deltaY = optics->masterGrid.sizeY-1 - beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = optics->masterGrid.sizeX-1;
            blockingPositionY = beamStart.y + deltaX;
        }
        else {
            blockingPositionX = beamStart.x + deltaY;
            blockingPositionY = optics->masterGrid.sizeY-1;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.x > beamStart.x  && (int)(myTile->gridPosition.x-beamStart.x) == (int)(myTile->gridPosition.y-beamStart.y)) {
                if (myTile->gridPosition.x <= blockingPositionX && myTile->gridPosition.y <= blockingPositionY && myTile->tileShape!=LASER) {
                    blockingPositionX = myTile->gridPosition.x;
                    blockingPositionY = myTile->gridPosition.y;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        if (blockingTile && blockingTile->tileShape!=LASER) {			// A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE45 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        deltaX = beamEnd.x - beamStart.x;
        start_index = 0;
        end_index = deltaX;
    }
    else if (beamAngle == ANGLE90) {
        blockingPosition = MAXY;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.x==beamStart.x && myTile->gridPosition.y>beamStart.y) {
                if (myTile->gridPosition.y <= blockingPosition && myTile->tileShape!=LASER) {
                    blockingPosition = myTile->gridPosition.y;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.y = blockingPosition;
        beamEnd.x = beamStart.x;
        if (blockingTile && blockingTile->tileShape!=LASER) {			// A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE90 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        start_index = beamStart.y;
        end_index = beamEnd.y;
    }
    else if (beamAngle == ANGLE135) {
        int deltaX = beamStart.x;
        int deltaY = optics->masterGrid.sizeY-1 - beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = 0;
            blockingPositionY = beamStart.y + deltaX;
        }
        else {
            blockingPositionX = beamStart.x - deltaY;
            blockingPositionY = optics->masterGrid.sizeY-1;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.x < beamStart.x && (int)(myTile->gridPosition.x-beamStart.x) == -(int)(myTile->gridPosition.y-beamStart.y)) {
                if (myTile->gridPosition.x >= blockingPositionX && myTile->gridPosition.y <= blockingPositionY && myTile->tileShape!=LASER) {
                    blockingPositionX = myTile->gridPosition.x;
                    blockingPositionY = myTile->gridPosition.y;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        if (blockingTile && blockingTile->tileShape!=LASER) {            // A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE135 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        deltaX = beamEnd.x - beamStart.x;
        start_index = 0;
        end_index = deltaX;
    }
    // Horizontal beam: BeamDirection = ANGLE180
    else if (beamAngle == ANGLE180) {
        blockingPosition = 0;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.y==beamStart.y && myTile->gridPosition.x<beamStart.x) {
                if (myTile->gridPosition.x >= blockingPosition && myTile->tileShape!=LASER) {
                    blockingPosition = myTile->gridPosition.x;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.x = blockingPosition;
        beamEnd.y = beamStart.y;
        if (blockingTile && blockingTile->tileShape!=LASER) {			// A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE180 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        start_index = beamStart.x;
        end_index = beamEnd.x;
    }
    else if (beamAngle == ANGLE225) {
        int deltaX = beamStart.x;
        int deltaY = beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = 0;
            blockingPositionY = beamStart.y - deltaX;
        }
        else {
            blockingPositionX = beamStart.x - deltaY;
            blockingPositionY = 0;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.x < beamStart.x && (int)(myTile->gridPosition.x-beamStart.x) == (int)(myTile->gridPosition.y-beamStart.y)) {
                if (myTile->gridPosition.x >= blockingPositionX && myTile->gridPosition.y >= blockingPositionY && myTile->tileShape!=LASER) {
                    blockingPositionX = myTile->gridPosition.x;
                    blockingPositionY = myTile->gridPosition.y;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        if (blockingTile && blockingTile->tileShape!=LASER) {			// A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE225 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        deltaX = beamEnd.x - beamStart.x;
        start_index = 0;
        end_index = deltaX;
    }
    // Vertical beam: BeamDirection = ANGLE270
    else if (beamAngle == ANGLE270) {
        blockingPosition = 0;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.x==beamStart.x && myTile->gridPosition.y<beamStart.y) {
                if (myTile->gridPosition.y >= blockingPosition && myTile->tileShape!=LASER) {
                    blockingPosition = myTile->gridPosition.y;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.x = beamStart.x;
        beamEnd.y = blockingPosition;
        if (blockingTile && blockingTile->tileShape!=LASER) {			// A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE270 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        NSError *error = nil;
        NSAssert(beamStart.y >= beamEnd.y, @"beamStart:beamEnd inconsistent with direction, error %@", error);
        start_index = beamStart.y;
        end_index = beamEnd.y;
    }
    else if (beamAngle == ANGLE315) {
        int deltaX = optics->masterGrid.sizeX-1 - beamStart.x;
        int deltaY = beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = optics->masterGrid.sizeX-1;
            blockingPositionY = beamStart.y - deltaX;
        }
        else {
            blockingPositionX = beamStart.x + deltaY;
            blockingPositionY = 0;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (myTile->gridPosition.x > beamStart.x && (int)(myTile->gridPosition.x-beamStart.x) == -(int)(myTile->gridPosition.y-beamStart.y)) {
                if (myTile->gridPosition.x <= blockingPositionX && myTile->gridPosition.y >= blockingPositionY && myTile->tileShape!=LASER) {
                    blockingPositionX = myTile->gridPosition.x;
                    blockingPositionY = myTile->gridPosition.y;
                    blockingTile = myTile;
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        if (blockingTile && blockingTile->tileShape!=LASER) {			// A tile is blocking the beam - send it a message to tell it!
            endTile = blockingTile;
            [blockingTile tileIsInteractingWithBeam:self direction:ANGLE315 color:beamColor];
            retValue = YES;
        }
        else {
            endTile = nil;
        }
        deltaX = beamEnd.x - beamStart.x;
        start_index = 0;
        end_index = deltaX;
    }
    return retValue;
}

- (NSMutableDictionary *)checkIfBeamIntersectsGridPosition:(vector_int2)position  {
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
    [returnDictionary setObject:[NSNumber numberWithInt:0] forKey:@"beamTouchesGridPoint"];
    [returnDictionary setObject:[NSNumber numberWithInt:0] forKey:@"beamPassesThroughGridPoint"];
    [returnDictionary setObject:[NSNumber numberWithInt:beamAngle] forKey:@"beamAngle"];

    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    int MAXX = optics->masterGrid.sizeX-1;
    int MAXY = optics->masterGrid.sizeY-1;
    int tileIndex;
    Tile *myTile;
    // Determine whether the beam strikes a tile
    int blockingPosition;
    int blockingPositionX, blockingPositionY;
    
    // Horizontal beam: BeamDirection = ANGLE0
    if (beamAngle == ANGLE0) {
        blockingPosition = MAXX;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.y==beamStart.y && myTile->gridPosition.x>beamStart.x) {
                    if (myTile->gridPosition.x <= blockingPosition) {
                        blockingPosition = myTile->gridPosition.x;
                    }
                }
            }
        }
        beamEnd.x = blockingPosition;
        beamEnd.y = beamStart.y;
        //
        // Test position
        //
        if (position.y == beamStart.y &&
            position.x > beamStart.x &&
            position.x <= blockingPosition){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.y == beamStart.y &&
            position.x > beamStart.x &&
            position.x < blockingPosition){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    else if (beamAngle == ANGLE45) {
        int deltaX = optics->masterGrid.sizeX-1 - beamStart.x;
        int deltaY = optics->masterGrid.sizeY-1 - beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = optics->masterGrid.sizeX-1;
            blockingPositionY = beamStart.y + deltaX;
        }
        else {
            blockingPositionX = beamStart.x + deltaY;
            blockingPositionY = optics->masterGrid.sizeY-1;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.x > beamStart.x  && (int)(myTile->gridPosition.x-beamStart.x) == (int)(myTile->gridPosition.y-beamStart.y)) {
                    if (myTile->gridPosition.x <= blockingPositionX && myTile->gridPosition.y <= blockingPositionY){
                        blockingPositionX = myTile->gridPosition.x;
                        blockingPositionY = myTile->gridPosition.y;
                    }
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        //
        // Test position
        //
        if (position.x > beamStart.x &&
            position.x-beamStart.x == position.y-beamStart.y &&
            position.x <= blockingPositionX &&
            position.y <= blockingPositionY){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.x > beamStart.x &&
            position.x-beamStart.x == position.y-beamStart.y &&
            position.x < blockingPositionX &&
            position.y < blockingPositionY){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    else if (beamAngle == ANGLE90) {
        blockingPosition = MAXY;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.x==beamStart.x && myTile->gridPosition.y>beamStart.y) {
                    if (myTile->gridPosition.y <= blockingPosition) {
                        blockingPosition = myTile->gridPosition.y;
                    }
                }
            }
        }
        beamEnd.y = blockingPosition;
        beamEnd.x = beamStart.x;
        //
        // Test position
        //
        if (position.x == beamStart.x &&
            position.y > beamStart.y &&
            position.y <= blockingPosition){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.x == beamStart.x &&
            position.y > beamStart.y &&
            position.y < blockingPosition){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    else if (beamAngle == ANGLE135) {
        int deltaX = beamStart.x;
        int deltaY = optics->masterGrid.sizeY-1 - beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = 0;
            blockingPositionY = beamStart.y + deltaX;
        }
        else {
            blockingPositionX = beamStart.x - deltaY;
            blockingPositionY = optics->masterGrid.sizeY-1;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.x < beamStart.x && (int)(myTile->gridPosition.x-beamStart.x) == -(int)(myTile->gridPosition.y-beamStart.y)) {
                    if (myTile->gridPosition.x >= blockingPositionX && myTile->gridPosition.y <= blockingPositionY) {
                        blockingPositionX = myTile->gridPosition.x;
                        blockingPositionY = myTile->gridPosition.y;
                    }
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        //
        // Test position
        //
        if (position.x < beamStart.x &&
            position.x-beamStart.x == -(position.y-beamStart.y) &&
            position.x >= blockingPositionX &&
            position.y <= blockingPositionY){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.x < beamStart.x &&
            position.x-beamStart.x == -(position.y-beamStart.y) &&
            position.x > blockingPositionX &&
            position.y < blockingPositionY){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    // Horizontal beam: BeamDirection = ANGLE180
    else if (beamAngle == ANGLE180) {
        blockingPosition = 0;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.y==beamStart.y && myTile->gridPosition.x<beamStart.x) {
                    if (myTile->gridPosition.x >= blockingPosition) {
                        blockingPosition = myTile->gridPosition.x;
                    }
                }
            }
        }
        beamEnd.x = blockingPosition;
        beamEnd.y = beamStart.y;
        //
        // Test position
        //
        if (position.y == beamStart.y &&
            position.x < beamStart.x &&
            position.x >= beamEnd.x){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.y == beamStart.y &&
            position.x < beamStart.x &&
            position.x > beamEnd.x){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    else if (beamAngle == ANGLE225) {
        int deltaX = beamStart.x;
        int deltaY = beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = 0;
            blockingPositionY = beamStart.y - deltaX;
        }
        else {
            blockingPositionX = beamStart.x - deltaY;
            blockingPositionY = 0;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.x < beamStart.x && (int)(myTile->gridPosition.x-beamStart.x) == (int)(myTile->gridPosition.y-beamStart.y)) {
                    if (myTile->gridPosition.x >= blockingPositionX && myTile->gridPosition.y >= blockingPositionY) {
                        blockingPositionX = myTile->gridPosition.x;
                        blockingPositionY = myTile->gridPosition.y;
                    }
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        //
        // Test position
        //
        if (position.x < beamStart.x &&
            position.x-beamStart.x == position.y-beamStart.y &&
            position.x >= beamEnd.x &&
            position.y >= beamEnd.y){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.x < beamStart.x &&
            position.x-beamStart.x == position.y-beamStart.y &&
            position.x > beamEnd.x &&
            position.y > beamEnd.y){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    // Vertical beam: BeamDirection = ANGLE270
    else if (beamAngle == ANGLE270) {
        blockingPosition = 0;
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.x==beamStart.x && myTile->gridPosition.y<beamStart.y) {
                    if (myTile->gridPosition.y >= blockingPosition) {
                        blockingPosition = myTile->gridPosition.y;
                    }
                }
            }
        }
        beamEnd.x = beamStart.x;
        beamEnd.y = blockingPosition;
        if (position.x == beamStart.x &&
            position.y < beamStart.y &&
            position.y >= beamEnd.y){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.x == beamStart.x &&
            position.y < beamStart.y &&
            position.y > beamEnd.y){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    else if (beamAngle == ANGLE315) {
        int deltaX = optics->masterGrid.sizeX-1 - beamStart.x;
        int deltaY = beamStart.y;
        if (deltaX < deltaY) {
            blockingPositionX = optics->masterGrid.sizeX-1;
            blockingPositionY = beamStart.y - deltaX;
        }
        else {
            blockingPositionX = beamStart.x + deltaY;
            blockingPositionY = 0;
        }
        for (tileIndex=0; tileIndex<[optics getOpticsTileCount]; tileIndex++) {
            myTile = [optics getOpticsTile:tileIndex];
            if (![myTile beamCanPassThroughTile:self]){
                if (myTile->gridPosition.x > beamStart.x && (int)(myTile->gridPosition.x-beamStart.x) == -(int)(myTile->gridPosition.y-beamStart.y)) {
                    if (myTile->gridPosition.x <= blockingPositionX && myTile->gridPosition.y >= blockingPositionY) {
                        blockingPositionX = myTile->gridPosition.x;
                        blockingPositionY = myTile->gridPosition.y;
                    }
                }
            }
        }
        beamEnd.x = blockingPositionX;
        beamEnd.y = blockingPositionY;
        //
        // Test position
        //
        if (position.x > beamStart.x &&
            position.x-beamStart.x == -(position.y-beamStart.y) &&
            position.x <= beamEnd.x &&
            position.y >= beamEnd.y){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamTouchesGridPoint"];
        }
        if (position.x > beamStart.x &&
            position.x-beamStart.x == -(position.y-beamStart.y) &&
            position.x < beamEnd.x &&
            position.y > beamEnd.y){
            [returnDictionary setObject:[NSNumber numberWithInt:1] forKey:@"beamPassesThroughGridPoint"];
        }
    }
    return returnDictionary;
}


- (void)renderBeam:(NSMutableArray *)beamsRenderArray frameCounter:(uint16_t)frameCounter {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *beamTextureDataArray = appDelegate.beamAnimationContainers;
    animationContainer = BEAM_AC_GLOWWHITE_RECTANGLE_HORIZONTAL;
    if (beamVisible) {
        // Increment animationFrame, wrapping back to 0 if last animation
        NSMutableArray *frameArray = [[[beamTextureDataArray objectAtIndex:animationContainer] objectAtIndex:ANGLE0] objectAtIndex:currentAnimation];
        uint16_t animationFrame = frameCounter % [frameArray count];
        TextureData *textureData = [[[[beamTextureDataArray objectAtIndex:animationContainer] objectAtIndex:ANGLE0] objectAtIndex:currentAnimation] objectAtIndex:animationFrame];
        
        // Search beamsRenderArray for a BeamTextureRenderData with the same beam start and end tile grid positions
        BeamTextureRenderData *bgd;
        NSEnumerator *bgdEnum = [beamsRenderArray objectEnumerator];
        BOOL foundAndUpdatedObject = NO;
        while (bgd = [bgdEnum nextObject]) {
            // Is there already a BeamTextureRenderData instance for a beam connecting these grid positions in either direction?
            if ((bgd->textureStartGridPosition.x == beamStart.x
                 && bgd->textureStartGridPosition.y == beamStart.y
                 && bgd->textureEndGridPosition.x == beamEnd.x
                 && bgd->textureEndGridPosition.y == beamEnd.y) ||
                (bgd->textureStartGridPosition.x == beamEnd.x
                 && bgd->textureStartGridPosition.y == beamEnd.y
                 && bgd->textureEndGridPosition.x == beamStart.x
                 && bgd->textureEndGridPosition.y == beamStart.y)) {
                NSError *error = nil;
                NSAssert(beamColor >= BEAM_RED && beamColor <= BEAM_BLUE, @"beamColor %d out of range, error %@", beamColor, error);
                bgd->beamCountsByColor[beamColor]++;
                foundAndUpdatedObject = YES;
            }
        }
        // If no matching object found then create and initialize a new BeamTextureRenderData instance and add to array
        if (!foundAndUpdatedObject) {
            bgd = [[BeamTextureRenderData alloc] init];
            // TODO: debug math error
            bgd->textureStartGridPosition = beamStart;
            bgd->textureEndGridPosition = beamEnd;
            bgd->texturePositionInPixels = [self beamPositionInPixels];
            bgd->textureDimensionsInPixels = [self beamDimensionsInPixels];
            bgd->beamCountsByColor[beamColor]++;
            bgd->angle = beamAngle;
            bgd->beam = self;
            bgd.beamRenderTexture = textureData.texture;
            [beamsRenderArray addObject:bgd];
        }
    }
}

- (vector_int2)beamPositionInPixels {
    vector_int2 c, d, p;
    c = [self beamCenterInPixels];
    d = [self beamDimensionsInPixels];
    p.x = c.x - d.x/2.0;
    p.y = c.y - d.y/2.0;
    return p;
}

- (vector_float2)rootBeamStartPositionInPixels {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    CGFloat tileSide = appDelegate->optics->_squareTileSideLengthInPixels;
    vector_float2 s, e;
    s = [self gridPositionToPixelPosition:beamStart];
    e = [self gridPositionToPixelPosition:beamEnd];
    if (beamStart.x == 0){
        switch(beamAngle){
            case ANGLE315:{
                s.x = s.x - tileSide;
                s.y = s.y + tileSide;
                break;
            }
            case ANGLE0:{
                s.x = s.x - tileSide;
                break;
            }
            case ANGLE45:{
                s.x = s.x - tileSide;
                s.y = s.y - tileSide;
                break;
            }
            default:{
                break;
            }
        }
    }
    else if (beamStart.x == appDelegate->optics->masterGrid.sizeX-1){
        switch(beamAngle){
            case ANGLE225:{
                s.x = s.x + tileSide;
                s.y = s.y + tileSide;
                break;
            }
            case ANGLE180:{
                s.x = s.x + tileSide;
                break;
            }
            case ANGLE135:{
                s.x = s.x + tileSide;
                s.y = s.y - tileSide;
                break;
            }
            default:{
                break;
            }
        }
    }
    else if (beamStart.y == 0){
        switch(beamAngle){
            case ANGLE45:{
                s.x = s.x - tileSide;
                s.y = s.y - tileSide;
                break;
            }
            case ANGLE90:{
                s.y = s.y - tileSide;
                break;
            }
            case ANGLE135:{
                s.x = s.x + tileSide;
                s.y = s.y - tileSide;
                break;
            }
            default:{
                break;
            }
        }
    }
    else if (beamStart.y == appDelegate->optics->masterGrid.sizeY-1){
        switch(beamAngle){
            case ANGLE315:{
                s.x = s.x - tileSide;
                s.y = s.y + tileSide;
                break;
            }
            case ANGLE270:{
                s.y = s.y + tileSide;
                break;
            }
            case ANGLE225:{
                s.x = s.x + tileSide;
                s.y = s.y + tileSide;
                break;
            }
            default:{
                break;
            }
        }
    }
    return s;
}

- (vector_int2)beamCenterInPixels {
    vector_int2 c;
    vector_float2 s, e;
    // root beam render textures get extended beyond their starting grid point to meet the Laser Gun Tile
//    if (root){
    if (NO){
        s = [self rootBeamStartPositionInPixels];
    }
    else {
        s = [self gridPositionToPixelPosition:beamStart];
    }
    e = [self gridPositionToPixelPosition:beamEnd];
    c.x = (s.x + e.x)/2.0;
    c.y = (s.y + e.y)/2.0;
    return c;
}

//- (vector_int2)beamCenterInPixels {
//    vector_int2 c;
//    vector_float2 s = [self gridPositionToPixelPosition:beamStart];
//    vector_float2 e = [self gridPositionToPixelPosition:beamEnd];
//    c.x = (s.x + e.x)/2.0;
//    c.y = (s.y + e.y)/2.0;
//    return c;
//}

- (vector_int2)beamDimensionsInPixels {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    vector_int2 d;
    vector_float2 s;
    // root beam render textures get extended beyond their starting grid point to meet the Laser Gun Tile
//    if (root){
    if (NO){
        s = [self rootBeamStartPositionInPixels];
    }
    else {
        s = [self gridPositionToPixelPosition:beamStart];
    }
    vector_float2 e = [self gridPositionToPixelPosition:beamEnd];
    float length = sqrt((s.x-e.x)*(s.x-e.x) + (s.y-e.y)*(s.y-e.y));
    d.x = length;
    d.y = 4.0*optics->_squareTileSideLengthInPixels;
    return d;
}

- (vector_float2)gridPositionToPixelPosition:(vector_int2)g {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    vector_float2 p;
    // Beams start and end at centers of tiles
    p.x = (g.x * optics->_squareTileSideLengthInPixels) + optics->_squareTileSideLengthInPixels/2.0 + optics->_tileHorizontalOffsetInPixels;
    p.y = (g.y * optics->_squareTileSideLengthInPixels) + optics->_squareTileSideLengthInPixels/2.0 + optics->_tileVerticalOffsetInPixels;
    return p;
}

- (vector_int2)pixelPositionToGridPosition:(vector_float2)p {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    vector_int2 g;
    //    float epsilon = 0.1;
    g.x = (uint)(p.x - optics->_tileHorizontalOffsetInPixels)/optics->_squareTileSideLengthInPixels;
    g.y = (uint)(p.y - optics->_tileVerticalOffsetInPixels)/optics->_squareTileSideLengthInPixels;
    return g;
}

@end
