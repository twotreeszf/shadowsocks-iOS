//
//  ProxySettingsTableViewController.m
//  shadowsocks-iOS
//
//  Created by clowwindy on 12-12-31.
//  Copyright (c) 2012年 clowwindy. All rights reserved.
//

#import "NSData+Base64.h"
#import "ProxySettingsTableViewController.h"
#import "SimpleTableViewSource.h"
#import "SWBAppDelegate.h"
#import "ShadowsocksRunner.h"
#import "TTSystemProxyManager.h"
#import "PTPacServer.h"
#import "KPBackgroundRunner.h"
#import "QRCodeViewController.h"

// rows

#define kIPRow 0
#define kPortRow 1
#define kPasswordRow 2

// config keys


@interface ProxySettingsTableViewController ()
{
    SimpleTableViewSource*  _encryptionSource;
    PTPacServer*            _pacServer;
    KPBackgroundRunner*     _bkgRunner;
}

@end

@implementation ProxySettingsTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _pacServer = [[PTPacServer alloc] initWithLocalProxyPort:7070];
    _bkgRunner = [KPBackgroundRunner new];
    
    UIBarButtonItem *showQRCode =  [[UIBarButtonItem alloc] initWithTitle:_L(QR)
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(showQRCode)];
    UIBarButtonItem *scanQRCode = [[UIBarButtonItem alloc] initWithTitle:_L(Scan)
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(scanQRCode)];
    self.navigationItem.leftBarButtonItem = showQRCode;
    self.navigationItem.rightBarButtonItem = scanQRCode;
    self.navigationItem.title = _L(Shadowsocks);
}

- (void)done: (UISwitch*)sender {
    if (ipField.text == nil) {
        ipField.text = @"";
    }
    if (portField.text == nil) {
        portField.text = @"";
    }
    if (passwordField.text == nil) {
        passwordField.text = @"";
    }
    [ShadowsocksRunner saveConfigForKey:kShadowsocksIPKey value:ipField.text];
    [ShadowsocksRunner saveConfigForKey:kShadowsocksPortKey value:portField.text];
    [ShadowsocksRunner saveConfigForKey:kShadowsocksPasswordKey value:passwordField.text];

    [ShadowsocksRunner reloadConfig];
    
    
    if (sender.isOn)
    {
        if (![ShadowsocksRunner settingsAreNotComplete])
        {
            // [[TTSystemProxyManager sharedInstance] enableSocksProxy:@"127.0.0.1" :7070];
            [_pacServer start];
            _bkgRunner.enable = YES;
            
            NSString* url = _pacServer.pacFileAddress;
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = url;
        }
    }
    else
    {
        // [[TTSystemProxyManager sharedInstance] disableProxy];
        [_pacServer stop];
        _bkgRunner.enable = NO;
    }
}

- (void)scanQRCode
{
    QRCodeViewController *qrCodeViewController =
    [[QRCodeViewController alloc] initWithReturnBlock:^(NSString *code)
     {
         if (code) {
             NSURL *URL = [NSURL URLWithString:code];
             if (URL) {
                 [[UIApplication sharedApplication] openURL:URL];
                 
                 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                 {
                     [self.tableView reloadData];
                 });
             }
         }
     }];
    
    [self presentModalViewController:qrCodeViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return _L(Server);
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == 0)
        return 1;
    else
        return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
        
        cell.textLabel.text = _L(Enable);

        UISwitch* onoff = [UISwitch new];
        onoff.center = CGPointMake(cell.bounds.size.width - 40.0, cell.bounds.size.height * 0.5);
        [onoff addTarget:self action:@selector(done:) forControlEvents:UIControlEventValueChanged];
        
        [cell.contentView addSubview:onoff];
        
        return cell;
    } else if (indexPath.section == 1) {
        if (indexPath.row == 3) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bb"];
            cell.textLabel.text = _L(Method);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"aaaaa"];
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
        textField.adjustsFontSizeToFitWidth = YES;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.returnKeyType = UIReturnKeyDone;
        switch (indexPath.row) {
            case kIPRow:
                cell.textLabel.text = _L(IP);
                textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                textField.secureTextEntry = NO;
                textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksIPKey];
                ipField = textField;
                break;
            case kPortRow:
                cell.textLabel.text = _L(Port);
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.secureTextEntry = NO;
                textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksPortKey];
                portField = textField;
                break;
            case kPasswordRow:
                cell.textLabel.text = _L(Password);
                textField.keyboardType = UIKeyboardTypeDefault;
                textField.secureTextEntry = YES;
                textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kShadowsocksPasswordKey];
                passwordField = textField;
                break;
            default:
                break;
        }
        [cell addSubview:textField];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        return cell;
    }
    return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 3) {
        NSString *v = [[NSUserDefaults standardUserDefaults] objectForKey:kShadowsocksEncryptionKey];
        if (!v) {
            v = @"aes-256-cfb";
        }
        _encryptionSource = [[SimpleTableViewSource alloc] initWithLabels:
                            [NSArray arrayWithObjects:@"table", @"aes-256-cfb", @"aes-192-cfb", @"aes-128-cfb",
                             @"bf-cfb", @"camellia-128-cfb", @"camellia-192-cfb", @"camellia-256-cfb", @"cast5-cfb",
                             @"des-cfb", @"idea-cfb", @"rc2-cfb", @"rc4", @"seed-cfb", nil]
                                                                  values:
                            [NSArray arrayWithObjects:@"table", @"aes-256-cfb", @"aes-192-cfb", @"aes-128-cfb",
                             @"bf-cfb", @"camellia-128-cfb", @"camellia-192-cfb", @"camellia-256-cfb", @"cast5-cfb",
                             @"des-cfb", @"idea-cfb", @"rc2-cfb", @"rc4", @"seed-cfb", nil]
                                                            initialValue:v selectionBlock:^(NSObject *value) {
                                                                [[NSUserDefaults standardUserDefaults] setObject:value forKey:kShadowsocksEncryptionKey];
                                                            }];
        UIViewController *controller = [[UIViewController alloc] init];
        controller.contentSizeForViewInPopover = self.contentSizeForViewInPopover;
        controller.navigationItem.title = _L(Method);
        UITableView *tableView1 = [[UITableView alloc] initWithFrame:controller.view.frame style:UITableViewStyleGrouped];
        tableView1.dataSource = _encryptionSource;
        tableView1.delegate = _encryptionSource;
        controller.view = tableView1;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end
