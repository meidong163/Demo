//
//  NSObject+kvo.m
//  KVODemo
//
//  Created by 舒江波 on 2019/10/30.
//  Copyright © 2019 com.pactera. All rights reserved.
//

#import "NSObject+kvo.h"
#import "KVOlib/RTUnregisteredClass.h"

#import "KVOlib/RTProperty.h"
#import "KVOlib/MARTNSObject.h"
#import "KVOlib/RTMethod.h"
#import <objc/runtime.h>
#import <objc/message.h>

NSString *const kClassPrefix = @"MDKVOPrefix_";

NSString *const kMDKVOAssociatedObservers = @"PGKVOAssociatedObservers";


@interface MDObservationInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) Block block;

@end

@implementation MDObservationInfo

- (instancetype)initWithObserver:(NSObject *)observer Key:(NSString *)key block:(Block)block
{
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}

@end

@implementation NSObject (kvo)

- (void)addObservedObj:(NSObject *)observeObj forKey:(NSString *)key WithBlock:(Block)block
{
    
    // 1.获取监听属性的setter方法
//    RTProperty *property = [object_getClass(self) rt_propertyForName:key];
    SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    RTMethod *md = [self.class rt_methodForSelector:setterSelector];
    if (!md) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        
        return;
    }
    // 2.创建一个子类 类名 = 类前缀+原来的类名 初始化继承关系
    Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
    NSString *subClassName = [kClassPrefix stringByAppendingString: clazzName];
    RTUnregisteredClass *subclass = [[RTUnregisteredClass alloc]initWithName:subClassName withSuperclass:clazz];
    NSLog(@"subclassname = %@",[subclass valueForKey:@"_class"]);
    //3.添加类方法
    RTMethod *method = [self.class rt_methodForSelector:@selector(class)];
    [subclass addMethod:method];
    Class kvoClass = [subclass registerClass];
    
    //4.替换被监听对象的isa 让这个对象isa 指向这个子类 这样在调用被监听对象的setter方法是，就回来执行这个子类对象的setter方法。从而实现kvo
    [self PrintClassChain:self.class];
    [self rt_setClass:kvoClass];
    [self PrintClassChain:self.class]; //类的继承发生了变化
    
    //5.添加新的子类对象的setter
    if (![self hasSelector:setterSelector]) {
        RTMethod *insMethod = [[RTMethod alloc]initWithSelector:md.selector implementation:(IMP)kvo_setter signature:md.signature];
        [subclass addMethod:insMethod];
    }
    // 6.管理观察者对象
    MDObservationInfo *info = [[MDObservationInfo alloc]initWithObserver:observeObj Key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kMDKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kMDKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
    
}

static void kvo_setter(id self, SEL _cmd, id newValue)
{
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);

    if (!getterName) {
       NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
       @throw [NSException exceptionWithName:NSInvalidArgumentException
                                      reason:reason
                                    userInfo:nil];
       return;
    }
    NSLog(@"getterName = %@",getterName);
    id oldvalue = [self valueForKey:getterName];
    
    //重写子类对象setter方法 把最新的值赋给 被监听的对象 这里给被监听的对象赋值比较困难。MDKVOPrefix_Messsgae 的父类对象 也就是Message的对象
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    // cast our pointer so the compiler won't complain
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    // call super's setter, which is original class's setter method
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);

    // 执行回调方法
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kMDKVOAssociatedObservers));
    for (MDObservationInfo *each in observers) {
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.block(self, getterName, oldvalue, newValue);
            });
        }
    }
}

/// 通过setter方法拼接getter方法
/// @param setter stter方法
static NSString * getterForSetter(NSString *setter)
{
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    // remove 'set' at the begining and ':' at the end
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    // lower case the first letter
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    
    return key;
}

/// 通过getter方法 拼接出getter方法
/// @param getter getter方法
static NSString * setterForGetter(NSString *getter)
{
    if (getter.length <= 0) {
        return nil;
    }
    
    // upper case the first letter
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    
    // add 'set' at the begining and ':' at the end
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    
    return setter;
}

- (BOOL)hasSelector:(SEL)selector
{
     Class clazz = object_getClass(self);
       unsigned int methodCount = 0;
       Method* methodList = class_copyMethodList(clazz, &methodCount);
       for (unsigned int i = 0; i < methodCount; i++) {
           SEL thisSelector = method_getName(methodList[i]);
           if (thisSelector == selector) {
               free(methodList);
               return YES;
           }
       }
       free(methodList);
       return NO;
}

- (void)removeObserver:(NSObject *)observer forKey:(NSString *)key
{
    NSMutableArray* observers = objc_getAssociatedObject(self, (__bridge const void *)(kMDKVOAssociatedObservers));
    
    MDObservationInfo *infoToRemove;
    for (MDObservationInfo* info in observers) {
        if (info.observer == observer && [info.key isEqual:key]) {
            infoToRemove = info;
            break;
        }
    }
    [observers removeObject:infoToRemove];
}

- (void)PrintClassChain:(Class)aClass{
    NSLog(@"Class:%@ Address:%p", aClass,aClass);
    
    Class getClass = object_getClass(aClass);
    
    if(getClass != aClass){
        [self PrintClassChain:getClass];
    }
}

@end
