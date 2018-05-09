//
//  ViewController.m
//  ZOSSFileUploader
//
//  Created by zwx on 2017/12/14.
//  Copyright © 2017年 zwx. All rights reserved.
//

#import "ViewController.h"
#import "ZOSSFileUploader.h"


@interface ViewController ()

@property (nonatomic,strong) UIImage* o_image;
@property (nonatomic,strong) NSString* o_path;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _o_image = [UIImage imageNamed:@"image.jpg"];
    _o_path = [[NSBundle mainBundle] pathForResource:@"guoxinantai" ofType:@"mp4"];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onUploadImageAct:(id)sender {
    [[ZOSSFileUploader shareInstance]  asyncUploadImages:@[_o_image,_o_image,_o_image,_o_image,_o_image,_o_image,_o_image] progress:^(int64_t byteSent, int64_t bytesTotal, double progress) {
//        NSLog(@" %lld, %lld, --%lf",byteSent, bytesTotal,progress);
    } complete:^(NSArray<NSString *> *names, BOOL isSuccess) {
        NSLog(@"%@",names);
//        NSLog(@" IS success ----%d---",isSuccess);
        NSLog(@"-----");
        for (NSString* name in names) {
            NSString* fullStr = [ZOSSFileUploader aliUrlWithName:name];
            NSLog(@"%@",fullStr);
        }
        
    }];
}
- (IBAction)onUploadDataAct:(id)sender {
    
    NSData* data = UIImageJPEGRepresentation(_o_image,0.8);
    
    [[ZOSSFileUploader shareInstance]  asyncUploadDatas:@[data,data,data,data,data,data,data] progress:^(int64_t byteSent, int64_t bytesTotal, double progress) {
//        NSLog(@" %lld, %lld, --%lf",byteSent, bytesTotal,progress);
    } complete:^(NSArray<NSString *> *names, BOOL isSuccess) {
        NSLog(@"%@",names);
//        NSLog(@" IS success ----%d---",isSuccess);
        NSLog(@"-----");
        for (NSString* name in names) {
            NSString* fullStr = [ZOSSFileUploader aliUrlWithName:name];
            NSLog(@"%@",fullStr);
        }
    }];
}
- (IBAction)onUploadFilePathAct:(id)sender {
    
    [[ZOSSFileUploader shareInstance]  asyncUploadPaths:@[_o_path,_o_path,_o_path,_o_path,_o_path,_o_path,_o_path,_o_path] progress:^(int64_t byteSent, int64_t bytesTotal, double progress) {
//        NSLog(@" %lld, %lld, --%lf",byteSent, bytesTotal,progress);
    } complete:^(NSArray<NSString *> *names, BOOL isSuccess) {
        NSLog(@"%@",names);
//        NSLog(@" Is success ----%@---",isSuccess?@"YES":@"NO");
        NSLog(@"-----");
        for (NSString* name in names) {
            NSString* fullStr = [ZOSSFileUploader aliUrlWithName:name];
            NSLog(@"%@",fullStr);
        }
    }];
}

@end
