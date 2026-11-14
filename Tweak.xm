#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <mach-o/dyld.h>

// ==========================================
// 1. AS FUNÇÕES OCULTAS DO 3105 (Via Offset)
// ==========================================
uintptr_t get_real_base_address() {
    return (uintptr_t)_dyld_get_image_header(0);
}

typedef BOOL (*ImportAndInjectFunc)(NSData *patchData);

void ExecutarImportacaoOriginal(NSString *caminhoDoArquivo) {
    uintptr_t base = get_real_base_address();
    
    // O offset da FUN_10000ec90 (0x10000ec90 - 0x100000000)
    uintptr_t funcAddr = base + 0xec90; 
    
    NSData *fileData = [NSData dataWithContentsOfFile:caminhoDoArquivo];
    if (!fileData) {
        NSLog(@"[ZERO] Erro: Nao foi possivel ler o arquivo em %@", caminhoDoArquivo);
        return;
    }
    
    NSLog(@"[ZERO] Chamando o motor original de importacao via Offset...");
    
    ImportAndInjectFunc importFunc = (ImportAndInjectFunc)funcAddr;
    BOOL sucesso = importFunc(fileData);
    
    if (sucesso) {
        NSLog(@"[ZERO] Importacao e injecao realizadas com sucesso pelo motor original!");
    } else {
        NSLog(@"[ZERO] O motor original retornou falha na importacao.");
    }
}

// ==========================================
// 2. A INTERFACE (UI)
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
@property (nonatomic, strong) NSMutableDictionary *patchPaths;
@end

@implementation VoltPatchesViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.15 green:0.05 blue:0.05 alpha:1.0];
    
    self.patches = [NSMutableArray array]; 
    self.switchStates = [NSMutableDictionary dictionary];
    self.patchPaths = [NSMutableDictionary dictionary];
    
    self.title = @"Patches VOLT CHATS";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.15 green:0.05 blue:0.05 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor redColor];
    
    // AQUI ESTAVA O ERRO: UIBarButtonSystemItemAdd
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
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[ZERO] Tentando abrir o seletor de arquivos...");
        
        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeItem, UTTypeData, UTTypeFolder] asCopy:YES];
        picker.delegate = self;
        picker.allowsMultipleSelection = NO;
        
        [self presentViewController:picker animated:YES completion:nil];
    });
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSLog(@"[ZERO] Seletor fechou. Arquivos selecionados: %lu", (unsigned long)urls.count);
    
    if (urls.count > 0) {
        NSURL *fileURL = urls[0];
        BOOL access = [fileURL startAccessingSecurityScopedResource];
        NSLog(@"[ZERO] Acesso ao arquivo liberado? %d", access);
        
        NSString *fileName = fileURL.lastPathComponent;
        NSString *patchName = [fileName stringByDeletingPathExtension];
        
        NSLog(@"[ZERO] Importando patch: %@", patchName);
        
        [self.patches insertObject:patchName atIndex:0];
        [self.patchPaths setObject:fileURL.path forKey:patchName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
        
        if (access) [fileURL stopAccessingSecurityScopedResource];
    } else {
        NSLog(@"[ZERO] Nenhum arquivo selecionado ou cancelado.");
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
        NSString *path = self.patchPaths[patchName];
        if (path) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                ExecutarImportacaoOriginal(path);
            });
        }
    } else {
        NSLog(@"[ZERO] Restore solicitado. (Em implementação)");
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
