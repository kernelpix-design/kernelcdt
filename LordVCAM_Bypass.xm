// LordVCAM Bypass - Tweak Permanente
// Metodos descobertos via analise Frida da AVServicesd.dylib v2.0.994

#import <Foundation/Foundation.h>

// ================================================================
// AVSServiceConfiguration - nucleo de autenticacao
// ================================================================
%hook AVSServiceConfiguration

// Status: sempre retornar 1 (ativo/autorizado)
- (NSInteger)_avs_cfg_st {
    return 1;
}

// Bloquear setter para valores ruins (4=expirado, 0=nao-autenticado)
- (void)set_avs_cfg_st:(NSInteger)val {
    if (val == 4 || val == 0) {
        return; // ignorar estado de expiracao/logout
    }
    %orig;
}

// Expiry: sempre far future
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

// Ban: sempre sem texto
- (NSString *)_avs_cfg_banText {
    return @"";
}

// Ban expiry: 0 = ban expirou
- (double)_avs_cfg_banExp {
    return 0.0;
}

// Ban type: 0 = sem ban
- (NSInteger)_avs_cfg_banType {
    return 0;
}

// Bloquear sync periodico (evita re-validacao)
- (void)startPeriodicSync {
    // nao iniciar sync
}

// Bloquear resolucao de rede (evita validacao)
- (void)_avs_cfg_resolveNet {
    // nao resolver
}

// Interceptar chamadas HTTP do tweak e retornar sucesso
- (void)postToEndpoint:(NSString *)endpoint body:(id)body completion:(id)completion {
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
    // Chamar completion block com resposta falsa
    void (^block)(NSDictionary *, NSError *) = completion;
    block(fakeResponse, nil);
}

// Ban class method: nunca banido
+ (BOOL)_avs_pres_isBanned {
    return NO;
}

%end

// ================================================================
// AVSPresentationController - suprimir todas as telas de aviso
// ================================================================
%hook AVSPresentationController

// Bloquear tela de login
- (void)showLogin {}

// Bloquear construcao da UI
- (void)buildAndShow {}

// Bloquear tela de anti-tamper
- (void)showIntegrityFailed {}

// Bloquear tela de conta expirada
- (void)_avs_pres_showExp {}

// Bloquear tela de ban
- (void)_avs_pres_showBan:(id)banInfo duration:(double)duration _avs_cfg_banType:(NSInteger)type {}

// Bloquear construcao de tela de integridade
- (void)buildAndShowIntegrityFailed {}

// Bloquear tela de erro de seguranca
- (void)_avs_pres_showSE {}

// Bloquear tela de manutencao
- (void)_avs_pres_showMnt:(NSString *)msg estimatedEnd:(id)end {}

// Bloquear tela de erro de localizacao
- (void)_avs_pres_showErrLoc:(id)err message:(NSString *)msg {}

%end

// ================================================================
// OBRIGATORIO: inicializar todos os hooks
// Sem este bloco, NENHUM hook e ativado!
// ================================================================
%ctor {
    NSLog(@"[LordVCAM-Bypass] Tweak carregado - bypass ativo!");
    %init;
}
