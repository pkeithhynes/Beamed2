//
//  Background.m
//  Beamed
//
//  Created by pkeithhynes on 7/14/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import "Background.h"
#import <math.h>


@implementation Background

- (Background *)init {
    self = [super init];
    if (self){
        animationFrame = 0;
    }
    return self;
}


// Render an array of background Tile Textures based upon the grid geometry
// - tileColor  >= 0 and <= 6 will cause Tiles to display with eTileColors 0-6
// - tileColor >= 7 will cause Tiles to display a shifting set of colors
- (NSMutableArray *)renderBackgroundArray:(NSMutableArray *)backgroundArray
                                tileColor:(unsigned int)tileColor
                    numberOfUnplacedTiles:(unsigned int)numberOfUnplacedTiles
                          puzzleCompleted:(BOOL)puzzleCompleted
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *backgroundTextureData = [backgroundTextureDataArray objectAtIndex:TILE_BG];
    TextureRenderData *backgroundTileRenderData, *unusedTileBackgroundRenderData;
    
    animationFrame++;
    int ii, jj;

    for (ii=0; ii<optics->masterGrid.sizeX; ii++) {
        // Puzzle Grid
        for (jj=0; jj<optics->masterGrid.sizeY; jj++) {
            if (ii > 0 && ii < optics->masterGrid.sizeX-1 &&
                jj > 0 && jj < optics->masterGrid.sizeY-1) {
                backgroundTileRenderData = [[TextureRenderData alloc] init];
                backgroundTileRenderData.renderTexture = backgroundTextureData.texture;
                backgroundTileRenderData->textureGridPosition.x = ii;
                backgroundTileRenderData->textureGridPosition.y = jj;
                vector_float2 p = [optics gridPositionToPixelPosition:backgroundTileRenderData->textureGridPosition];
                backgroundTileRenderData->texturePositionInPixels.x = (uint)p.x;
                backgroundTileRenderData->texturePositionInPixels.y = (uint)p.y;
                backgroundTileRenderData->textureDimensionsInPixels.x = 1.0*optics->_squareTileSideLengthInPixels;
                backgroundTileRenderData->textureDimensionsInPixels.y = 1.0*optics->_squareTileSideLengthInPixels;
                
                if ( (tileColor >=0 && tileColor <=6) || tileColor==8 ){
                    backgroundTileRenderData->tileColor = tileColor;
                }
                else {
                    backgroundTileRenderData->tileColor = (int)(2.37*(float)ii + 3.53*(float)jj + (float)animationFrame/400) % 7;
                }
                
                backgroundTileRenderData->angle = ANGLE45;
                backgroundTileRenderData->tileShape = BACKGROUND;
                // TODO: No tileAnimation or tile fields - for now treat this as a special backgound object
                // TODO: not actually a Tile at all.
                [backgroundArray addObject:backgroundTileRenderData];
            }
        }
        // Unused Tile Grid at jj = optics->masterGrid.sizeY
        if (ii < numberOfUnplacedTiles){
            unusedTileBackgroundRenderData = [[TextureRenderData alloc] init];
            unusedTileBackgroundRenderData.renderTexture = backgroundTextureData.texture;
            unusedTileBackgroundRenderData->textureGridPosition.x = ii+1;   // Shift over by 1
                                                                            // to match edge of gameGrid
            unusedTileBackgroundRenderData->textureGridPosition.y = optics->masterGrid.sizeY;
            vector_float2 p = [optics gridPositionToPixelPosition:unusedTileBackgroundRenderData->textureGridPosition];
            unusedTileBackgroundRenderData->texturePositionInPixels.x = (uint)p.x;
            unusedTileBackgroundRenderData->texturePositionInPixels.y = (uint)p.y;
            unusedTileBackgroundRenderData->textureDimensionsInPixels.x = optics->_squareTileSideLengthInPixels;
            unusedTileBackgroundRenderData->textureDimensionsInPixels.y = optics->_squareTileSideLengthInPixels;
            unusedTileBackgroundRenderData->tileColor = tileColor;
            unusedTileBackgroundRenderData->angle = ANGLE45;
            unusedTileBackgroundRenderData->tileShape = BACKGROUND;
            [backgroundArray addObject:unusedTileBackgroundRenderData];
        }
    }
    return backgroundArray;
}


