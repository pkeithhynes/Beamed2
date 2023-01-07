//
//  Controls.m
//  Beamed
//
//  Created by Patrick Keith-Hynes on 12/30/20.
//  Copyright © 2020 Apple. All rights reserved.
//

#import "Controls.h"
#import "BMDViewController.h"

@implementation Controls
{
    UIView *viewTop;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (Controls *)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
 
    viewTop = [UIView new];
    viewTop.translatesAutoresizingMaskIntoConstraints = NO;
    viewTop.backgroundColor = [UIColor colorWithRed:0.95 green:0.47 blue:0.48 alpha:1.0];
    [self addSubview:viewTop];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Press Me" forState:UIControlStateNormal];
    [button sizeToFit];

    // Set a new (x,y) point for the button's center
    button.center = CGPointMake(320/2, 60);

    [self addSubview:button];

    return self;
}


@end
