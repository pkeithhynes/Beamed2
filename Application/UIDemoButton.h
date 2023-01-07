//
//  UIDemoButton.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 9/4/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDemoButton : UIButton {
@public
    BOOL nextPuzzle;
    BOOL finalPuzzle;
}

@property (readwrite) BOOL nextPuzzle;
@property (readwrite) BOOL finalPuzzle;

- (UIDemoButton *)init;
@end

NS_ASSUME_NONNULL_END
