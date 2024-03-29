#import "MRAuthService.h"
#import "MRRequester.h"
#import "MRUserData.h"
#import "MRError.h"
#import "CocoaSecurity.h"
#import "MRValidateUtils.h"

@implementation MRAuthService {

}

- (void)authWithPhone:(NSString *)phone andPassword:(NSString *)password block:(void (^)(NSError *error))block {
    [MRRequester doGetRequest:API_GET_AUTH_CODE params:@{
            @"phone" : phone
    } block:^(id result, NSError *error) {
        if (!error) {
            id schema = [MRValidateUtils getSchemaWithData:@{}];
            id validatedJson = [schema validateJson:result error:&error];
            if (!error) {
                NSDictionary *dictionary = (NSDictionary *)result;
                if (![dictionary[@"error"] isEqualToString:API_ERROR_SUCCESS]) {
                    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                    [errorDetails setValue:dictionary[@"msg"] forKey:NSLocalizedDescriptionKey];
                    error = [NSError errorWithDomain:MRAppDomain code:MRLogginError userInfo:errorDetails];
                } else {
                    NSString *authCode = dictionary[@"data"][@"code"];
                    CocoaSecurityResult *md5 = [CocoaSecurity md5:[password stringByAppendingString:HARDWARE_SALT]];
                    NSString *hashedPass = [md5 hexLower];
                    md5 = [CocoaSecurity md5:[hashedPass stringByAppendingString:authCode]];
                    hashedPass = [md5 hexLower];
                    [MRRequester doGetRequest:API_GET_ACCESS_TOKEN params:@{
                            @"phone" : phone,
                            @"pass" : hashedPass
                    }                   block:^(id result, NSError *error) {
                        if (!error) {
                            id schema = [MRValidateUtils getSchemaWithData:@{}];
                            id validatedJson = [schema validateJson:result error:&error];
                            if (!error) {
                                NSDictionary *dictionary = (NSDictionary *)result;
                                if ([dictionary[@"error"] isEqualToString:API_ERROR_SUCCESS]) {
                                    [_userData setFromData:dictionary[@"data"]];
                                    [_userData saveToUserDefaults];
                                } else {
                                    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                                    [errorDetails setValue:dictionary[@"msg"] forKey:NSLocalizedDescriptionKey];
                                    error = [NSError errorWithDomain:MRAppDomain code:MRLogginError userInfo:errorDetails];
                                }
                            }
                        }
                        if (error) {
                            NSLog(@"API_GET_ACCESS_TOKEN error:\n%@", error.userInfo);
                        }
                        block(error);

                    }];
                }
            }
        }
        if (error) {
            NSLog(@"API_GET_AUTH_CODE error:\n%@", error.userInfo);
            block(error);
        }
    }];
}

- (void)registerWithPhone:(NSString *)phone
               andCarType:(NSString *)carType
              andCarModel:(NSString *)carModel
              andCarColor:(NSString *)carColor
             andCarNumber:(NSString *)carNumber
                    block:(void (^)(NSError *error))block {
    [MRRequester doPostRequest:API_REGISTER params:@{
            @"phone" : phone,
            @"carType" : carType,
            @"carModel" : carModel,
            @"carColor" : carColor,
            @"carNumber" : carNumber,
    } block:^(id result, NSError *error) {
        if (!error) {
            id schema = [MRValidateUtils getSchemaWithData:@{}];
            id validatedJson = [schema validateJson:result error:&error];
            if (!error) {
                NSDictionary *dictionary = (NSDictionary *)result;
                if (![dictionary[@"error"] isEqualToString:API_ERROR_SUCCESS]) {
                    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                    [errorDetails setValue:dictionary[@"msg"] forKey:NSLocalizedDescriptionKey];
                    error = [NSError errorWithDomain:MRAppDomain code:MRRegistrationError userInfo:errorDetails];
                } else {
                    NSLog(@"Password: %@", dictionary[@"data"][@"password"]);
                }
            }
        }
        if (error) {
            NSLog(@"API_REGISTER error:\n%@", error.userInfo);
        }
        block(error);
    }];
}

@end