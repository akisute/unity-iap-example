#import "IAPProductsRequestClient.h"


#pragma mark - Utility Function


extern void UnitySendMessage(const char *, const char *, const char *);

#define UnityStringFromNSString( _x_ ) ( _x_ != NULL && [_x_ isKindOfClass:[NSString class]] ) ? strdup( [_x_ UTF8String] ) : NULL
#define NSStringFromUnityString( _x_ ) ( _x_ != NULL ) ? [[NSString alloc] initWithCString:_x_ encoding:NSUTF8StringEncoding] : [NSString stringWithUTF8String:""]


#pragma mark -


@interface IAPProductsRequestClient ()
@property (nonatomic, retain) SKProductsRequest *request;
@property (nonatomic, retain) NSArray *requestingProductIdentifiers;
@property (nonatomic) IAPProductsRequestResultFormat resultFormat;
@end

@implementation IAPProductsRequestClient

- (void)dealloc
{
    self.requestingProductIdentifiers = nil;
    [super dealloc];
}

- (BOOL)processing
{
    return ([self.requestingProductIdentifiers count] > 0);
}

- (void)startRequestWithProductIdentifiers:(NSArray *)productIdentifiers resultFormat:(IAPProductsRequestResultFormat)resultFormat
{
    if (self.processing) {
        return;
    }
    
    self.requestingProductIdentifiers = productIdentifiers;
    self.resultFormat = resultFormat;
    self.request = [[[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:self.requestingProductIdentifiers]] autorelease];
    self.request.delegate = self;
    [self.request start];
}


#pragma mark -


- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    NSMutableString *buffer = [NSMutableString string];
    for (SKProduct *product in response.products) {
        if ([buffer length] > 0) {
            [buffer appendString:@"|"];
        }
        NSString *priceString = nil;
        if (self.resultFormat == IAPProductsRequestResultFormatDefault) {
            priceString = [product.price description];
        } else if (self.resultFormat == IAPProductsRequestResultFormatLocalized) {
            [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
            [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            [numberFormatter setLocale:product.priceLocale];
            priceString = [numberFormatter stringFromNumber:product.price];
        }
        [buffer appendFormat:@"%@:%@", product.productIdentifier, priceString];
    }
    UnitySendMessage(UnityStringFromNSString(@"StoreKit"),
                     UnityStringFromNSString(@"RequestProductPriceFinished"),
                     UnityStringFromNSString(buffer));
    self.requestingProductIdentifiers = nil;
    self.request.delegate = nil;
    self.request = nil;
}

@end
