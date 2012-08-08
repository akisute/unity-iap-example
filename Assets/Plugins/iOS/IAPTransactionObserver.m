#import "IAPTransactionObserver.h"
#import "NSData-Base64.h"

@implementation IAPTransactionObserver

@synthesize available = availability_;

- (id)init {
    if ((self = [super init])) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        availability_ = [SKPaymentQueue canMakePayments];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark - Property

- (BOOL)processing {
    return [SKPaymentQueue defaultQueue].transactions.count > 0;
}

#pragma mark - Common Payment Function

- (void)queuePayment:(NSString *)productIdentifier {
     SKPayment *payment = [SKPayment paymentWithProductIdentifier:productIdentifier];
     [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - Utility Function

- (void)storeTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionReceiptBase64String = [transaction.transactionReceipt base64EncodedString];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [NSString stringWithFormat:@"StoreKitReceipts-%@", transaction.payment.productIdentifier];
    NSString *receiptBase64CommaDelimitedString = [defaults stringForKey:key];
    if ([receiptBase64CommaDelimitedString length] > 0) {
        [defaults setObject:[NSString stringWithFormat:@"%@,%@", transactionReceiptBase64String, receiptBase64CommaDelimitedString] forKey:key];
        [defaults synchronize];
    } else {
        [defaults setObject:transactionReceiptBase64String forKey:key];
        [defaults synchronize];
    }
}

#pragma mark - SKTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        if (transaction.transactionState == SKPaymentTransactionStatePurchased) {
            // Completed.
            NSLog(@"Purchased - %@", transaction.payment.productIdentifier);
            [self storeTransaction:transaction];
            [queue finishTransaction:transaction];
            // TODO: SendMessage
        } else if (transaction.transactionState == SKPaymentTransactionStateFailed) {
            // Failed.
            NSLog(@"Failed - %@ (%@)", transaction.payment.productIdentifier, transaction.error);
            // TODO: remove this alert
            if (transaction.error.code != SKErrorPaymentCancelled) {
                [[[UIAlertView alloc] initWithTitle:@"Payment Error" message:transaction.error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            }
            [queue finishTransaction:transaction];
            // TODO: SendMessage
        } else if (transaction.transactionState == SKPaymentTransactionStateRestored) {
            // Restored.
            NSLog(@"Restored - %@", transaction.payment.productIdentifier);
            [self storeTransaction:transaction];
            [queue finishTransaction:transaction];
            // TODO: SendMessage
        }
    }
}

@end
