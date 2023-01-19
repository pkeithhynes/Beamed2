//
//  Background.h
//  Beamed
//
//  Created by pkeithhynes on 7/14/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Definitions.h"
#import "BMDAppDelegate.h"
#import "BMDRenderer.h"
#import "Optics.h"

@class BMDRenderer;
@class Optics;
@class TextureRenderData;

API_AVAILABLE(ios(13.0))
@interface Background : UIView
{
@public
    TextureRenderData     *borderRenderData;
    TextureRenderData     *backgroundRenderDataOuter;
    TextureRenderData     *backgroundRenderDataInner;
    TextureRenderData     *backgroundRenderDataImage;
    TextureRenderData     *backgroundRenderAnimationImage;
    TextureRenderData     *unusedTileBackgroundRenderData;
    NSUInteger            animationFrame;            // Pointer to the current frame of the animation
@private
}

- (TextureRenderData *)renderBorder:(enum eTileColors)color;
- (TextureRenderData *)renderBackgroundImage:(unsigned int)backgroundColor;
- (TextureRenderData *)renderOverlayImage:(unsigned int)imageIndex color:(unsigned int)backgroundColor;
- (TextureRenderData *)renderBackgroundAnimations:(uint16_t)frameCounter
                                  backgroundColor:(unsigned int)backgroundColor;
- (TextureRenderData *)renderBackgroundInner:(unsigned int)backgroundColor;
- (TextureRenderData *)renderBackgroundOuter:(unsigned int)backgroundColor;
- (TextureRenderData *)renderUnusedTileBackground:(unsigned int)backgroundColor numberOfUnplacedTiles:(unsigned int)numberOfUnplacedTiles initialNumberOfUnplacedTiles:(unsigned int)initialNumberOfUnplacedTiles;
- (NSMutableArray *)renderBackgroundArray:(NSMutableArray *)backgroundArray tileColor:(unsigned int)tileColor numberOfUnplacedTiles:(unsigned int)numberOfUnplacedTiles puzzleCompleted:(BOOL)puzzleCompleted;
- (TextureRenderData *)renderMovableTile:(vector_int2)position placedUsingHint:(BOOL)hint placedManuallyMatchesHint:(BOOL)mhint;
- (TextureRenderData *)renderTapToRotatePrompt:(vector_int2)position angle:(enum eObjectAngle)angle;
- (TextureRenderData *)renderTapToRotatePromptText:(vector_int2)position angle:(enum eObjectAngle)angle;
- (TextureRenderData *)renderDragPromptText:(vector_int2)position angle:(enum eObjectAngle)angle;
//- (TextureRenderData *)renderPointingFinger:(vector_int2)position angle:(enum eObjectAngle)angle;
- (TextureRenderData *)renderTutorialTilePathArrow:(vector_int2)startPosition end:(vector_int2)endPosition textureRenderData:(TextureRenderData *)textureRenderData;
@end
