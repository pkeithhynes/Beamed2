//
//  Foreground.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 2/13/21.
//  Copyright © 2021 Apple. All rights reserved.
//

#import "Foreground.h"

@implementation Foreground

- (Foreground *)init {
    animationFrame = 0;
    runningAnimationFrame = 0;
    return self;
}

// Render an array of energized jewel rings
- (NSMutableArray *)renderIdleJewelRingArray:(NSMutableArray *)ringArray
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *ringTextureDataArray = appDelegate.ringAnimationContainers;
    NSMutableArray *frameArray = [[[ringTextureDataArray objectAtIndex:0] objectAtIndex:ANGLE0] objectAtIndex:RING_EXPANDING];
    
    animationFrame++;
    if (animationFrame >= [frameArray count])
        animationFrame = 0;
    runningAnimationFrame++;
    
    TextureRenderData *ringRenderData;
    TextureData *ringTextureData;
    
    // Go through every tile
    NSMutableArray *tiles = optics->tiles;
    NSEnumerator *tileEnum = [tiles objectEnumerator];
    Tile *aTile = nil;
    while (aTile = [tileEnum nextObject]) {
        if (aTile->tileShape == TILE_AC_JEWEL && !aTile->energized) {
            ringRenderData = [[TextureRenderData alloc] init];
            switch (aTile->tileColor){
                case COLOR_RED:{
                    ringTextureData = [frameArray objectAtIndex:animationFrame];
                    ringRenderData->tileColor = COLOR_RED;
                    break;
                }
                case COLOR_GREEN:{
                    ringTextureData = [frameArray objectAtIndex:(animationFrame + 4) % [frameArray count]];
                    ringTextureData = [frameArray objectAtIndex:animationFrame];
                    ringRenderData->tileColor = COLOR_GREEN;
                    break;
                }
                case COLOR_BLUE:{
                    ringTextureData = [frameArray objectAtIndex:(animationFrame + 8) % [frameArray count]];
                    ringTextureData = [frameArray objectAtIndex:animationFrame];
                    ringRenderData->tileColor = COLOR_BLUE;
                    break;
                }
                case COLOR_YELLOW:{
                    ringTextureData = [frameArray objectAtIndex:(animationFrame + 12) % [frameArray count]];
                    ringTextureData = [frameArray objectAtIndex:animationFrame];
                    if ((runningAnimationFrame / [frameArray count]) % 2 == 0){
                        ringRenderData->tileColor = COLOR_RED;
                    }
                    else {
                        ringRenderData->tileColor = COLOR_GREEN;
                    }
                    break;
                }
                case COLOR_MAGENTA:{
                    ringTextureData = [frameArray objectAtIndex:(animationFrame + 16) % [frameArray count]];
                    ringTextureData = [frameArray objectAtIndex:animationFrame];
                    if ((runningAnimationFrame / [frameArray count]) % 2 == 0){
                        ringRenderData->tileColor = COLOR_RED;
                    }
                    else {
                        ringRenderData->tileColor = COLOR_BLUE;
                    }
                    break;
                }
                case COLOR_CYAN:{
                    ringTextureData = [frameArray objectAtIndex:(animationFrame + 20) % [frameArray count]];
                    ringTextureData = [frameArray objectAtIndex:animationFrame];
                    if ((runningAnimationFrame / [frameArray count]) % 2 == 0){
                        ringRenderData->tileColor = COLOR_GREEN;
                    }
                    else {
                        ringRenderData->tileColor = COLOR_BLUE;
                    }
                    break;
                }
                case COLOR_WHITE:
                default:{
                    ringTextureData = [frameArray objectAtIndex:(animationFrame + 24) % [frameArray count]];
                    ringTextureData = [frameArray objectAtIndex:animationFrame];
                    if ((runningAnimationFrame / [frameArray count]) % 3 == 0){
                        ringRenderData->tileColor = COLOR_RED;
                    }
                    else if ((runningAnimationFrame / [frameArray count]) % 3 == 1) {
                        ringRenderData->tileColor = COLOR_GREEN;
                    }
                    else {
                        ringRenderData->tileColor = COLOR_BLUE;
                    }
                    break;
                }
                    
            }
            //            ringRenderData = [[TextureRenderData alloc] init];
            ringRenderData.renderTexture = ringTextureData.texture;
            ringRenderData->textureGridPosition = aTile->gridPosition;
            ringRenderData->textureDimensionsInPixels.x = 3.0*aTile->tileDimensionsInPixels.x;
            ringRenderData->textureDimensionsInPixels.y = 3.0*aTile->tileDimensionsInPixels.y;
            ringRenderData->texturePositionInPixels.x = aTile->tilePositionInPixels.x - ringRenderData->textureDimensionsInPixels.x/3.0;
            ringRenderData->texturePositionInPixels.y = aTile->tilePositionInPixels.y - ringRenderData->textureDimensionsInPixels.y/3.0;
            //            ringRenderData->tileColor = aTile->tileColor;
            ringRenderData->tileShape = aTile->tileShape;
            ringRenderData->angle = ANGLE0;
            ringRenderData->tile = aTile;
            
            [ringArray addObject:ringRenderData];
        }
    }
    return ringArray;
}

