//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<permission_handler_apple/PermissionHandlerPlugin.h>)
#import <permission_handler_apple/PermissionHandlerPlugin.h>
#else
@import permission_handler_apple;
#endif

#if __has_include(<scandit_flutter_datacapture_barcode/ScanditFlutterDataCaptureBarcode.h>)
#import <scandit_flutter_datacapture_barcode/ScanditFlutterDataCaptureBarcode.h>
#else
@import scandit_flutter_datacapture_barcode;
#endif

#if __has_include(<scandit_flutter_datacapture_core/ScanditFlutterDataCaptureCore.h>)
#import <scandit_flutter_datacapture_core/ScanditFlutterDataCaptureCore.h>
#else
@import scandit_flutter_datacapture_core;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [PermissionHandlerPlugin registerWithRegistrar:[registry registrarForPlugin:@"PermissionHandlerPlugin"]];
  [ScanditFlutterDataCaptureBarcode registerWithRegistrar:[registry registrarForPlugin:@"ScanditFlutterDataCaptureBarcode"]];
  [ScanditFlutterDataCaptureCore registerWithRegistrar:[registry registrarForPlugin:@"ScanditFlutterDataCaptureCore"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
