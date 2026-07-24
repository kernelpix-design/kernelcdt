// LordVCAM Bypass v1.0.4
// Abordagem completa: escrever state.plist + hooks + desativar AVSAntiTamper

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ================================================================
// Escrever plist de estado fake (mesmo metodo que o Frida V8 usava)
// ================================================================
static void writeFakeStatePlist() {
    NSString *dir  = @"/var/tmp/com.apple.avfcache";
    NSString *path = [dir stringByAppendingPathComponent:@"state.plist"];

    [[NSFileManager defaultManager]
        createDirectoryAtPath:dir
        withIntermediateDirectories:YES
        attributes:nil
        error:nil];

    NSDictionary *state = @{
        @"st":        @1,
        @"expiry":    @([[NSDate distantFuture] timeIntervalSince1970]),
        @"remaining": @(86400.0 * 3650),
        @"balance":   @999.99,
        @"email":     @"bypass@bypass.com",
        @"token":     @"bypass_permanent_token",
        @"purchased": @YES,
        @"banText":   @"",
        @"banType":   @0,
        @"banExp":    @0.0
    };

    BOOL ok = [state writeToFile:path atomically:YES];
    NSLog(@"[LordVCAMBypass] state.plist escrito: %@ -> %@", ok ? @"OK" : @"ERRO", path);
}

// ================================================================
// AVSAntiTamper - desativar deteccao de bypass/frida/jailbreak
// ================================================================
%hook AVSAntiTamper

+ (BOOL)checkIntegrity       { return YES; }
+ (BOOL)isTampered           { return NO;  }
+ (BOOL)hasFrida             { return NO;  }
+ (BOOL)isModified           { return NO;  }
+ (void)performCheck         {}
+ (void)startMonitoring      {}
+ (id)sharedInstance         { return %orig; }

- (BOOL)checkIntegrity       { return YES; }
- (BOOL)isTampered           { return NO;  }
- (BOOL)hasFrida             { return NO;  }
- (void)performCheck         {}

%end

// ================================================================
// AVSServiceConfiguration - forcar status ativo
// ================================================================
%hook AVSServiceConfiguration

- (NSInteger)_avs_cfg_st     { return 1; }

- (void)set_avs_cfg_st:(NSInteger)val {
    // Bloqueia qualquer tentativa de mudar para expirado/inativo
    if (val == 0 || val == 4 || val == 5 || val == 6) {
        NSLog(@"[LordVCAMBypass] BLOQUEADO set_avs_cfg_st: %ld", (long)val);
        return;
    }
    %orig;
}

- (double)_avs_cfg_expiry    { return [[NSDate distantFuture] timeIntervalSince1970]; }
- (double)_avs_cfg_remaining { return 86400.0 * 3650; }
- (double)_avs_cfg_balance   { return 999.99; }
- (NSString *)_avs_cfg_banText { return @""; }
- (double)_avs_cfg_banExp    { return 0.0; }
- (NSInteger)_avs_cfg_banType { return 0; }

- (void)startPeriodicSync    {}
- (void)_avs_cfg_resolveNet  {}

+ (BOOL)_avs_pres_isBanned   { return NO; }

%end

// ================================================================
// AVSPresentationController - bloquear APENAS telas de erro/login
// ================================================================
%hook AVSPresentationController

- (void)showLogin {
    NSLog(@"[LordVCAMBypass] showLogin BLOQUEADO");
}

- (void)_avs_pres_showExp {
    NSLog(@"[LordVCAMBypass] showExp BLOQUEADO");
}

- (void)_avs_pres_showBan:(id)a duration:(double)b _avs_cfg_banType:(NSInteger)c {
    NSLog(@"[LordVCAMBypass] showBan BLOQUEADO");
}

- (void)showIntegrityFailed         { NSLog(@"[LordVCAMBypass] integrityFailed BLOQUEADO"); }
- (void)buildAndShowIntegrityFailed { NSLog(@"[LordVCAMBypass] buildAndShowIntegrityFailed BLOQUEADO"); }

// buildAndShow NAO bloqueado - e o que abre a camera via gesto de volume

%end

// ================================================================
// INIT
// ================================================================
%ctor {
    NSLog(@"[LordVCAMBypass] v1.0.4 iniciando em: %@",
          [[NSBundle mainBundle] bundleIdentifier] ?: @"(sem bundle)");

    // Escrever estado fake antes que o tweak original leia
    writeFakeStatePlist();

    %init;

    NSLog(@"[LordVCAMBypass] v1.0.4 hooks ativos!");
}
