// LordVCAM Bypass v1.0.5 - porta direta do frida_bypass_v8.js
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ================================================================
// AVSAntiTamper - desativar deteccao de tamper/frida
// ================================================================
%hook AVSAntiTamper
+ (BOOL)checkIntegrity  { return YES; }
+ (BOOL)isTampered      { return NO;  }
+ (BOOL)hasFrida        { return NO;  }
+ (BOOL)isModified      { return NO;  }
+ (void)performCheck    {}
+ (void)startMonitoring {}
%end

// ================================================================
// AVSServiceConfiguration - forcas status ativo + bloquear sync
// ================================================================
%hook AVSServiceConfiguration

- (NSInteger)_avs_cfg_st     { return 1; }

- (void)set_avs_cfg_st:(NSInteger)val {
    if (val == 0 || val == 4 || val == 5 || val == 6) return;
    %orig;
}

- (double)_avs_cfg_expiry      { return [[NSDate distantFuture] timeIntervalSince1970]; }
- (double)_avs_cfg_remaining   { return 86400.0 * 3650; }
- (double)_avs_cfg_balance     { return 999.99; }
- (NSString *)_avs_cfg_banText { return @""; }
- (double)_avs_cfg_banExp      { return 0.0; }
- (NSInteger)_avs_cfg_banType  { return 0; }
- (void)startPeriodicSync      {}
- (void)_avs_cfg_resolveNet    {}
+ (BOOL)_avs_pres_isBanned     { return NO; }

// Hook critico: interceptar chamada HTTP e injetar resposta de sucesso
- (void)postToEndpoint:(id)endpoint body:(id)body completion:(id)completion {
    NSLog(@"[LordVCAMBypass] postToEndpoint INTERCEPTADO");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
        NSMutableDictionary *fakeResp = [NSMutableDictionary dictionary];
        fakeResp[@"success"]    = @YES;
        fakeResp[@"status"]     = @"ok";
        fakeResp[@"authorized"] = @YES;
        fakeResp[@"purchased"]  = @YES;
        fakeResp[@"st"]         = @1;
        fakeResp[@"expiry"]     = @([[NSDate distantFuture] timeIntervalSince1970]);
        fakeResp[@"remaining"]  = @(86400.0 * 3650);
        fakeResp[@"balance"]    = @999.99;
        fakeResp[@"banText"]    = @"";
        fakeResp[@"banType"]    = @0;
        fakeResp[@"email"]      = @"bypass@bypass.com";
        fakeResp[@"token"]      = @"bypass_tok";
        if (completion) {
            void (^block)(NSDictionary *, id) = completion;
            block(fakeResp, nil);
        }
        NSLog(@"[LordVCAMBypass] postToEndpoint resposta injetada!");
    });
}

// Capturar instancia para forcar clearBan + writeSession
- (void)_avs_cfg_startTrk {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSLog(@"[LordVCAMBypass] startTrk capturado, forcando clearBan + writeSession");
        @try { [[self class] performSelector:@selector(_avs_pres_clearBan)]; } @catch(NSException *e) {}
        @try { [self performSelector:@selector(_avs_cfg_writeSession)];      } @catch(NSException *e) {}
    });
}

%end

// ================================================================
// AVSPresentationController - bloquear telas de erro/login
// NAO bloquear buildAndShow (abre via gesto de volume)
// ================================================================
%hook AVSPresentationController
- (void)showLogin                                                              { NSLog(@"[LordVCAMBypass] showLogin BLOQUEADO"); }
- (void)_avs_pres_showExp                                                     {}
- (void)_avs_pres_showBan:(id)a duration:(double)b _avs_cfg_banType:(NSInteger)c {}
- (void)showIntegrityFailed                                                   {}
- (void)buildAndShowIntegrityFailed                                           {}
- (void)_avs_pres_buildExp                                                    {}
- (void)_avs_pres_buildBan:(id)a duration:(double)b _avs_cfg_banType:(NSInteger)c {}
- (void)_avs_pres_showSE                                                      {}
- (void)_avs_pres_showMnt:(id)a estimatedEnd:(id)b                            {}
- (void)_avs_pres_showErrLoc:(id)a message:(id)b                              {}
%end

// ================================================================
// INIT - escrever state.plist fake e ativar todos os hooks
// ================================================================
%ctor {
    NSLog(@"[LordVCAMBypass] v1.0.5 carregado em: %@",
          [[NSBundle mainBundle] bundleIdentifier] ?: @"(sem bundle)");

    NSString *dir  = @"/var/tmp/com.apple.avfcache";
    NSString *path = [dir stringByAppendingPathComponent:@"state.plist"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
        withIntermediateDirectories:YES attributes:nil error:nil];
    NSDictionary *state = @{
        @"st":        @1,
        @"expiry":    @([[NSDate distantFuture] timeIntervalSince1970]),
        @"remaining": @(86400.0 * 3650),
        @"balance":   @999.99,
        @"email":     @"bypass@bypass.com",
        @"token":     @"bypass_token",
        @"purchased": @YES,
        @"banText":   @"",
        @"banType":   @0,
        @"banExp":    @0.0
    };
    [state writeToFile:path atomically:YES];
    NSLog(@"[LordVCAMBypass] state.plist escrito: %@", path);

    %init;
    NSLog(@"[LordVCAMBypass] v1.0.5 hooks todos ativos!");
}
