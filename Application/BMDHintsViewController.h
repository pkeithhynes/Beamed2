//
//  BMDHintsViewController.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 8/12/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface BMDHintsViewController : UIViewController{
    
    @public
    UIView *hintsView;
    UILabel *hintsViewLabel;
    NSMutableArray *hintPacksButtonsArray;

}

@property (nonatomic, retain) UIView *hintsView;
@property (nonatomic, retain) UIView *hintsViewLabel;
@property (nonatomic, retain) NSMutableArray *hintPacksButtonsArray;

- (void)updateHintsViewLabel;
- (void)backButtonPressed;

@end

NS_ASSUME_NONNULL_END
