#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// ==========================================
// 1. A PONTE DO MOTOR
// ==========================================
@interface ATCGlue : NSObject
+ (id)sharedInstance;
@end

void AplicarPatchEngine(NSString *patchName, NSArray *files, NSArray *data) {
    Class atcClass = NSClassFromString(@"ATCGlue");
    if (!atcClass) return;
    id atcInstance = [(id)atcClass sharedInstance];
    
    NSString *ip = @"1.0.7.0"; 
    NSString *pairingPath = [NSString stringWithFormat:@"%@/Documents/AirLift/.pairingplist", NSHomeDirectory()];
    NSString *targetDir = @"/var/mobile/Containers/Data/Application/ALVO/Documents"; // Precisamos descobrir o alvo

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
        [invocation setArgument:&files atIndex:6];
        [invocation setArgument:&data atIndex:7];
        [invocation setArgument:&errorPtr atIndex:8];
        
        [invocation invoke];
        NSLog(@"[ZERO] Injeção disparada para: %@", patchName);
    }
}

// ==========================================
// 2. A INTERFACE
// ==========================================
@interface CustomPatchCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UISwitch *toggleSwitch;
@end

@implementation CustomPatchCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UIView *card = [[UIView alloc] init];
        card.backgroundColor = [UIColor colorWithRed:0.2 green:0.1 blue:0.1 alpha:1.0];
        card.layer.cornerRadius = 10;
        card.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:card];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:_titleLabel];
        
        _subtitleLabel = [[UILabel alloc] init];
        _subtitleLabel.text = @"Estado não verificado";
        _subtitleLabel.textColor = [UIColor grayColor];
        _subtitleLabel.font = [UIFont systemFontOfSize:12];
        _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:_subtitleLabel];
        
        _toggleSwitch = [[UISwitch alloc] init];
        _toggleSwitch.onTintColor = [UIColor redColor];
        _toggleSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        [card addSubview:_toggleSwitch];
        
        [NSLayoutConstraint activateConstraints:@[
            [card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
            [card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
            [card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
            [card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16],
            [_titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:12],
            [_titleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
            [_subtitleLabel.topAnchor constraintEqualToAnchor:_titleLabel.bottomAnchor constant:4],
            [_subtitleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
            [_toggleSwitch.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
            [_toggleSwitch.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16]
        ]];
    }
    return self;
}
@end

@interface VoltPatchesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIDocumentPickerDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *patches;
@property (nonatomic, strong) NSMutableDictionary *switchStates;
@end

@implementation VoltPatchesViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.15 green:0.05 blue:0.05 alpha:1.0];
    
    // LISTA VAZIA! Só vai popular quando importar.
    self.patches = [NSMutableArray array]; 
    self.switchStates = [NSMutableDictionary dictionary];
    
    self.title = @"Patches VOLT CHATS";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.15 green:0.05 blue:0.05 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor redColor];
    
    UIBarButtonItem *importBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(importPatch)];
    self.navigationItem.rightBarButtonItem = importBtn;
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
}

- (void)importPatch {
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeZIP, UTTypeFolder, UTTypeData]];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0) {
        NSString *fileName = urls[0].lastPathComponent;
        NSString *patchName = [fileName stringByDeletingPathExtension];
        
        [self.patches insertObject:patchName atIndex:0];
        [self.tableView reloadData];
        NSLog(@"[ZERO] Patch importado: %@", patchName);
        
        // NO FUTURO: Aqui a gente copia o arquivo para a pasta do app.
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.patches.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomPatchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) cell = [[CustomPatchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    NSString *patchName = self.patches[indexPath.row];
    cell.titleLabel.text = patchName;
    
    BOOL isOn = [[self.switchStates objectForKey:patchName] boolValue];
    cell.toggleSwitch.on = isOn;
    
    [cell.toggleSwitch removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    cell.toggleSwitch.tag = indexPath.row;
    [cell.toggleSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 85; }

- (void)switchChanged:(UISwitch *)sender {
    NSString *patchName = self.patches[sender.tag];
    [self.switchStates setObject:@(sender.isOn) forKey:patchName];
    
    if (sender.isOn) {
        // Aqui a gente chama o motor
        AplicarPatchEngine(patchName, @[], @[]); 
    } else {
        NSLog(@"[ZERO] Desligado: %@", patchName);
    }
}
@end

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            VoltPatchesViewController *minhaTela = [[VoltPatchesViewController alloc] init];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:minhaTela];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            
            UIViewController *rootVC = self.rootViewController;
            if ([rootVC isKindOfClass:[UINavigationController class]]) rootVC = [(UINavigationController *)rootVC topViewController];
            if (rootVC) [rootVC presentViewController:nav animated:YES completion:nil];
        });
    });
}
%end
