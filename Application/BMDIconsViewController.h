//
//  BMDIconsViewController.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 3/23/23.
//  Copyright © 2023 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMDIconsViewController : UIViewController {
    
@public
    UIView *iconsView;
    NSMutableArray *alternateIconsArray;
    NSMutableArray *alternateIconsButtonsArray;
}

@property (nonatomic, retain) UIView *iconsView;
@property (nonatomic, retain) NSMutableArray *alternateIconsArray;
@property (nonatomic, retain) NSMutableArray *alternateIconsButtonsArray;

@end

NS_ASSUME_NONNULL_END
