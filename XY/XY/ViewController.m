//
//  ViewController.m
//  XY
//
//  Created by zcb on 15-6-15.
//  Copyright (c) 2015年 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"
#import "XYCache.h"

@interface ViewController ()<UITextViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    XYCache *xy = nil;
    xy = [[XYCache alloc] initWithName:@"tee"];
    [xy setObject:@"test" forKey:@"akey"];

     [[XYCache sharedCache] objectForKey:@"akey" usingBlock:^(id<NSCopying> object) {
         NSLog(@"%@",object);
     }];
    
   // NSString *object =[xy objectForKey:@"akey"];
//    NSString *path = [xy pathForKey:@"akey"];
//    NSLog(@"path:%@,obj:%@",path,object);
//    NSLog(@"dir:%@",xy.directory);
//    [xy setObject:@"test_obj" forKey:@"akey1"];
//    NSString *object1 =[xy objectForKey:@"akey1"];
//    NSString *path1 = [xy pathForKey:@"akey1"];
    //[xy excludeDirectory:[cachesDirectory stringByAppendingString:@"/com.xycache.www"]];
//    NSLog(@"path1:%@,obj1:%@",path1,object1);
//    NSLog(@"dir1:%@",xy.directory);
//    NSLog(@"%@",[xy subpathsOfDirectoryAtPath:xy.directory]);
//    NSLog(@"%@",[xy contectsOfDirectoryAtPath:xy.directory]);
    
    NSString * str = [NSString stringWithFormat:@"This is an example by @www.baidu.com"];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:str]; // assume string exists
    NSRange urlRange = [str rangeOfString:@"www.baidu.com"];
    [string addAttribute:NSLinkAttributeName
                   value:@"username://@www.baidu.com/"
                   range:urlRange];
    [string addAttribute:NSForegroundColorAttributeName
                   value:[UIColor blueColor]
                   range:urlRange];
    [string addAttribute:NSUnderlineStyleAttributeName
                   value:@(NSUnderlineStyleNone)
                   range:urlRange];
    [string endEditing];
    
    UITextView * textView = [[UITextView alloc] initWithFrame:CGRectMake(100, 200, 200, 200)];
    textView.backgroundColor =[UIColor whiteColor];
    textView.delegate = self;
    [textView setSelectable: YES];
    [textView setEditable:NO];
    textView.attributedText = string;
    textView.dataDetectorTypes = UIDataDetectorTypeLink;
    [self.view addSubview:textView];
    [self test:@"1",@"2",@"3",nil];
  
    

}

- (void)test:(id)firstobj,...{
    va_list ap;
    id arg;
    va_start(ap, firstobj);
    while ((arg = va_arg(ap, id))!=nil) {
        NSLog(@"%@",arg);
    }
    va_end(ap);
}
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    NSLog(@"url :%@",URL);
    if ([[URL scheme] isEqualToString:@"username"]) {
        NSString *username = [URL host];
        NSLog(@"username :%@",username);
        return NO;
    }
    return YES;
}
@end
