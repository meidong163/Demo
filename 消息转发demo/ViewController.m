//
//  ViewController.m
//  消息转发demo
//
//  Created by 舒江波 on 2018/12/14.
//

#import "ViewController.h"
#import "People.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 调用eat 方法，现在当前类查找，如果查找不到，去父类找。如果找不到，进入到消息转发
    [self performSelector:@selector(eat) withObject:nil];

}

- (void)eat
{
    NSLog(@"a food");
}


// 动态创建调用类方法
//+ (BOOL)resolveClassMethod:(SEL)sel


//+ (BOOL)resolveInstanceMethod:(SEL)sel
//{
//    NSLog(@"resolveInstanceMethod:  %@", NSStringFromSelector(sel));
//    if (sel == @selector(eat)) {
//        class_addMethod([self class], sel,[self instanceMethodForSelector:@selector(eat)], "V@:");
//        return YES;
//    }
//    return [super resolveInstanceMethod:sel];
//}


// 告诉调用者，在这个类中即self 来处理这个消息
//- (id)forwardingTargetForSelector:(SEL)aSelector
//{
    // 第一种形式，用别的对象处理消息
//    return [People new];
//}


/**
 把oc转座子转化为方法签名 根据方法类型
 这里的 “v@:@”就代表：
 
 "v":代表返回值void
 "@":代表一个对象，这里指代的id类型zhangsan,也就是消息的receiver
 ":":代表SEL
 "@":代表参数lisi

 @param aSelector oc方法转座子
 @return sing 调用方法签名
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if (aSelector == @selector(eat)) {
        NSMethodSignature *sing = [NSMethodSignature signatureWithObjCTypes:"v@:"];
        return sing;
    }
    // 往父类抛
    return [super methodSignatureForSelector:aSelector];
}

// 转发调用
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([anInvocation selector] == @selector(eat)) {
        [anInvocation invokeWithTarget:[People new]];
    }
    return [super forwardInvocation:anInvocation];// 遵守调用链
}


- (void)doesNotRecognizeSelector:(SEL)aSelector
{
    // 通过消息转发机制仍然无法处理的的方法，异常无法处理
    // 可以选择遗弃，也可以选择调用。
    NSLog(@"%@ 类中的 %@ 未被调用",NSStringFromSelector(_cmd),NSStringFromSelector(aSelector));
    [[People new] performSelector:aSelector];// 如果前面的消息，转发无法处理，这里也无法处理，只能抛出异常了
    
}


@end
