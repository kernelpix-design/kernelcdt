// LordVCAM Bypass - Tweak Permanente
// Metodos descobertos via analise Frida da AVServicesd.dylib
// Compilar: make package THEOS_PACKAGE_SCHEME=rootless

#import <Foundation/Foundation.h>

typedef void (^AVSCompletionBlock)(NSDictionary *response, NSError *error);

// ================================================================
// AVSServiceConfiguration - nucleo de autenticacao
// ================================================================
%hook AVSServiceConfiguration

// Status: sempre retornar 1 (ativo/autorizado)
- (long long)_avs_cfg_st {
    return 1;
}

// Bloquear setter para valores ruins (4=expirado, 0=nao-autenticado)
- (void)set_avs_cfg_st:(long long)val {
    if (val == 4 || val == 0) {
        return; // ignorar estado de expiracao/logout
    }
    %orig;
}

// Expiry: sempre 10 anos no futuro
- (double)_avs_cfg_expiry {
    return [[NSDate distantFuture] timeIntervalSince1970];
}

// Tempo restante: sempre maximo
- (double)_avs_cfg_remaining {
    return 86400.0 * 3650;
}

// Saldo: sempre alto
- (double)_avs_cfg_balance {
    return 999.99;
}

// Ban: sempre sem texto de ban
- (NSString *)_avs_cfg_banText {
    return @"";
}

// Ban expiry: sempre 0 (ban expirou)
- (double)_avs_cfg_banExp {
    return 0.0;
}

// Ban type: 0 = sem ban
- (long long)_avs_cfg_banType {
    return 0;
}

// Bloquear sync periodico (evita re-validacao com servidor)
- (void)startPeriodicSync {
    // nao iniciar sync
}

// Bloquear resolucao de rede (evita validacao)
- (void)_avs_cfg_resolveNet {
    // nao resolver
}

// Interceptar chamadas HTTP e retornar sucesso
- (void)postToEndpoint:(NSString *)endpoint body:(NSDictionary *)body completion:(AVSCompletionBlock)completion {
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
    completion(fakeResponse, nil);
}

// Ban class method: nunca banido
+ (BOOL)_avs_pres_isBanned {
    return NO;
}

%end

// ================================================================
// AVSPresentationController - telas de UI
// ================================================================
%hook AVSPresentationController

// Bloquear tela de login
- (void)showLogin {
    // nao mostrar
}

// Bloquear construcao da UI de login/aviso
- (void)buildAndShow {
    // nao construir
}

// Bloquear tela de integridade falhou (anti-tamper)
- (void)showIntegrityFailed {
    // nao mostrar
}

// Bloquear tela de conta expirada
- (void)_avs_pres_showExp {
    // nao mostrar
}

// Bloquear tela de ban
- (void)_avs_pres_showBan:(id)banInfo duration:(double)duration _avs_cfg_banType:(long long)type {
    // nao mostrar
}

// Bloquear construcao de tela de integridade
- (void)buildAndShowIntegrityFailed {
    // nao construir
}

// Bloquear tela de erro de seguranca
- (void)_avs_pres_showSE {
    // nao mostrar
}

// Bloquear tela de manutencao
- (void)_avs_pres_showMnt:(NSString *)msg estimatedEnd:(id)end {
    // nao mostrar
}

%end