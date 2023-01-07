//
//  GameControls.m
//  Beamed
//
//  Created by pkeithhynes on 8/5/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import "GameControls.h"


@implementation GameControls

- (NSMutableArray *)renderGameControls:(NSMutableArray *)gameControlTiles {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    if ([appDelegate editModeIsEnabled]){
        // Set up TextureRenderData objects for each game control tile image
        gameControlPrism = [[TextureRenderData alloc] init];
        gameControlBeamsplitter = [[TextureRenderData alloc] init];
        gameControlMirror = [[TextureRenderData alloc] init];
        gameControlJewel = [[TextureRenderData alloc] init];
        gameControlRectangle = [[TextureRenderData alloc] init];
        gameControlLaserRed = [[TextureRenderData alloc] init];
        gameControlLaserGreen = [[TextureRenderData alloc] init];
        gameControlLaserBlue = [[TextureRenderData alloc] init];
        vector_int2 gp;
        gp.x = 0; gp.y = optics->masterGrid.sizeY;
        gameControlPrism = [self createGameControlTileTexture:gameControlPrism tileShape:PRISM gridPosition:gp tileColor:COLOR_WHITE];
        gp.x = 1; gp.y = optics->masterGrid.sizeY;
        gameControlBeamsplitter = [self createGameControlTileTexture:gameControlBeamsplitter tileShape:BEAMSPLITTER gridPosition:gp tileColor:COLOR_WHITE];
        gp.x = 2; gp.y = optics->masterGrid.sizeY;
        gameControlMirror = [self createGameControlTileTexture:gameControlMirror tileShape:MIRROR gridPosition:gp tileColor:COLOR_WHITE];
        gp.x = 3; gp.y = optics->masterGrid.sizeY;
        gameControlJewel = [self createGameControlTileTexture:gameControlJewel tileShape:JEWEL gridPosition:gp tileColor:COLOR_WHITE];
        gp.x = 4; gp.y = optics->masterGrid.sizeY;
        gameControlRectangle = [self createGameControlTileTexture:gameControlRectangle tileShape:RECTANGLE gridPosition:gp tileColor:COLOR_WHITE];
        gp.x = 5; gp.y = optics->masterGrid.sizeY;
        gameControlLaserRed = [self createGameControlTileTexture:gameControlLaserRed tileShape:LASER gridPosition:gp tileColor:COLOR_RED];
        gp.x = 6; gp.y = optics->masterGrid.sizeY;
        gameControlLaserGreen = [self createGameControlTileTexture:gameControlLaserGreen tileShape:LASER gridPosition:gp tileColor:COLOR_GREEN];
        gp.x = 7; gp.y = optics->masterGrid.sizeY;
        gameControlLaserBlue = [self createGameControlTileTexture:gameControlLaserBlue tileShape:LASER gridPosition:gp tileColor:COLOR_BLUE];

        // Add all game control tile images
        [gameControlTiles addObject:gameControlPrism];
        [gameControlTiles addObject:gameControlBeamsplitter];
        [gameControlTiles addObject:gameControlMirror];
        [gameControlTiles addObject:gameControlJewel];
        [gameControlTiles addObject:gameControlRectangle];
        [gameControlTiles addObject:gameControlLaserRed];
        [gameControlTiles addObject:gameControlLaserGreen];
        [gameControlTiles addObject:gameControlLaserBlue];
    }
    return gameControlTiles;
}

- (TextureRenderData *)createGameControlTileTexture:(TextureRenderData *)tRenderData
                    tileShape:(enum eTileShape)shape
                    gridPosition:(vector_int2)gPosition
                    tileColor:(enum eTileColors)color {
    BOOL success = YES;
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;

    NSMutableArray *tileTextureDataArray = appDelegate.tileAnimationContainers;
    // Set up appropriate animation container based upon shape
    enum eTileAnimationContainers animationContainer;
    enum eObjectAngle angle = ANGLE45;

    BOOL showTileTexture = NO;
    // In Edit Mode show all of the Tile Textures
    if ([appDelegate editModeIsEnabled]){
        showTileTexture = YES;
    }
    
    TextureData *textureData = nil;
    if (shape == JEWEL){
        textureData = [appDelegate.jewelTextures objectAtIndex:6];
    }
    else {
        angle = ANGLE0;
        animationContainer = TILE_AC_GLOWWHITE_RECTANGLE;
        switch(shape) {
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
            case LASER:
                animationContainer = TILE_AC_LASER;
                break;
            default:
                DLog("Unknown tileShape %d\n", shape);
                success = NO;
        }
        textureData = [[[[tileTextureDataArray objectAtIndex:animationContainer] objectAtIndex:angle] objectAtIndex:TILE_A_WAITING] objectAtIndex:0];
    }

    if (showTileTexture) {
        tRenderData.renderTexture = textureData.texture;
        tRenderData->texturePositionInPixels.x = gPosition.x*optics->_squareTileSideLengthInPixels + optics->_tileHorizontalOffsetInPixels;
        tRenderData->texturePositionInPixels.y = gPosition.y*optics->_squareTileSideLengthInPixels + optics->_tileVerticalOffsetInPixels;
        tRenderData->textureGridPosition = gPosition;
        tRenderData->textureDimensionsInPixels.x = optics->_squareTileSideLengthInPixels;
        tRenderData->textureDimensionsInPixels.y = optics->_squareTileSideLengthInPixels;
        if (shape == JEWEL){
            tRenderData->tileColor = 7;
        }
        else {
            tRenderData->tileColor = color;
        }
    }
    if (success)
        return tRenderData;
    else
        return nil;
}

