//
//  StoreObserver.h
//  Beamed
//
//  Created by Patrick Keith-Hynes on 6/10/21.
//  Copyright © 2021 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StoreObserver : NSObject <SKPaymentTransactionObserver>

@end

NS_ASSUME_NONNULL_END
