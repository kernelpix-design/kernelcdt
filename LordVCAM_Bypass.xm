// LordVCAM Bypass v1.0.3 - Minimalista
// Apenas o necessario para bypassar o login sem quebrar o gesto de volume

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ================================================================
// AVSServiceConfiguration - forcas status = ativo (1)
// ================================================================
%hook AVSServiceConfiguration

// Sempre retorna 1 = ativo/autorizado
- (NSInteger)_avs_cfg_st {
    return 1;
}

// Bloqueia tentativas de mudar para expirado (4) ou nao-autenticado (0)
- (void)set_avs_cfg_st:(NSInteger)val {
    if (val == 0 || val == 4 || val == 5 || val == 6) {
        return; // ignorar estado ruim
    }
    %orig;
}

// Expiracao: data distante
- (double)_avs_cfg_expiry {
    return [[NSDate distantFuture] timeIntervalSince1970];
}

// Sem ban
- (NSString *)_avs_cfg_banText  { return @""; }
- (double)_avs_cfg_banExp       { return 0.0; }
- (NSInteger)_avs_cfg_banType   { return 0; }

// Bloquear sync periodico com o servidor (evita reset do estado)
- (void)startPeriodicSync       {}
- (void)_avs_cfg_resolveNet     {}

%end

// ================================================================
// AVSPresentationController - bloquear SOMENTE telas de erro
// ================================================================
%hook AVSPresentationController

// Bloquear tela de login
- (void)showLogin {
    NSLog(@"[LordVCAMBypass] showLogin bloqueado");
}

// Bloquear tela de expirado
- (void)_avs_pres_showExp {
    NSLog(@"[LordVCAMBypass] showExp bloqueado");
}

// Bloquear tela de ban
- (void)_avs_pres_showBan:(id)a duration:(double)b _avs_cfg_banType:(NSInteger)c {}

// Bloquear falha de integridade
- (void)showIntegrityFailed         {}
- (void)buildAndShowIntegrityFailed {}

// buildAndShow: NAO bloqueado - e ele que abre o LordVCAM via gesto de volume
// Com _avs_cfg_st retornando 1, ele vai mostrar a camera, nao o login

%end

// ================================================================
// INIT - obrigatorio para ativar os hooks
// ================================================================
%ctor {
    NSLog(@"[LordVCAMBypass] v1.0.3 carregado em: %@",
          [[NSBundle mainBundle] bundleIdentifier] ?: @"(sem bundle)");
    %init;
}
