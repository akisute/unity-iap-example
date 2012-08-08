#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface IAPTransactionObserver : NSObject <SKPaymentTransactionObserver> {
    BOOL availability_;
}

@property (readonly) BOOL available;
@property (readonly) BOOL processing;

- (void)queuePayment:(NSString *)productIdentifier;
- (void)storeTransaction:(SKPaymentTransaction *)transaction;

@end
