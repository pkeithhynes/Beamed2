//
//  TileHint.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 4/13/21.
//  Copyright © 2021 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Definitions.h"
#import "BMDShaderTypes.h"
#import "Tile.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface TileHint : NSObject {
    @public
    enum eObjectAngle   hintAngle;
    enum eTileShape     hintShape;
    vector_int2         hintPosition;
    BOOL hintUsed;
    Tile *hintTile;
}

@property (readwrite) enum eObjectAngle hintAngle;
@property (readwrite) enum eTileShape  hintShape;
@property (readwrite) vector_int2 hintPosition;
@property (readwrite) BOOL hintUsed;
@property (nonatomic, retain) Tile * hintTile;

- (TileHint *)initWithParameters:(Tile *)tile position:(vector_int2)position hintAngle:(enum eObjectAngle)angle hintShape:(enum eTileShape)shape hintUsed:(BOOL)used;
@end

NS_ASSUME_NONNULL_END