- (NSMutableArray *)renderPuzzleCompletedMarker:(NSMutableArray *)foregroundArray {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *puzzleCompleteCheckmarkTextureData = [backgroundTextureDataArray objectAtIndex:TILE_CHECKMARK];
    TextureRenderData *puzzleCompleteRenderData = [[TextureRenderData alloc] init];
    puzzleCompleteRenderData.renderTexture = puzzleCompleteCheckmarkTextureData.texture;
    puzzleCompleteRenderData->texturePositionInPixels.x = optics->gridTouchGestures.minPuzzleBoundary.x;
    puzzleCompleteRenderData->texturePositionInPixels.y = optics->gridTouchGestures.minPuzzleBoundary.y;
    puzzleCompleteRenderData->textureDimensionsInPixels.x = optics->_puzzleDisplayWidthInPixels;
    puzzleCompleteRenderData->textureDimensionsInPixels.y = optics->_puzzleDisplayWidthInPixels;
    
    [foregroundArray addObject:puzzleCompleteRenderData];
    return foregroundArray;
}

- (NSMutableArray *)renderPackCompletedMarker:(NSMutableArray *)foregroundArray {
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    Optics *optics = appDelegate->optics;
    
    NSMutableArray *backgroundTextureDataArray = appDelegate.backgroundTextures;
    TextureData *puzzleCompleteCheckmarkTextureData = [backgroundTextureDataArray objectAtIndex:PACK_COMPLETED];
    TextureRenderData *puzzleCompleteRenderData = [[TextureRenderData alloc] init];
    puzzleCompleteRenderData.renderTexture = puzzleCompleteCheckmarkTextureData.texture;
    puzzleCompleteRenderData->texturePositionInPixels.x = optics->gridTouchGestures.minPuzzleBoundary.x;
    puzzleCompleteRenderData->texturePositionInPixels.y = optics->gridTouchGestures.minPuzzleBoundary.y;
    puzzleCompleteRenderData->textureDimensionsInPixels.x = optics->_puzzleDisplayWidthInPixels;
    puzzleCompleteRenderData->textureDimensionsInPixels.y = optics->_puzzleDisplayWidthInPixels;
    
    [foregroundArray addObject:puzzleCompleteRenderData];
    return foregroundArray;
}

// Return a frame from the logo animation
- (TextureRenderData *)renderLogoFrame:(TextureRenderData *)logoRenderData
                            centerX:(CGFloat)centerX
                            centerY:(CGFloat)centerY
                              color:(unsigned int)colorNumber
                              sizeX:(CGFloat)sizeInPixelsX
                              sizeY:(CGFloat)sizeInPixelsY
                          syncFrame:(BOOL)syncFrame
                            stillFrame:(BOOL)stillFrame
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    BMDViewController *rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];

    NSMutableArray *logoTextureDataArray = appDelegate.logoAnimationContainers;
    NSMutableArray *frameArray = [[[logoTextureDataArray objectAtIndex:0] objectAtIndex:0] objectAtIndex:0];
    
    if (stillFrame){
        animationFrame = 0;
    }
    else {
        if (syncFrame){
            animationFrame = 0;
        }
        else {
            animationFrame++;
            if (animationFrame >= [frameArray count]){
                animationFrame = 0;
            }
        }
    }
    
    TextureData *logoTextureData;
    
    // Add ring texture
    logoRenderData = [[TextureRenderData alloc] init];
    logoRenderData->tileColor = colorNumber;
    logoTextureData = [frameArray objectAtIndex:animationFrame];
    
    logoRenderData.renderTexture = logoTextureData.texture;
    logoRenderData->textureGridPosition.x = 0;
    logoRenderData->textureGridPosition.y = 0;
    logoRenderData->textureDimensionsInPixels.x = sizeInPixelsX;
    logoRenderData->textureDimensionsInPixels.y = sizeInPixelsY;
    
    logoRenderData->texturePositionInPixels.x = centerX;
    logoRenderData->texturePositionInPixels.y = centerY;
    
    logoRenderData->tileShape = JEWEL;
    logoRenderData->angle = ANGLE0;
    logoRenderData->tile = nil;
    
    return logoRenderData;
}

