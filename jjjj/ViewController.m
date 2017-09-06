//
//  ViewController.m
//  大文件上传测试
//
//  Created by JY on 2017/9/5.
//  Copyright © 2017年 谭占武. All rights reserved.
//

#import "ViewController.h"
#import "FileStreamOperation.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "JYUpdataTool.h"

@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}



- (IBAction)btnClick:(UIButton *)sender {
    UIImagePickerController *pic = [[UIImagePickerController alloc]init];
    pic.delegate = self;
    pic.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    pic.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    [self presentViewController:pic animated:YES completion:nil];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    
    NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:^{
        
        [[JYUpdataTool new]upDataWithPath:[url path]];
        
    }];
    
    
}





@end
