#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef enum _IAPProductsRequestResultFormat {
    IAPProductsRequestResultFormatDefault,
    IAPProductsRequestResultFormatLocalized,
} IAPProductsRequestResultFormat;

@interface IAPProductsRequestClient : NSObject <SKProductsRequestDelegate>

@property (readonly) BOOL processing;

- (void)startRequestWithProductIdentifiers:(NSArray *)productIdentifiers resultFormat:(IAPProductsRequestResultFormat)resultFormat;

@end
