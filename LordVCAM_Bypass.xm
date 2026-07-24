// LordVCAM Bypass - Tweak Permanente
// Metodos descobertos via analise Frida da AVServicesd.dylib v2.0.994

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ================================================================
// AVSServiceConfiguration - nucleo de autenticacao
// ================================================================
%hook AVSServiceConfiguration

- (NSInteger)_avs_cfg_st { return 1; }

- (void)set_avs_cfg_st:(NSInteger)val {
    if (val == 4 || val == 0) return;
    %orig;
}

- (double)_avs_cfg_expiry {
    return [[NSDate distantFuture] timeIntervalSince1970];
}

- (double)_avs_cfg_remaining {
    return 86400.0 * 3650;
}

- (double)_avs_cfg_balance {
    return 999.99;
}

- (NSString *)_avs_cfg_banText {
    return @"";
}

- (double)_avs_cfg_banExp {
    return 0.0;
}

- (NSInteger)_avs_cfg_banType {
    return 0;
}

- (void)startPeriodicSync {}

- (void)_avs_cfg_resolveNet {}

- (void)postToEndpoint:(NSString *)endpoint body:(id)body completion:(id)completion {
    NSLog(@"[LordVCAMBypass] postToEndpoint interceptado: %@", endpoint);
    if (!completion) return;
    NSDictionary *fakeResponse = @{
        @"success":    @YES,
        @"status":     @"ok",
        @"authorized": @YES,
        @"purchased":  @YES,
        @"st":         @1,
        @"expiry":     @([[NSDate distantFuture] timeIntervalSince1970]),
        @"remaining":  @(86400.0 * 3650),
        @"balance":    @999.99,
        @"banText":    @"",
        @"banType":    @0,
        @"email":      @"bypass@bypass.com",
        @"token":      @"bypass_permanent_token"
    };
    void (^block)(NSDictionary *, NSError *) = completion;
    block(fakeResponse, nil);
}

+ (BOOL)_avs_pres_isBanned {
    return NO;
}

%end

// ================================================================
// AVSPresentationController - suprimir telas de aviso
// ================================================================
%hook AVSPresentationController

// LOGIN / EXPIRADO / BAN: bloquear
- (void)showLogin {
    NSLog(@"[LordVCAMBypass] showLogin BLOQUEADO");
}

- (void)_avs_pres_showExp {
    NSLog(@"[LordVCAMBypass] showExp BLOQUEADO");
}

- (void)_avs_pres_showBan:(id)banInfo duration:(double)duration _avs_cfg_banType:(NSInteger)type {
    NSLog(@"[LordVCAMBypass] showBan BLOQUEADO");
}

- (void)showIntegrityFailed {
    NSLog(@"[LordVCAMBypass] showIntegrityFailed BLOQUEADO");
}

- (void)buildAndShowIntegrityFailed {
    NSLog(@"[LordVCAMBypass] buildAndShowIntegrityFailed BLOQUEADO");
}

- (void)_avs_pres_showSE {}
- (void)_avs_pres_showMnt:(NSString *)msg estimatedEnd:(id)end {}
- (void)_avs_pres_showErrLoc:(id)err message:(NSString *)msg {}

// buildAndShow: LIBERADO - e a tela principal da camera (ativada pelo volume)
// Com o status sempre retornando 1 (ativo), ele mostra a camera, nao o login

%end

// ================================================================
// Inicializar hooks - OBRIGATORIO
// ================================================================
%ctor {
    NSLog(@"[LordVCAMBypass] ===== TWEAK CARREGADO EM: %@ =====",
          [[NSBundle mainBundle] bundleIdentifier] ?: @"unknown");
    %init;
    NSLog(@"[LordVCAMBypass] Todos os hooks registrados!");
}
