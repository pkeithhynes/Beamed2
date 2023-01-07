//
//  UIDemoButton.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 9/4/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import "UIDemoButton.h"

@implementation UIDemoButton

@synthesize nextPuzzle;
@synthesize finalPuzzle;

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (UIDemoButton *)init {
    self = [super init];
    nextPuzzle = NO;
    finalPuzzle = NO;
    return self;
}

@end
