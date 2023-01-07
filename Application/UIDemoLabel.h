//
//  UIDemoLabel.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 7/30/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDemoLabel : UILabel {
@public
    BOOL dragTile;
    BOOL tapTile;
    BOOL puzzleComplete;
}

@property (readwrite) BOOL dragTile;
@property (readwrite) BOOL tapTile;
@property (readwrite) BOOL puzzleComplete;

- (UIDemoLabel *)init;
@end

NS_ASSUME_NONNULL_END

