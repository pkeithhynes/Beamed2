//
//  TileHint.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 4/13/21.
//  Copyright © 2021 Apple. All rights reserved.
//

#import "TileHint.h"

@implementation TileHint

@synthesize hintShape;
@synthesize hintAngle;
@synthesize hintPosition;
@synthesize hintUsed;
@synthesize hintTile;

- (TileHint *)initWithParameters:(Tile *)tile position:(vector_int2)position hintAngle:(enum eObjectAngle)angle hintShape:(enum eTileShape)shape hintUsed:(BOOL)used  API_AVAILABLE(ios(13.0)){
    hintShape = shape;
    hintPosition = position;
    hintAngle = angle;
    hintUsed = used;
    hintTile = tile;
    return self;
}

@end