- (TextureRenderData *)renderUnusedTileBackground:(unsigned int)backgroundColor numberOfUnplacedTiles:(unsigned int)numberOfUnplacedTiles initialNumberOfUnplacedTiles:(unsigned int)initialNumberOfUnplacedTiles{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;

    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *backgroundTextureData;
    
    backgroundTextureData = [backgroundTextureDataArray objectAtIndex:BACKGROUND_ASPECT_4_3];

    unusedTileBackgroundRenderData = [[TextureRenderData alloc] init];
    unusedTileBackgroundRenderData.renderTexture = backgroundTextureData.texture;
    unusedTileBackgroundRenderData->texturePositionInPixels.x = optics->gridTouchGestures.minUnplacedTilesBoundary.x - optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    unusedTileBackgroundRenderData->texturePositionInPixels.y = optics->gridTouchGestures.minUnplacedTilesBoundary.y - optics->_puzzleGridTopAndBottomBorderWidthInPixels;
    if (numberOfUnplacedTiles == 0){
        unusedTileBackgroundRenderData->textureDimensionsInPixels.x = 0.0;
    }
    else {
        unusedTileBackgroundRenderData->textureDimensionsInPixels.x = 1.0*optics->_squareTileSideLengthInPixels*numberOfUnplacedTiles + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    }
    unusedTileBackgroundRenderData->textureDimensionsInPixels.y = optics->_squareTileSideLengthInPixels + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    unusedTileBackgroundRenderData->tileColor = backgroundColor;

    return unusedTileBackgroundRenderData;
}

- (TextureRenderData *)renderUnusedTileBackground2:(unsigned int)backgroundColor numberOfUnplacedTiles:(unsigned int)numberOfUnplacedTiles initialNumberOfUnplacedTiles:(unsigned int)initialNumberOfUnplacedTiles{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;

    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *backgroundTextureData;
    
    backgroundTextureData = [backgroundTextureDataArray objectAtIndex:BACKGROUND_ASPECT_4_3];

    unusedTileBackgroundRenderData = [[TextureRenderData alloc] init];
    unusedTileBackgroundRenderData.renderTexture = backgroundTextureData.texture;
    unusedTileBackgroundRenderData->texturePositionInPixels.x = optics->_tileHorizontalOffsetInPixels - optics->_puzzleGridLeftAndRightBorderWidthInPixels +
        optics->_squareTileSideLengthInPixels*(initialNumberOfUnplacedTiles-numberOfUnplacedTiles);
    unusedTileBackgroundRenderData->texturePositionInPixels.y = optics->_tileVerticalOffsetInPixels - optics->_puzzleGridTopAndBottomBorderWidthInPixels +
        optics->_squareTileSideLengthInPixels*(optics->gameGrid.sizeY);
    if (numberOfUnplacedTiles == 0){
        unusedTileBackgroundRenderData->textureDimensionsInPixels.x = 0.0;
    }
    else {
        unusedTileBackgroundRenderData->textureDimensionsInPixels.x = 1.0*optics->_squareTileSideLengthInPixels*numberOfUnplacedTiles + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    }
    unusedTileBackgroundRenderData->textureDimensionsInPixels.y = optics->_squareTileSideLengthInPixels + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    unusedTileBackgroundRenderData->tileColor = backgroundColor;

    return unusedTileBackgroundRenderData;
}

- (TextureRenderData *)renderBackgroundImage:(unsigned int)backgroundColor {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;

    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *backgroundTextureData;
    
    backgroundTextureData = [backgroundTextureDataArray objectAtIndex:PUZZLE_BACKGROUND_IMAGE1];

    backgroundRenderDataImage = [[TextureRenderData alloc] init];
    backgroundRenderDataImage.renderTexture = backgroundTextureData.texture;
    backgroundRenderDataImage->texturePositionInPixels.x = 0;
    backgroundRenderDataImage->texturePositionInPixels.y = 0;
    backgroundRenderDataImage->textureDimensionsInPixels.x = optics->_screenWidthInPixels;
    backgroundRenderDataImage->textureDimensionsInPixels.y = optics->_screenHeightInPixels;
    backgroundRenderDataImage->tileColor = backgroundColor;

    return backgroundRenderDataImage;
}

