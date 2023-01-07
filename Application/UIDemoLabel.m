//
//  UIDemoLabel.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 7/30/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "UIDemoLabel.h"

@implementation UIDemoLabel

@synthesize dragTile;
@synthesize tapTile;
@synthesize puzzleComplete;


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (UIDemoLabel *)init {
    self = [super init];
    dragTile = NO;
    tapTile = NO;
    puzzleComplete = NO;
    return self;
}

@end
