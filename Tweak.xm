#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

// ==========================================
// 1. A PONTE DO MOTOR (ATCGlue)
// ==========================================
// Declaração para o compilador não reclamar do sharedInstance
@interface ATCGlue : NSObject
+ (id)sharedInstance;
@end

// Função que sua futura UI vai chamar
void AplicarPatchEngine(NSString *patchName, NSString *targetDir, NSArray *fileNames, NSArray *fileData) {
    Class atcClass = NSClassFromString(@"ATCGlue");
    if (!atcClass) return;
    
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

// ==========================================
// 2. O SEQUESTRO DA TELA (Hook UIWindow)
// ==========================================
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig; // Deixa o app original fazer o trabalho dele primeiro
    
    // O dispatch_once garante que o alerta só vai pular UMA vez
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Espera 2 segundos para o app carregar a interface original antes de tacar o alerta
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // Cria o alerta
            UIAlertController *alerta = [UIAlertController alertControllerWithTitle:@"ZERO" message:@"UI Sequestrada com Sucesso!" preferredStyle:UIAlertControllerStyleAlert];
            
            // Adiciona o botão
            [alerta addAction:[UIAlertAction actionWithTitle:@"Eu mando aqui" style:UIAlertActionStyleDefault handler:nil]];
            
            // Acha a ViewController principal para mostrar o alerta
            UIViewController *rootVC = self.rootViewController;
            if (rootVC) {
                // Se a root for uma NavigationController, pegamos a tela de cima
                if ([rootVC isKindOfClass:[UINavigationController class]]) {
                    rootVC = [(UINavigationController *)rootVC topViewController];
                }
                
                // Mostra o alerta
                [rootVC presentViewController:alerta animated:YES completion:nil];
            }
        });
    });
}

%end
