#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Avisa o compilador que essa classe existe e tem esse método
@interface ATCGlue : NSObject
+ (id)sharedInstance;
@end

void AplicarPatchEngine(NSString *patchName, NSString *targetDir, NSArray *fileNames, NSArray *fileData) {
    Class atcClass = NSClassFromString(@"ATCGlue");
    if (!atcClass) return;
    
    // Correção para o compilador não reclamar do sharedInstance
    id atcInstance = nil;
    if ([atcClass respondsToSelector:@selector(sharedInstance)]) {
        atcInstance = [(id)atcClass sharedInstance];
    } else {
        atcInstance = [[atcClass alloc] init];
    }
    
    NSString *ip = @"1.0.7.0"; 
    NSString *pairingPath = [NSString stringWithFormat:@"%@/Documents/AirLift/.pairingplist", NSHomeDirectory()];
    SEL selector = NSSelectorFromString(@"injectPatchDirectoryWithDeviceIP:pairingPath:targetDirectory:directoryName:fileNames:data:error:");
    
    if ([atcInstance respondsToSelector:selector]) {
        NSMethodSignature *signature = [atcInstance methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:atcInstance];
        [invocation setSelector:selector];
        
        // Correção do NSError para o ARC
        NSError *__autoreleasing error = nil;
        NSError *__autoreleasing *errorPtr = &error;
        
        [invocation setArgument:&ip atIndex:2];
        [invocation setArgument:&pairingPath atIndex:3];
        [invocation setArgument:&targetDir atIndex:4];
        [invocation setArgument:&patchName atIndex:5];
        [invocation setArgument:&fileNames atIndex:6];
        [invocation setArgument:&fileData atIndex:7];
        [invocation setArgument:&errorPtr atIndex:8];
        
        [invocation invoke];
    }
}

%hook UIViewController 
- (void)viewDidLoad {
    %orig;
    NSLog(@"[ZERO] Tweak carregada com sucesso no app!");
}
%end