- (vector_int2)pixelPositionToGridPosition:(vector_int2)p {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    vector_int2 g;
    float epsilon = 0.1;
    g.x = (uint)(((p.x - optics->_tileHorizontalOffsetInPixels)/optics->_squareTileSideLengthInPixels) - epsilon);
    g.y = (uint)(((p.y - optics->_tileVerticalOffsetInPixels)/optics->_squareTileSideLengthInPixels) - epsilon);
    return g;
}

- (void)touchesBegan:(vector_int2)p {
    vector_int2 g = [self pixelPositionToGridPosition:p];
//    DLog("g.x = %d, g.y = %d", g.x, g.y);
    
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    if ([appDelegate editModeIsEnabled]){
        BOOL createTileRequest = YES;
        enum eTileShape tileShape = RECTANGLE;
        enum eObjectAngle angle = ANGLE0;
        enum eTileColors tileColor = COLOR_WHITE;
        //
        // The unplaced tiles are ordered left to right as follows:
        //      g.x = 0     PRISM
        //      g.x = 1     BEAMSPLITTER
        //      g.x = 2     MIRROR
        //      g.x = 3     JEWEL
        //      g.x = 4     RECTANGLE
        //      g.x = 5     RED LASER
        //      g.x = 6     GREEN LASER
        //      g.x = 7     BLUE LASER
        //
        if (g.x == 0) {            // Prism
            tileShape = PRISM;
        }
        else if (g.x == 1) {        // Beamsplitter
            tileShape = BEAMSPLITTER;
        }
        else if (g.x == 2) {        // Mirror
            tileShape = MIRROR;
        }
        else if (g.x == 3) {        // Jewel
            tileShape = JEWEL;
        }
        else if (g.x == 4) {        // Rectangle
            tileShape = RECTANGLE;
        }
        else if (g.x == 5) {        // RED LASER
            tileShape = LASER;
            tileColor = COLOR_RED;
//            angle = ANGLE45;
        }
        else if (g.x == 6) {        // GREEN LASER
            tileShape = LASER;
            tileColor = COLOR_GREEN;
//            angle = ANGLE45;
        }
        else if (g.x == 7) {        // BLUE LASER
            tileShape = LASER;
            tileColor = COLOR_BLUE;
//            angle = ANGLE45;
        }
        else {
            createTileRequest = NO;
        }

        if (createTileRequest) {
            Tile *myTile;
            vector_int2 tileDimensions;
            vector_int2 centerPositionInPixels;
            centerPositionInPixels.x = optics->gridTouchGestures.pixelPosition.x;
            centerPositionInPixels.y = optics->gridTouchGestures.pixelPosition.y;
            tileDimensions.x = tileDimensions.y = optics->_squareTileSideLengthInPixels;
            myTile = [[Tile alloc] initWithGridParameters:optics
                                                       cx:optics->gridTouchGestures.gridPosition.x
                                                       cy:optics->gridTouchGestures.gridPosition.y
                                                       cz:0
                                                    shape:tileShape
                                                    angle:angle
                                                  visible:YES
                                                    color:tileColor
                                                    fixed:NO
                                   centerPositionInPixels:centerPositionInPixels
                                       dimensionsInPixels:tileDimensions];
            [optics putOpticsTile:myTile array:optics->tiles];
            optics->tileCurrentlyBeingEdited = myTile;
            [optics updateAllBeams];
        }
    }
}

- (void)touchesEnded:(vector_int2)p {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    if ([appDelegate editModeIsEnabled]){
        if (optics->tileCurrentlyBeingEdited) {		// If we are dragging a tile with us then remove it from tiles array and discard it.
            [optics removeOpticsTile:optics->tileCurrentlyBeingEdited array:optics->tiles];
            optics->tileCurrentlyBeingEdited = nil;
            // Also reset all of the beams
            [optics resetAllColorBeams];
        }
    }
}


@end
