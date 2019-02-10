//
//  UCShareViewController.m
//  TestAlert
//
//  Created by winkle on 16/12/30.
//  Copyright © 2016年 zhiwei.yu. All rights reserved.
//

#import "UCShareViewController.h"
#import "UCShareData.h"
#import "Utils.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define UC_CLIENT_URL    @"sharefile"
#define WIDTH_SCREEN    [UIScreen mainScreen].bounds.size.width
#define HEIGHT_SCREEN   [UIScreen mainScreen].bounds.size.height
#define margin_view 15
#define margin_content 8
#define width_thumb 80
#define url_flag  0x1
#define url_image 0x10
#define url_text  0x100
#define url_file  0x1000

@interface UCShareViewController()<UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>
{
    UITableView *tbl_Content;
    UIView *lineView;
    UIButton *postBtn;
    UIButton *cancelBtn;
    UITextView *label;
    UILabel *placeholder;
}

@property (atomic, strong) NSURL *url;
@property (atomic, strong) UIImage *thumb;
//@property (nonatomic, copy) NSURL *imagePath;
@property (atomic, strong) NSMutableArray *arrImagePath; //array of NSURL
@property (atomic, strong) NSMutableString *text;
@property (atomic, strong)  NSString *contentText;
@property (atomic, strong) NSNumber * flag;
@end

@implementation UCShareViewController

- (void)viewDidLoad
{
    [self parseContent];
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, WIDTH_SCREEN, HEIGHT_SCREEN);
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    //定义一个容器视图来存放分享内容和两个操作按钮
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(margin_view, 120, WIDTH_SCREEN-margin_view*2, 175)];
    container.layer.cornerRadius = 6;
    container.layer.borderColor = [UIColor clearColor].CGColor;
    container.layer.borderWidth = 1;
    container.layer.masksToBounds = YES;
    container.backgroundColor = [UIColor colorWithWhite:255 alpha:0.99];
    container.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    UIFont * font = [UIFont fontWithName:@"STHeitiSC-Medium" size:16];
    NSDictionary *attributes= @{
                                NSFontAttributeName: font,
                                };
    //定义Post和Cancel按钮
    cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelBtn.frame = CGRectMake(margin_content, 8, 65, 30);
    [cancelBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    NSAttributedString *attributedString = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"取消", nil) attributes:attributes];
    [cancelBtn setAttributedTitle:attributedString forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancelBtnClickHandler:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:cancelBtn];
    
    postBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    postBtn.frame = CGRectMake(container.frame.size.width - margin_content - 65, 8, 65, 30);
    [postBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    attributedString = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"发送", nil) attributes:attributes];
    [postBtn setAttributedTitle:attributedString forState:UIControlStateNormal];
    attributes= @{
                  NSFontAttributeName: font,
                  NSForegroundColorAttributeName: [UIColor grayColor],
                  };
    attributedString = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"发送", nil) attributes:attributes];
    [postBtn setAttributedTitle:attributedString forState:UIControlStateDisabled];
    [postBtn addTarget:self action:@selector(postBtnClickHandler:) forControlEvents:UIControlEventTouchUpInside];
     postBtn.enabled = NO;
    [container addSubview:postBtn];
   
    
    lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 42, WIDTH_SCREEN-margin_view*2, 0.5)];
    lineView.backgroundColor = [UIColor grayColor];
    [container addSubview:lineView];

    tbl_Content = [[UITableView alloc] initWithFrame:CGRectMake(0, lineView.frame.origin.y + lineView.frame.size.height, WIDTH_SCREEN-margin_view*2, container.frame.size.height - (lineView.frame.origin.y + lineView.frame.size.height))];
    [tbl_Content setDelegate:self];
    tbl_Content.dataSource = self;
    tbl_Content.separatorStyle = UITableViewCellSeparatorStyleNone;
    tbl_Content.allowsSelection = NO;
    
    if (@available(iOS 11.0, *)) {
        tbl_Content.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        tbl_Content.scrollIndicatorInsets = tbl_Content.contentInset;
        /// 自动关闭估算高度，不想估算那个，就设置那个即可
        tbl_Content.estimatedRowHeight = 0;
        tbl_Content.estimatedSectionHeaderHeight = 0;
        tbl_Content.estimatedSectionFooterHeight = 0;
    }
    
    
    UIFont * font_text = [UIFont fontWithName:@"STHeitiSC-Medium" size:14];
    label = [[UITextView alloc] init];
    [label setFont:font_text];
    label.textAlignment = NSTextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];
    [label setDelegate:self];
    placeholder = [[UILabel alloc] initWithFrame:CGRectMake(5, 7, 200, 20)];
    [placeholder setFont:font_text];
    [placeholder setTextColor:[UIColor grayColor]];
    placeholder.text = NSLocalizedString(@"写点什么...", nil);
    [label addSubview:placeholder];

    [container addSubview:tbl_Content];
  
  NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.cn.com.mengniu.oa.sharextension"];
  NSURL *fileURL = [groupURL URLByAppendingPathComponent:@"login.txt"];
  NSString *isLoginStatus = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
  //如果未登录提示登录
  if (isLoginStatus && [isLoginStatus isEqualToString:@"isNotLogin"]) {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"请先登录办随，再分享"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"确定"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                            UIResponder* responder = self;
                                                            while ((responder = [responder nextResponder]) != nil)
                                                            {
                                                              if([responder respondsToSelector:@selector(openURL:)] == YES)
                                                              {
                                                                [responder performSelector:@selector(openURL:) withObject:[NSURL URLWithString:@"sharefile://"]];
                                                              }
                                                              [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                                                            }
                                                          }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                           [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
                                                         }];
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
  }
  else//已登录加载发送框
  {
    [self.view addSubview:container];
  }
}

