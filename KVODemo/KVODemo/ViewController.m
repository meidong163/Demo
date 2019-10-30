//
//  ViewController.m
//  KVODemo
//
//  Created by 舒江波 on 2019/10/30.
//  Copyright © 2019 com.pactera. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+kvo.h"
@interface Message : NSObject
@property (nonatomic, copy) NSString *text;
@end

@implementation Message


//- (void)myTextSet:(NSString *)text
//{
//    if (self = [super setText:text]) {
//
//    }
//}
@end


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textfelid;
@property(nonatomic,strong)Message *msg;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.msg = [[Message alloc]init];
//    [self.msg addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    __weak  typeof(self) WeakSelf = self;
    [self.msg addObservedObj:self forKey:@"text" WithBlock:^(id  _Nullable observedObject, NSString *observedKey, id oldValue, id newValue) {
        NSLog(@"\n oldvalue = %@ \n newvalue = %@",oldValue,newValue);
        dispatch_async(dispatch_get_main_queue(), ^{
            WeakSelf.textfelid.text = newValue;
        });
    }];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
//{
//    NSLog(@"object = %@",[object valueForKey:@"text"]);
//}

- (IBAction)clickButton:(id)sender {
    NSArray *textArray = @[
        @"曹操",
         @"刘备",
         @"张飞",
         @"赵子龙",
         @"李广",
        @"卫青",
        @"霍去病"
    ];
    NSInteger index = arc4random_uniform((u_int32_t)textArray.count);
    self.msg.text = textArray[index];
}


@end
