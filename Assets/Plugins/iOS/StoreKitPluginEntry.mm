#import <Foundation/Foundation.h>
#import "IAPTransactionObserver.h"
#import "IAPProductsRequestClient.h"


static IAPTransactionObserver *observer;
static IAPProductsRequestClient *client;


#pragma mark - Utility Function


extern void UnitySendMessage(const char *, const char *, const char *);

#define UnityStringFromNSString( _x_ ) ( _x_ != NULL && [_x_ isKindOfClass:[NSString class]] ) ? strdup( [_x_ UTF8String] ) : NULL
#define NSStringFromUnityString( _x_ ) ( _x_ != NULL ) ? [[NSString alloc] initWithCString:_x_ encoding:NSUTF8StringEncoding] : [NSString stringWithUTF8String:""]

NSArray *_StoreKitNSArrayFromStringArray(const char **unityStringArray);
NSArray *_StoreKitNSArrayFromStringArray(const char **unityStringArray)
{
    int i = 0;
    NSMutableArray *stringArrayConstructor = [NSMutableArray array];
    for (i = 0; unityStringArray[i] != NULL; ++i) {
        [stringArrayConstructor addObject:NSStringFromUnityString(unityStringArray[i])];
    }
    NSArray *stringArray = [NSArray arrayWithArray:stringArrayConstructor];
    return stringArray;
}


#pragma mark Plug-in Function


extern "C" void _StoreKitInstall()
{
    if (observer == nil) {
        observer = [[IAPTransactionObserver alloc] init];
    }
    if (client == nil) {
        client = [[IAPProductsRequestClient alloc] init];
    }
}

extern "C" bool _StoreKitIsAvailable()
{
    return observer.available;
}

extern "C" bool _StoreKitIsProcessing()
{
    return observer.processing;
}

extern "C" void _StoreKitBuy(const char *productIdentifier)
{
    [observer queuePayment:NSStringFromUnityString(productIdentifier)];
}

extern "C" void _StoreKitRequestProductPriceString(const char **productIdentifiers)
{
    NSArray *array = _StoreKitNSArrayFromStringArray(productIdentifiers);
    [client startRequestWithProductIdentifiers:array resultFormat:IAPProductsRequestResultFormatDefault];
}

extern "C" void _StoreKitRequestProductLocalizedPriceString(const char **productIdentifiers)
{
    NSArray *array = _StoreKitNSArrayFromStringArray(productIdentifiers);
    [client startRequestWithProductIdentifiers:array resultFormat:IAPProductsRequestResultFormatLocalized];
}