- (void)parseContent
{
    __block NSInteger count = 0;
    self.arrImagePath = [[NSMutableArray alloc] init];
    self.text = [[NSMutableString alloc]init];

   [self.extensionContext.inputItems enumerateObjectsUsingBlock:^(NSExtensionItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
       if (obj.attributedContentText.string.length > 0)
       {
           self.contentText = obj.attributedContentText.string;
       }
       
       [obj.attachments enumerateObjectsUsingBlock:^(NSItemProvider *  _Nonnull itemProvider, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"])
            {
                [itemProvider loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error) {
                    
                    if ([(NSObject *)item isKindOfClass:[NSURL class]])
                    {
                        self.url = (NSURL *)item;

                        NSInteger preValue = self.flag.integerValue;

                        if ([self.url isFileURL])
                        {
                            self.flag = [NSNumber numberWithInteger:(preValue|url_file)];
                        }
                        else
                        {
                            self.flag = [NSNumber numberWithInteger:(preValue|url_flag)];
                        }
                    }
                    
                    [self refreshView];
                }];
            }
           
           if ([itemProvider hasItemConformingToTypeIdentifier:@"public.image"])
            {
                [itemProvider loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:^(id item, NSError *error) {
                    
                    if ([item isKindOfClass:[NSURL class]])
                    {
                        [self.arrImagePath addObject:item];
                        NSInteger preValue = self.flag.integerValue;
                        self.flag = [NSNumber numberWithInteger:(preValue | url_image)];
                        [self refreshView];
                        count ++;
                    }
                    else if ([item isKindOfClass:[UIImage class]] && !self.thumb)
                    {
                        self.thumb = (UIImage *)item;
                        NSInteger preValue = self.flag.integerValue;
                        self.flag = [NSNumber numberWithInteger:(preValue | url_image)];
                        [self refreshView];
                        count ++;
                    }
                }];
            }
           
            if ([itemProvider hasItemConformingToTypeIdentifier:(__bridge NSString *)kUTTypeText])
            {
                NSInteger preValue = self.flag.integerValue;
                self.flag = [NSNumber numberWithInteger:(preValue|url_text)];
                
                [itemProvider loadItemForTypeIdentifier:(__bridge NSString *)kUTTypeText options:nil completionHandler:^(id item, NSError *error) {
                    
                    if ([item isKindOfClass:[NSString class]])
                    {
                        NSString *str = (NSString *)item;
                        
                        if ([str containsString:@"http://"] || [str containsString:@"https://"] || [str containsString:@"file:///"])
                        {
                            if (!self.url)
                            {
                                self.url = [NSURL URLWithString:str];
                                
                                if ([self.url isFileURL])
                                {
                                    self.flag = [NSNumber numberWithInteger:(preValue|url_file)];
                                }
                                else
                                {
                                    self.flag = [NSNumber numberWithInteger:(preValue|url_flag)];
                                }
                            }
                        }
                        else
                        {
                            [self.text appendString:str];
                            [self.text appendString:@"\n"];
                        }
                    }

                    [self refreshView];
                }];
            }
           
           if ([itemProvider hasItemConformingToTypeIdentifier:@"public.movie"])
           {
               [itemProvider loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:^(id<NSSecureCoding>  _Nullable item, NSError * _Null_unspecified error)
               {
                   NSInteger preValue = self.flag.integerValue;
                   NSURL *fileurl = (NSURL *)item;
                   if ([fileurl isFileURL])
                   {
                       self.flag = [NSNumber numberWithInteger:(preValue | url_file)];
                       self.url = fileurl;
                       [self refreshView];
                   }
               }];
           }
           
        }];
       
    }];
}

