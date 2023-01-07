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

@end
