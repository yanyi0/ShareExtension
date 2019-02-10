//
//  Utils.m
//  UC_Iphone
//
//  Created by winkle on 16/11/9.
//
//

#import "Utils.h"
#import <CoreFoundation/CoreFoundation.h>

#ifndef APP_GROUP_NAME
//#define APP_GROUP_NAME [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UCGroup"]
#define APP_GROUP_NAME @"group.cn.com.mengniu.oa.sharextension"
#endif

@implementation Utils
+(NSString*)writeFile:(NSString*)filePath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        return nil;
    }
    
    NSString *fname = [NSString stringWithFormat:@"%@", [filePath lastPathComponent]];
    NSString* docpath = [self getGroupURL];
    docpath = [docpath stringByAppendingPathComponent:fname];

    NSError *error = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:docpath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:docpath error:&error];
    }
    
    BOOL bRet = [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:docpath error:&error];
   
    return [Utils URLEncodedString:docpath];
}

+(NSString*)writeImage:(UIImage*)image
{
    if (!image || ![image isKindOfClass:[UIImage class]]) {
        return nil;
    }
    
    //save image to file and return its file URI
    NSString* docpath = [self getGroupURL];
    NSString* fname = [NSString stringWithFormat:@"%ld.jpg", (NSInteger)[[NSDate date] timeIntervalSince1970]*1000000];
    
    docpath = [docpath stringByAppendingPathComponent:fname];
    
    BOOL bRet = [UIImageJPEGRepresentation(image,1.0) writeToFile:docpath
                                              options:NSDataWritingAtomic
                                                error:nil];
    return docpath;
}

+ (NSString *)getGroupURL {
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_NAME];
    
    containerURL = [containerURL URLByAppendingPathComponent:@"Library/Caches"];
    
    NSString *path = [containerURL path];
    
    if(![[NSFileManager defaultManager]fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [containerURL path];
}

+ (NSString *)nameStringFromPaths:(NSArray *)arrPath
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (int i=0; i<arrPath.count; i++)
    {
        NSURL *path = [arrPath objectAtIndex:i];
        
        if ([path isFileURL])
        {
            [arr addObject:[path lastPathComponent]];
        }
    }
    
    if (arr.count > 0)
    {
        return [arr componentsJoinedByString:@", "];
    }
    else
    {
        return nil;
    }
}

+ (NSString *)URLEncodedString:(NSString *)str
{
    return [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
}

+ (long long)getCurrentDate
{
    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval now = [dat timeIntervalSince1970]*1000;
    long long value = [[NSNumber numberWithDouble:now] longLongValue];
    
    //很多地方调用该方法都将返回的时间戳当做唯一key来使用，例如：msg_id, 图片名。
    //殊不知，当快速访问该方法时，返回的时间戳精确到毫秒也会重复。现针对已经发现的msg_id重复，
    //做如下调整(最小修改法，如有更简单的，请指出)，之后，该方法每次调用都将返回不同的时间戳，误差：1毫秒。
    //该修改理论上不会影响现有逻辑正确执行，如发现有不妥之处，请重新考量。
    //zhiwei.yu@2017-5-11
    static long long lastValue = -1;
    if (value <= lastValue) {
        value = lastValue + 1;
    }
    
    lastValue = value;
    
    return value;
}

+ (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size
{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}
@end
