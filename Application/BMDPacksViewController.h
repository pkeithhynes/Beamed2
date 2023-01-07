//
//  BMDPacksViewController.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/22/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface BMDPacksViewController : UIViewController {
    
@public
    UIView *packsView;
    UIView *contentView;
    UIScrollView *scrollView;
    NSMutableArray *puzzlePacksButtonsArray;
    NSMutableArray *puzzlePacksLockIconsArray;
}

@property (nonatomic, retain) UIView *packsView;
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIView *scrollView;
@property (nonatomic, retain) NSMutableArray *puzzlePacksButtonsArray;
@property (nonatomic, retain) NSMutableArray *puzzlePacksLockIconsArray;


- (void)updateOnePackButtonTitle:(int)packDisplayIndex
                      packNumber:(int)packNumber
                          button:(UIButton *)button;

- (void)highlightCurrentlySelectedPack;

- (void)unHighlightAllPacks;

@end

NS_ASSUME_NONNULL_END