- (TextureRenderData *)renderBackgroundInner:(unsigned int)backgroundColor {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;

    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *backgroundTextureData;
    
    backgroundTextureData = [backgroundTextureDataArray objectAtIndex:BACKGROUND_ASPECT_4_3];

    backgroundRenderDataInner = [[TextureRenderData alloc] init];
    backgroundRenderDataInner.renderTexture = backgroundTextureData.texture;
    backgroundRenderDataInner->texturePositionInPixels.x = optics->gridTouchGestures.minPuzzleBoundary.x - 1.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    backgroundRenderDataInner->texturePositionInPixels.y = optics->gridTouchGestures.minPuzzleBoundary.y - 1.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    backgroundRenderDataInner->textureDimensionsInPixels.x = optics->_puzzleDisplayWidthInPixels + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    backgroundRenderDataInner->textureDimensionsInPixels.y = optics->_puzzleDisplayHeightInPixels + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    backgroundRenderDataInner->tileColor = backgroundColor;

    return backgroundRenderDataInner;
}

- (TextureRenderData *)renderBackgroundOuter:(unsigned int)backgroundColor {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;

    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *backgroundTextureData;
    
    backgroundTextureData = [backgroundTextureDataArray objectAtIndex:BACKGROUND_ASPECT_4_3];

    backgroundRenderDataOuter = [[TextureRenderData alloc] init];
    backgroundRenderDataOuter.renderTexture = backgroundTextureData.texture;
    backgroundRenderDataOuter->texturePositionInPixels.x = optics->_tileHorizontalOffsetInPixels - optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    backgroundRenderDataOuter->texturePositionInPixels.y = optics->_tileVerticalOffsetInPixels - optics->_puzzleGridTopAndBottomBorderWidthInPixels;
    backgroundRenderDataOuter->textureDimensionsInPixels.x = optics->_puzzleDisplayWidthInPixels + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    backgroundRenderDataOuter->textureDimensionsInPixels.y = optics->_puzzleDisplayHeightInPixels + 2.0*optics->_puzzleGridLeftAndRightBorderWidthInPixels;
    backgroundRenderDataOuter->tileColor = backgroundColor;

    return backgroundRenderDataOuter;
}

- (TextureRenderData *)renderBorder:(enum eTileColors)color
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;

    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *backgroundTextureData;
    
    backgroundTextureData = [backgroundTextureDataArray objectAtIndex:BORDER_ASPECT_4_3];

    borderRenderData = [[TextureRenderData alloc] init];
    borderRenderData.renderTexture = backgroundTextureData.texture;
    borderRenderData->tileColor = color;

    borderRenderData->texturePositionInPixels.x = optics->_tileHorizontalOffsetInPixels;
    borderRenderData->texturePositionInPixels.y = optics->_tileVerticalOffsetInPixels;
    borderRenderData->textureDimensionsInPixels.x = optics->_puzzleDisplayWidthInPixels;
    borderRenderData->textureDimensionsInPixels.y = optics->_puzzleDisplayHeightInPixels;

    return borderRenderData;
}

- (TextureRenderData *)renderTapToRotatePrompt:(vector_int2)position angle:(enum eObjectAngle)angle {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *demoTileTextureData = [backgroundTextureDataArray objectAtIndex:TAP_TO_ROTATE];
    TextureRenderData *demoTileRenderData = [[TextureRenderData alloc] init];

    demoTileRenderData.renderTexture = demoTileTextureData.texture;
    demoTileRenderData->texturePositionInPixels.x = position.x - 0.5*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->texturePositionInPixels.y = position.y - 0.5*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->textureDimensionsInPixels.x = 2.0*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->textureDimensionsInPixels.y = 2.0*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->tileColor = COLOR_YELLOW;
    demoTileRenderData->angle = angle;
    return demoTileRenderData;
}