- (void)refreshView
{
    dispatch_async(dispatch_get_main_queue(), ^{
 
        if ((self.flag.integerValue&url_flag)==url_flag)
        {
            if ([self.url.absoluteString containsString:@"https://"]||[self.url.absoluteString containsString:@"http://"])
            {
                postBtn.enabled = YES;
            }
            else
            {
                postBtn.enabled = NO;
            }
        }
        else if ((self.flag.integerValue&url_file)==url_file)
        {
            postBtn.enabled = YES;
        }
        else if ((self.flag.integerValue&url_image)==url_image)
        {
            postBtn.enabled = YES;
        }
        else
        {
            postBtn.enabled = NO;
        }
        
        [tbl_Content reloadData];
    });
}

- (void)cancelBtnClickHandler:(id)sender
{
    //取消分享
    [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"CustomShareError" code:NSUserCancelledError userInfo:nil]];
}

- (void)postBtnClickHandler:(id)sender
{
    //执行分享内容处理
    UCShareURL *shareData = [[UCShareURL alloc]init];
    shareData.text = [label text];
    shareData.thumbPath = [Utils writeImage:self.thumb];
   
    if ((self.flag.integerValue&url_flag) == url_flag)
    {
        [shareData.arrUrl addObject:self.url.absoluteString];
    }
    else if((self.flag.integerValue&url_image) == url_image && self.arrImagePath.count > 0)
    {
        for (int i=0; i<self.arrImagePath.count; i++)
        {
            NSURL *url = [self.arrImagePath objectAtIndex:i];
            [shareData.arrUrl addObject:[NSString stringWithFormat:@"file://%@", [Utils writeFile:[url relativePath]]]];
        }
    }
    else if((self.flag.integerValue&url_file) == url_file)
    {
        [shareData.arrUrl addObject:[NSString stringWithFormat:@"file://%@", [Utils writeFile:self.url.path]]];
    }
    else if((self.flag.integerValue&url_image) == url_image && self.thumb)
    {
        [shareData.arrUrl addObject:[NSString stringWithFormat:@"file://%@", shareData.thumbPath]];
    }
    
    [self invokeBee:[shareData composeString]];
    [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
}

- (void)invokeBee:(NSString *)url
{
    NSString *test = UC_CLIENT_URL;
    NSURL * container = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/%@", UC_CLIENT_URL, [[NSBundle mainBundle] bundleIdentifier], url?url:@""]];
    
    UIResponder* responder = self;
    while ((responder = [responder nextResponder]) != nil)
    {
        if([responder respondsToSelector:@selector(openURL:)] == YES)
        {
            [responder performSelector:@selector(openURL:) withObject:container];
        }
    }
}


#pragma mark -------UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *view = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (view == nil)
    {
        view = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // display the thumb view
    UIImageView *thumbView = nil;
    CGFloat width_text = view.frame.size.width - margin_content*2;
    if (self.thumb)
    {
        thumbView = [[UIImageView alloc] initWithImage:self.thumb];
        [thumbView setFrame:CGRectMake(view.frame.size.width - margin_content - width_thumb, 15, width_thumb, width_thumb)];
        [view addSubview:thumbView];
        width_text -= (width_thumb + margin_content);
    }
    
    if (((self.flag.integerValue & url_image) == url_image) && ((self.flag.integerValue & url_file) == url_file))
    {
        [label setFrame:CGRectMake(margin_content,
                                   margin_content,
                                   width_text,
                                   view.frame.size.height - margin_content*2)];
        
        label.text = [NSString stringWithFormat:NSLocalizedString(@"抱歉，图片和视频无法同时分享。将默认分享图片。" , nil)];
        [label setEditable:NO];
        placeholder.hidden = YES;
        [view addSubview:label];
    }
    else if ((self.flag.integerValue & url_file) == url_file)
    {
        [label setFrame:CGRectMake(margin_content,
                                   margin_content,
                                   width_text,
                                   view.frame.size.height - margin_content*2)];
        
        label.text = [NSString stringWithFormat:NSLocalizedString(@"分享文档[%@]", nil), [self.url lastPathComponent]];
        [label setEditable:NO];
        placeholder.hidden = YES;
        [view addSubview:label];
    }
    else if ((self.flag.integerValue & url_flag) == url_flag || (self.flag.integerValue & url_text) == url_text)
    {
        [label setFrame:CGRectMake(margin_content,
                                  margin_content,
                                  width_text,
                                  view.frame.size.height - margin_content*2)];
        
        if ((self.flag.integerValue & url_flag) == url_flag)
        {
            if ([self.url.absoluteString containsString:@"http://"] || [self.url.absoluteString containsString:@"https://"])
            {
                NSMutableString *str = [self.text mutableCopy];
                
                if (str.length <= 0)
                {
                    str = [self.contentText mutableCopy];
                }
                
                if (str.length > 0)
                {
                    [str appendString:@"\n"];
                    [placeholder setHidden:YES];
                }
                else
                {
                    [placeholder setHidden:NO];
                }
                
                label.text =  str;
                [view addSubview:label];
            }
            else
            {
                UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(margin_content,
                                                                          margin_content,
                                                                          width_text,
                                                                          view.frame.size.height - margin_content*2)];
                warn.text = NSLocalizedString(@"不支持分享此种类型的文件", nil);
                [view addSubview:warn];
            }
        }
        else
        {
            label.text = self.text;
            [view addSubview:label];
        }
        
    }
    else if(self.arrImagePath.count > 0)
    {
        [label setFrame:CGRectMake(margin_content,
                                   margin_content,
                                   width_text,
                                   view.frame.size.height - margin_content*2)];
        
        label.text = [NSString stringWithFormat:NSLocalizedString(@"分享文档[%@]", nil), [Utils nameStringFromPaths:self.arrImagePath]];
        [label setEditable:NO];
        placeholder.hidden = YES;
        [view addSubview:label];
    }
    else if ((self.flag.integerValue & url_image) == url_image && self.thumb)
    {
        [thumbView removeFromSuperview];
        
        CGSize imgSize = self.thumb.size;
        CGFloat realHeight = view.frame.size.height - margin_content*2;
        CGFloat realWidth = view.frame.size.width - margin_content*2;
        CGSize realSize;
        
        if (realWidth >= (imgSize.width/imgSize.height)*realHeight)
        {
            realSize = CGSizeMake((imgSize.width/imgSize.height)*realHeight, realHeight);
        }
        else
        {
            realSize = CGSizeMake(realWidth, realWidth*imgSize.height/imgSize.width);
        }
        
        UIImage * img = [Utils scaleToSize:self.thumb size:realSize];
        thumbView = [[UIImageView alloc] initWithImage:img];
        [thumbView setFrame:CGRectMake(margin_content, margin_content, img.size.width, img.size.height)];
        [view addSubview:thumbView];
        
        label.text = @"";
    }
    
    return view;
}

#pragma mark -------UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 175-43-margin_content;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![text isEqualToString:@""]) {
        placeholder.hidden = YES;
    }
    
    if ([text isEqualToString:@""] && range.location == 0 && range.length == 1) {
        placeholder.hidden = NO;
    }
    
    return YES;
}
@end
