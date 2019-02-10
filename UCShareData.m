//
//  UCShareUrl.m
//  UC_Iphone
//
//  Created by winkle on 16/11/9.
//
//

#import "UCShareData.h"
#import "Utils.h"

@implementation UCShareURL

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        self.flag = [NSNumber numberWithInt:0];
        self.arrUrl = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSString *)composeString
{
    NSString *urlString = @"";
    if (self.arrUrl.count > 0)
    {
        urlString = [self.arrUrl componentsJoinedByString:@","];
    }
    
    if (!self.thumbPath)
    {
        self.thumbPath = @"";
    }
    
    if (!self.text)
    {
        self.text = @"";
    }
    
    NSString *strRet = [NSString stringWithFormat:@"%@:&:%@:&:%@", [Utils URLEncodedString:urlString], [Utils URLEncodedString:self.thumbPath], [Utils URLEncodedString:self.text]];
    return strRet;
}

@end