- (TextureRenderData *)renderPointingFinger:(vector_int2)position angle:(enum eObjectAngle)angle {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *demoTileTextureData = [backgroundTextureDataArray objectAtIndex:POINTING_FINGER];
    TextureRenderData *demoTileRenderData = [[TextureRenderData alloc] init];

    demoTileRenderData.renderTexture = demoTileTextureData.texture;
    
        demoTileRenderData->tileColor = COLOR_WHITE;
        demoTileRenderData->texturePositionInPixels.x = position.x - 0.2*optics->_squareTileSideLengthInPixels;
        demoTileRenderData->texturePositionInPixels.y = position.y - 0.2*optics->_squareTileSideLengthInPixels;
        demoTileRenderData->textureDimensionsInPixels.x = 3.6*optics->_squareTileSideLengthInPixels;
        demoTileRenderData->textureDimensionsInPixels.y = 3.0*optics->_squareTileSideLengthInPixels;

    demoTileRenderData->tileColor = COLOR_YELLOW;
    demoTileRenderData->angle = angle;
    return demoTileRenderData;
}

- (TextureRenderData *)renderDragPromptText:(vector_int2)position angle:(enum eObjectAngle)angle {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *demoTileTextureData = [backgroundTextureDataArray objectAtIndex:DRAG_TILE_TEXT];
    TextureRenderData *demoTileRenderData = [[TextureRenderData alloc] init];

    demoTileRenderData.renderTexture = demoTileTextureData.texture;
    
        demoTileRenderData->tileColor = COLOR_YELLOW;
        demoTileRenderData->texturePositionInPixels.x = position.x - 0.25*optics->_squareTileSideLengthInPixels;
        demoTileRenderData->texturePositionInPixels.y = position.y - 0.40*optics->_squareTileSideLengthInPixels;
        demoTileRenderData->textureDimensionsInPixels.x = 1.5*optics->_squareTileSideLengthInPixels;
        demoTileRenderData->textureDimensionsInPixels.y = 1.8*optics->_squareTileSideLengthInPixels;

    demoTileRenderData->tileColor = COLOR_YELLOW;
    demoTileRenderData->angle = angle;
    return demoTileRenderData;
}

- (TextureRenderData *)renderTapToRotatePromptText:(vector_int2)position angle:(enum eObjectAngle)angle {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *demoTileTextureData = [backgroundTextureDataArray objectAtIndex:TAP_TO_ROTATE_TEXT];
    TextureRenderData *demoTileRenderData = [[TextureRenderData alloc] init];

    demoTileRenderData.renderTexture = demoTileTextureData.texture;
    demoTileRenderData->texturePositionInPixels.x = position.x - 1.5*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->texturePositionInPixels.y = position.y - 1.5*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->textureDimensionsInPixels.x = 4.0*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->textureDimensionsInPixels.y = 4.0*optics->_squareTileSideLengthInPixels;
    demoTileRenderData->tileColor = COLOR_YELLOW;
    demoTileRenderData->angle = angle;
    return demoTileRenderData;
}

// This method draws a yellow circle around movable Tiles and places a cyan checkmark
// on Tiles that are correctly positioned
- (TextureRenderData *)renderMovableTile:(vector_int2)position placedUsingHint:(BOOL)hint placedManuallyMatchesHint:(BOOL)mhint
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;

    TextureData *movableTileTextureData = [backgroundTextureDataArray objectAtIndex:OVERLAY_TILE_OUTLINE];
    TextureRenderData *movableTileRenderData = [[TextureRenderData alloc] init];
    movableTileRenderData.renderTexture = movableTileTextureData.texture;
    movableTileRenderData->texturePositionInPixels = position;
    movableTileRenderData->textureDimensionsInPixels.x = optics->_squareTileSideLengthInPixels;
    movableTileRenderData->textureDimensionsInPixels.y = optics->_squareTileSideLengthInPixels;
    
    TextureData *fixedTileCheckmarkTextureData = [backgroundTextureDataArray objectAtIndex:TILE_CHECKMARK];
    TextureRenderData *fixedTileRenderData = [[TextureRenderData alloc] init];
    fixedTileRenderData.renderTexture = fixedTileCheckmarkTextureData.texture;
    fixedTileRenderData->texturePositionInPixels = position;
    fixedTileRenderData->textureDimensionsInPixels.x = optics->_squareTileSideLengthInPixels;
    fixedTileRenderData->textureDimensionsInPixels.y = optics->_squareTileSideLengthInPixels;

    if (!hint && !mhint){
        movableTileRenderData->tileColor = COLOR_YELLOW;
        return movableTileRenderData;
    }
    else{
        fixedTileRenderData->tileColor = COLOR_CYAN;
        return fixedTileRenderData;
    }
}

