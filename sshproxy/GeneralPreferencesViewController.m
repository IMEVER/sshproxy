//
//  PreferencesController
//  sshproxy
//
//  Created by Brant Young on 16/1/13.
//  Copyright (c) 2013 Codinn Studio. All rights reserved.
//
#import <ServiceManagement/ServiceManagement.h>

#import "GeneralPreferencesViewController.h"
#import "CharmNumberFormatter.h"
#import "SSHHelper.h"
#import "AppController.h"

@implementation GeneralPreferencesViewController

@synthesize isDirty;

#pragma mark - MASPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral]; // NSImageNameNetwork
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

-(void)loadView
{
    [super loadView];
    
    CharmNumberFormatter *formatter = [[CharmNumberFormatter alloc] init];
    self.localPortTextField.formatter = formatter;
    
    NSInteger localPort = [SSHHelper getLocalPort];
    
    self.localPortTextField.integerValue = localPort;
    self.localPortStepper.integerValue = localPort;
    
    [self.userDefaultsController save:self];
    self.isDirty = NO;
}


#pragma - Actions

- (IBAction)localStepperAction:(id)sender {
	self.localPortTextField.intValue = self.localPortStepper.intValue;
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)toggleAutoTurnOnProxy:(id)sender
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(IBAction)toggleLaunchAtLogin:(id)sender
{
    NSInteger state = self.startAtLoginButton.state;
    
    if (state == NSOnState) { // ON
        // Turn on launch at login
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.codinnstudio.sshproxyhelper", YES)) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Couldn't add SSH Proxy Helper App to launch at login item list."];
            [alert runModal];
        }
    }
    if (state == NSOffState) { // OFF
        // Turn off launch at login
        if (!SMLoginItemSetEnabled ((__bridge CFStringRef)@"com.codinnstudio.sshproxyhelper", NO)) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"An error ocurred"
                                             defaultButton:@"OK"
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:@"Couldn't remove SSH Proxy Helper App from launch at login item list."];
            [alert runModal];
        }
    }
}

-(IBAction)closePreferencesWindow:(id)sender
{
    [self.view.window performClose:sender];
}

- (IBAction)applyChanges:(id)sender
{
//    BOOL isProxyNeedReactive = [SSHHelper getLocalPort]!=self.localPortTextField.integerValue;
//    BOOL isSocksServerNeedRestart = [SSHHelper isShareSOCKS]!=self.shareSocksButton.state;
    
    [self.userDefaultsController save:self];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.isDirty = NO;
    
    AppController *appController = (AppController *)([NSApplication sharedApplication].delegate);
    
//    if (isSocksServerNeedRestart) {
//        [appController performSelector: @selector(restartServer) withObject:nil afterDelay: 0.0];
//    }
    
    // reactive proxy
//    if (isProxyNeedReactive) {
    [appController performSelector: @selector(reactiveProxy:) withObject:self afterDelay: 0.0];
//    }
}
- (IBAction)revertChanges:(id)sender
{
    [self.userDefaultsController revert:self];
    
    // save again to prevent dirty settings
    [self.userDefaultsController save:self];
    self.isDirty = NO;
}

#pragma - NSViewController

- (BOOL)commitEditing
{
    BOOL shouldClose = YES;
    
    if (self.isDirty) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"The preference has changes that have not been applied. Would you like to apply them?" defaultButton:@"Apply" alternateButton:@"Don't Apply" otherButton:@"Cancel" informativeTextWithFormat:@""];
        
        alert.alertStyle = NSWarningAlertStyle;
        
        [alert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
        
        // a simple trick for waiting sheet modal return
        shouldClose = [NSApp runModalForWindow:alert.window];
    }
    
    return shouldClose;
}
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    switch (returnCode) {
        case NSAlertDefaultReturn: // apply
            [self performSelector: @selector(applyChanges:) withObject:nil afterDelay: 0.0];
            [NSApp stopModalWithCode:YES];
            break;
            
        case NSAlertOtherReturn: // cancel
            [NSApp stopModalWithCode:NO];
            break;
            
        case NSAlertAlternateReturn: // don't apply
            [self performSelector: @selector(revertChanges:) withObject:nil afterDelay: 0.0];
            [NSApp stopModalWithCode:YES];
            break;
            
        default:
            [NSApp stopModalWithCode:YES];
            break;
    }
}

- (void)dealloc
{
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

- (IBAction)toggleShareSocks:(id)sender
{
    self.isDirty = self.userDefaultsController.hasUnappliedChanges;
}

@end
