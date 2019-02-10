//
//  UCShareUrl.h
//  UC_Iphone
//
//  Created by winkle on 16/11/9.
//
//

#import <Foundation/Foundation.h>

@interface UCShareURL : NSObject
@property (nonatomic, strong) NSMutableArray *arrUrl;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *thumbPath;
@property (atomic, strong) NSNumber *flag;

- (NSString *)composeString;
@end