// Render an array of rings that are not connected with any Jewel or Puzzle
- (NSMutableArray *)renderRingArray:(NSMutableArray *)ringArray
                           numberOfRings:(unsigned int)numberOfRings
                            centerX:(unsigned int)centerX
                            centerY:(unsigned int)centerY
                              color:(unsigned int)colorNumber
                              sizeX:(unsigned int)sizeInPixelsX
                              sizeY:(unsigned int)sizeInPixelsY
                          syncFrame:(BOOL)syncFrame
{
    BMDAppDelegate *appDelegate = (BMDAppDelegate *)[[UIApplication sharedApplication] delegate];
    BMDViewController *rc = (BMDViewController*)[[(BMDAppDelegate *)[[UIApplication sharedApplication]delegate] window] rootViewController];

    NSMutableArray *ringTextureDataArray = appDelegate.ringAnimationContainers;
    NSMutableArray *frameArray = [[[ringTextureDataArray objectAtIndex:0] objectAtIndex:ANGLE0] objectAtIndex:RING_EXPANDING];
    
    if (syncFrame){
        animationFrame = 0;
    }
    else {
        animationFrame++;
        if (animationFrame >= [frameArray count]){
            animationFrame = 0;
        }
    }
    
    TextureRenderData *ringRenderData, *jewelRenderData;
    TextureData *ringTextureData, *jewelTextureData;
    
    // Add ring texture
    ringRenderData = [[TextureRenderData alloc] init];
    ringRenderData->tileColor = colorNumber;
    ringTextureData = [frameArray objectAtIndex:animationFrame];
    
    ringRenderData.renderTexture = ringTextureData.texture;
    ringRenderData->textureGridPosition.x = 0;
    ringRenderData->textureGridPosition.y = 0;
    ringRenderData->textureDimensionsInPixels.x = sizeInPixelsX;
    ringRenderData->textureDimensionsInPixels.y = sizeInPixelsY;
    
    ringRenderData->texturePositionInPixels.x = centerX - ringRenderData->textureDimensionsInPixels.x/2;
    ringRenderData->texturePositionInPixels.y = centerY - ringRenderData->textureDimensionsInPixels.y/2;
    
    ringRenderData->tileShape = JEWEL;
    ringRenderData->angle = ANGLE0;
    ringRenderData->tile = nil;
    
    [ringArray addObject:ringRenderData];
    
    // Add jewel texture
    jewelRenderData = [[TextureRenderData alloc] init];
    jewelRenderData->tileColor = 7;
    jewelTextureData = [appDelegate.jewelTextures objectAtIndex:colorNumber];

    jewelRenderData.renderTexture = jewelTextureData.texture;
    jewelRenderData->textureGridPosition.x = 0;
    jewelRenderData->textureGridPosition.y = 0;
    jewelRenderData->textureDimensionsInPixels.x = 0.2*sizeInPixelsX;
    jewelRenderData->textureDimensionsInPixels.y = 0.2*sizeInPixelsY;
    
    jewelRenderData->texturePositionInPixels.x = centerX - jewelRenderData->textureDimensionsInPixels.x/2;
    jewelRenderData->texturePositionInPixels.y = centerY - jewelRenderData->textureDimensionsInPixels.y/2;
    
    jewelRenderData->tileShape = JEWEL;
    jewelRenderData->angle = ANGLE0;
    jewelRenderData->tile = nil;
    
    [ringArray addObject:jewelRenderData];
    return ringArray;
}

@end
