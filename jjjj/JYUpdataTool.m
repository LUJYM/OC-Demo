//
//  JYUpdataTool.m
//  jjjj
//
//  Created by JY on 2017/9/6.
//  Copyright © 2017年 谭占武. All rights reserved.
//

#import "JYUpdataTool.h"
#import "FileStreamOperation.h"

@interface JYUpdataTool()

@property(strong,nonatomic) FileStreamOperation *fileStreamer;
@property(assign,nonatomic) NSInteger currentIndex;
@property(nonatomic,strong)NSThread *thread1;
@property(nonatomic,strong)NSThread *thread2;
@property(nonatomic,strong)NSThread *thread3;
//@property(strong,nonatomic) NSDate *date1;
@end


@implementation JYUpdataTool

-(void)upDataWithPath:(NSString *)path{
    
    FileStreamOperation *fileStreamer = [[FileStreamOperation alloc] initFileOperationAtPath:path forReadOperation:YES];
    self.fileStreamer = fileStreamer;
    [self toUpData];
}

#pragma mark  懒加载
-(NSThread *)thread1{
    if (!_thread1) {
        _thread1=[[NSThread alloc]initWithTarget:self selector:@selector(upOne) object:nil];
    }
    return _thread1;
}
-(NSThread *)thread2{
    if (!_thread2) {
        _thread2=[[NSThread alloc]initWithTarget:self selector:@selector(upOne) object:nil];
    }
    return _thread2;
}
-(NSThread *)thread3{
    if (!_thread3) {
        _thread3=[[NSThread alloc]initWithTarget:self selector:@selector(upOne) object:nil];
    }
    return _thread3;
}


#pragma mark  方法

-(void)toUpData{
//    self.date1 = [NSDate date];
    [self.thread1 start];
    [self.thread2 start];
    [self.thread3 start];
    
}


-(void)upOne{
    while (1) {
//        线程安全,防止多次上传同一块区间
        @synchronized (self) {
            if (self.currentIndex < self.fileStreamer.fileFragments.count) {
                NSData *data = [self.fileStreamer readDateOfFragment:self.fileStreamer.fileFragments[self.currentIndex]];
//                在这里执行上传的操作
//                [NSThread sleepForTimeInterval:0.02];
//                NSLog(@"这是第%zd个上传----%@",self.currentIndex,[NSThread currentThread]);
                self.currentIndex++;
            } else {
//                NSLog(@"时间间隔是%zd",(int)[[NSDate date] timeIntervalSinceDate:self.date1]);
                [NSThread exit];
                
            }
        }
    }
    
    
}



@end
