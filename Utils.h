//
//  Utils.h
//  UC_Iphone
//
//  Created by winkle on 16/11/9.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject

+ (NSString *)writeImage:(UIImage*)image;
+ (NSString *)writeFile:(NSString*)filePath;
+ (NSString *)URLEncodedString:(NSString *)str;
+ (NSString *)nameStringFromPaths:(NSArray *)arrPath;
+ (long long)getCurrentDate;

+ (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size;

@end
