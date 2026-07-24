// LordVCAM Bypass Tweak - Remove authentication
// Compile with: make THEOS_PACKAGE_SCHEME=rootless (for Dopamine)

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Target: AVServicesd.dylib (LordVCAM)
%config(generator=internal)

// Hook the main authorization flag
%hook AVSConfig

// Force authorized state to YES
- (BOOL)_avs_cfg_authorized {
    NSLog(@"[LordVCAM-Bypass] _avs_cfg_authorized hooked, returning YES");
    return YES;
}

// Force purchase state to YES  
- (BOOL)_avs_cfg_isPurch {
    NSLog(@"[LordVCAM-Bypass] _avs_cfg_isPurch hooked, returning YES");
    return YES;
}

// Force gallery state to active
- (long long)_avs_cfg_galSt {
    NSLog(@"[LordVCAM-Bypass] _avs_cfg_galSt hooked, returning active state");
    return 2; // Assuming 2 = active state
}

// Force connection state to connected
- (long long)_avs_cfg_connSt {
    NSLog(@"[LordVCAM-Bypass] _avs_cfg_connSt hooked, returning connected");
    return 1; // Assuming 1 = connected
}

// Override license expiry to far future
- (double)_avs_cfg_expiry {
    NSLog(@"[LordVCAM-Bypass] _avs_cfg_expiry hooked, returning future date");
    return [[NSDate dateWithTimeIntervalSinceNow:86400*365*10] timeIntervalSince1970]; // +10 years
}

// Override balance to high amount
- (double)_avs_cfg_balance {
    NSLog(@"[LordVCAM-Bypass] _avs_cfg_balance hooked, returning 999.99");
    return 999.99;
}

%end

// Hook license validation functions
%hook AVSLicenseValidator

// Always return success for license validation
- (BOOL)validateLicenseProof:(id)proof {
    NSLog(@"[LordVCAM-Bypass] validateLicenseProof hooked, returning YES");
    return YES;
}

// Skip integrity checks
- (BOOL)checkIntegrity {
    NSLog(@"[LordVCAM-Bypass] checkIntegrity hooked, returning YES");
    return YES;
}

// Skip server validation
- (void)performServerValidation {
    NSLog(@"[LordVCAM-Bypass] performServerValidation hooked, skipping");
    // Do nothing - skip server check
}

%end

// Hook anti-tamper detection
%hook AVSAntiTamper

// Disable Frida detection
- (BOOL)detectFrida {
    NSLog(@"[LordVCAM-Bypass] detectFrida hooked, returning NO");
    return NO;
}

// Disable debugger detection  
- (BOOL)detectDebugger {
    NSLog(@"[LordVCAM-Bypass] detectDebugger hooked, returning NO");
    return NO;
}

// Disable tweak conflict detection
- (BOOL)detectConflictingTweaks {
    NSLog(@"[LordVCAM-Bypass] detectConflictingTweaks hooked, returning NO");
    return NO;
}

%end

// Hook WebSocket validation
%hook AVSWebSocketManager

// Skip WebSocket license validation
- (void)validateLicenseViaWebSocket {
    NSLog(@"[LordVCAM-Bypass] validateLicenseViaWebSocket hooked, skipping");
    // Trigger success callback directly
    [self onValidationSuccess];
}

// Simulate successful WebSocket connection
- (BOOL)isWebSocketConnected {
    NSLog(@"[LordVCAM-Bypass] isWebSocketConnected hooked, returning YES");
    return YES;
}

%end

// Hook ban system
%hook AVSBanManager

// Disable all bans
- (BOOL)isBanned {
    NSLog(@"[LordVCAM-Bypass] isBanned hooked, returning NO");
    return NO;
}

// Clear persistent bans
- (void)setBanned:(BOOL)banned withReason:(NSString*)reason duration:(NSTimeInterval)duration {
    NSLog(@"[LordVCAM-Bypass] setBanned hooked, ignoring ban attempt");
    // Do nothing - ignore all ban attempts
}

%end

// Constructor - runs when dylib loads
%ctor {
    NSLog(@"[LordVCAM-Bypass] Tweak loaded successfully");
    
    // Create fake cache directory with success markers
    NSString *cacheDir = @"/var/tmp/com.apple.avfcache";
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:cacheDir]) {
        [fm createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // Create fake license file
    NSString *licenseFile = [cacheDir stringByAppendingPathComponent:@"license.plist"];
    NSDictionary *fakeLicense = @{
        @"authorized": @YES,
        @"purchased": @YES,
        @"expiry": @([[NSDate dateWithTimeIntervalSinceNow:86400*365*10] timeIntervalSince1970]),
        @"balance": @999.99,
        @"lastValidation": @([[NSDate date] timeIntervalSince1970]),
        @"deviceHash": @"bypass_device_hash",
        @"integrity": @"bypass_integrity_hash"
    };
    
    [fakeLicense writeToFile:licenseFile atomically:YES];
    NSLog(@"[LordVCAM-Bypass] Created fake license file at %@", licenseFile);
}
