//
//  GameControls.h
//  Beamed
//
//  Created by pkeithhynes on 8/5/10.
//  Copyright 2010 glimmerWave software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Definitions.h"
#import "Optics.h"
#import "Tile.h"
#import "BMDAppDelegate.h"

@class BMDAppDelegate;
@class Tile;
@class Background;
@class Beam;
@class TextureRenderData;

API_AVAILABLE(ios(13.0))
@interface GameControls : NSObject {
@private
    NSMutableArray  *gameControlTiles;
    TextureRenderData   *gameControlPrism;
    TextureRenderData   *gameControlBeamsplitter;
    TextureRenderData   *gameControlMirror;
    TextureRenderData   *gameControlJewel;
    TextureRenderData   *gameControlRectangle;
    TextureRenderData   *gameControlLaserRed;
    TextureRenderData   *gameControlLaserGreen;
    TextureRenderData   *gameControlLaserBlue;

}

- (NSMutableArray *)renderGameControls:(NSMutableArray *)gameControlTiles;
- (void)touchesBegan:(vector_int2)p;
- (void)touchesEnded:(vector_int2)p;

@end