- (TextureRenderData *)renderTutorialTilePathArrow:(vector_int2)startPosition end:(vector_int2)endPosition textureRenderData:(TextureRenderData *)arrowTextureRenderData
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];

    // Fetch the arrow image data
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *arrowTextureData = [backgroundTextureDataArray objectAtIndex:SINGLE_ARROW_1];
    arrowTextureRenderData.renderTexture = arrowTextureData.texture;

    // Largely copied from [Beam renderBeam]
    arrowTextureRenderData->texturePositionInPixels = [self arrowPositionInPixels:startPosition end:endPosition];
    arrowTextureRenderData->textureDimensionsInPixels = [self arrowDimensionsInPixels:startPosition end:endPosition];
    arrowTextureRenderData->tileColor = COLOR_YELLOW;
    arrowTextureRenderData->arrowAngle = [self arrowAngle:startPosition end:endPosition];

    return arrowTextureRenderData;
}


- (CGFloat)arrowAngle:(vector_int2)arrowStart end:(vector_int2)arrowEnd {
    CGFloat angle, dx, dy;
    vector_int2 s = [self gridPositionToIntPixelPosition:arrowStart];
    vector_int2 e = [self gridPositionToIntPixelPosition:arrowEnd];
    dx = e.x - s.x;
    dy = e.y - s.y;
    angle = -atan(dy/dx);
    if (dx < 0){
        angle = angle + PI;
    }
    return angle;
}


- (vector_int2)arrowPositionInPixels:(vector_int2)arrowStart end:(vector_int2)arrowEnd {
    vector_int2 c, d, p;
    c = [self arrowCenterInPixels:arrowStart end:arrowEnd];
    d = [self arrowDimensionsInPixels:arrowStart end:arrowEnd];
    p.x = c.x - d.x/2.0;
    p.y = c.y - d.y/2.0;
    return p;
}


- (vector_int2)arrowCenterInPixels:(vector_int2)arrowStart end:(vector_int2)arrowEnd {
    vector_int2 c;
    vector_int2 s = [self gridPositionToIntPixelPosition:arrowStart];
    vector_int2 e = [self gridPositionToIntPixelPosition:arrowEnd];
    c.x = (s.x + e.x)/2.0;
    c.y = (s.y + e.y)/2.0;
    return c;
}


- (vector_int2)arrowDimensionsInPixels:(vector_int2)arrowStart end:(vector_int2)arrowEnd {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    vector_int2 d;
    vector_int2 s = [self gridPositionToIntPixelPosition:arrowStart];
    vector_int2 e = [self gridPositionToIntPixelPosition:arrowEnd];
    float length = sqrt((s.x-e.x)*(s.x-e.x) + (s.y-e.y)*(s.y-e.y));
    d.x = length;
    d.y = 1.414*optics->_squareTileSideLengthInPixels;
    return d;
}


- (vector_int2)gridPositionToIntPixelPosition:(vector_int2)g {
     BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    vector_int2 p;
    // Beams start and end at centers of tiles
    p.x = (g.x * optics->_squareTileSideLengthInPixels) + optics->_squareTileSideLengthInPixels/2.0 + optics->_tileHorizontalOffsetInPixels;
    p.y = (g.y * optics->_squareTileSideLengthInPixels) + optics->_squareTileSideLengthInPixels/2.0 + optics->_tileVerticalOffsetInPixels;
    return p;
}


@end
