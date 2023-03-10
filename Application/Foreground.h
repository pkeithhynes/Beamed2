//
//  Foreground.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 2/13/21.
//  Copyright © 2021 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Definitions.h"
#import "BMDAppDelegate.h"
#import "BMDRenderer.h"
#import "Optics.h"

@class BMDRenderer;
@class Optics;
@class TextureRenderData;

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface Foreground : UIView
{
@public
    TextureRenderData     *foregroundRenderData;
@private
    NSUInteger           animationFrame;            // Pointer to the current frame of the animation
    NSUInteger           runningAnimationFrame;     // Pointer to a running (unconstrained) current frame of the animation
}

- (NSMutableArray *)renderIdleJewelRingArray:(NSMutableArray *)ringArray;
- (NSMutableArray *)renderPuzzleCompletedMarker:(NSMutableArray *)foregroundArray;
- (NSMutableArray *)renderPackCompletedMarker:(NSMutableArray *)foregroundArray;
- (NSMutableArray *)renderRingArray:(NSMutableArray *)ringArray
                           numberOfRings:(unsigned int)numberOfRings
                            centerX:(unsigned int)centerX
                            centerY:(unsigned int)centerY
                              color:(unsigned int)colorNumber
                              sizeX:(unsigned int)sizeInPixelsX
                              sizeY:(unsigned int)sizeInPixelsY
                          syncFrame:(BOOL)syncFrame;
- (TextureRenderData *)renderLogoFrame:(TextureRenderData *)logoRenderData
                            centerX:(CGFloat)centerX
                            centerY:(CGFloat)centerY
                              color:(unsigned int)colorNumber
                              sizeX:(CGFloat)sizeInPixelsX
                              sizeY:(CGFloat)sizeInPixelsY
                             syncFrame:(BOOL)syncFrame
                            stillFrame:(BOOL)stillFrame;

@end


NS_ASSUME_NONNULL_END
