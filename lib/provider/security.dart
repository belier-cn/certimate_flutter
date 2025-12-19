import "dart:ui";

import "package:certimate/extension/index.dart";
import "package:certimate/generated/l10n.dart";
import "package:certimate/widgets/well.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_secure_storage_ohos/flutter_secure_storage_ohos.dart"
    as ohos;
import "package:flutter_smart_dialog/flutter_smart_dialog.dart";
import "package:flutter_tabler_icons/flutter_tabler_icons.dart";
import "package:local_auth/local_auth.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:sp_util/sp_util.dart";

part "security.g.dart";

final LocalAuthentication _auth = LocalAuthentication();

final secureStorage = SecureStorage(
  ohosStorage: RunPlatform.isOhos ? const ohos.FlutterSecureStorage() : null,
  storage: RunPlatform.isOhos ? null : const FlutterSecureStorage(),
);

@Riverpod(keepAlive: true)
List<BiometricType> biometrics(Ref ref) => [];

@Riverpod(keepAlive: true)
class BiometricNotifier extends _$BiometricNotifier {
  final String cacheKey = "biometric";

  @override
  bool build() {
    return SpUtil.getBool(cacheKey, defValue: false)!;
  }

  void update(bool biometric) {
    state = biometric;
    SpUtil.putBool(cacheKey, biometric);
  }
}

@Riverpod(keepAlive: true)
class PrivacyBlurNotifier extends _$PrivacyBlurNotifier {
  final String cacheKey = "privacy_blur";

  @override
  bool build() {
    return SpUtil.getBool(cacheKey, defValue: !kIsWeb)!;
  }

  void update(bool privacyBlur) {
    state = privacyBlur;
    SpUtil.putBool(cacheKey, privacyBlur);
  }
}

int _lastUnlockTime = 0;

Future<List<BiometricType>> getAvailableBiometrics() async {
  if (kIsWeb) {
    return [];
  }
  if (RunPlatform.isOhos) {
    return [BiometricType.strong];
  }
  if (await _auth.canCheckBiometrics) {
    final biometrics = await _auth.getAvailableBiometrics();
    if (biometrics.isNotEmpty) {
      return biometrics;
    } else {
      return [BiometricType.strong];
    }
  }
  return [];
}

void onAppLifecycleStateChangeBySecurity(
  WidgetRef ref,
  AppLifecycleState? previous,
  AppLifecycleState current,
  ValueNotifier<bool> showUnlock, {
  bool first = false,
}) {
  final privacyBlur = ref.read(privacyBlurProvider);
  final biometrics = ref.read(biometricsProvider);
  final biometric = ref.read(biometricProvider);
  final tag = "privacyBlur";
  if (current == AppLifecycleState.inactive) {
    if ((privacyBlur || biometric) && !SmartDialog.checkExist(tag: tag)) {
      showUnlock.value = first;
      SmartDialog.show(
        tag: tag,
        animationType: SmartAnimationType.fade,
        maskWidget: const SizedBox(),
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              alignment: Alignment.center,
              color: Colors.white.withValues(alpha: 0.01),
              child: ValueListenableBuilder(
                valueListenable: showUnlock,
                builder: (_, value, child) {
                  return value ? child! : const SizedBox();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoWell(
                      onPressed: () => _localAuth(tag),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          biometrics.contains(BiometricType.face)
                              ? const Icon(TablerIcons.face_id, size: 32)
                              : const Icon(
                                  TablerIcons.fingerprint_scan,
                                  size: 32,
                                ),
                          Text(
                            S.current.unlock.capitalCase,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.current.lockedTip,
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  } else if (current == AppLifecycleState.resumed) {
    if (previous == AppLifecycleState.paused &&
        biometric &&
        DateTime.now().millisecondsSinceEpoch - _lastUnlockTime > 60 * 1000) {
      if (!showUnlock.value) {
        _localAuth(tag);
      }
      showUnlock.value = true;
    } else if (!showUnlock.value) {
      SmartDialog.dismiss(tag: tag);
    }
  }
}

void _localAuth(String tag) async {
  final didAuthenticate = await localAuthenticate(S.current.unlockAppTip);
  if (didAuthenticate) {
    SmartDialog.dismiss(tag: tag);
  }
}

Future<bool> localAuthenticate(String msg) async {
  try {
    final didAuthenticate = await _auth.authenticate(localizedReason: msg);
    if (didAuthenticate) {
      // 避免开启后台锁定后立马发起认证
      _lastUnlockTime = DateTime.now().millisecondsSinceEpoch;
    }
    return didAuthenticate;
  } on PlatformException catch (e) {
    SmartDialog.showToast(
      e.code == "NotEnrolled" ||
              e.message == "No Biometrics enrolled on this device."
          ? S.current.noCredentialsSetTip
          : (e.message ?? e.code),
    );
    rethrow;
  }
}

class SecureStorage {
  FlutterSecureStorage? storage;

  ohos.FlutterSecureStorage? ohosStorage;

  SecureStorage({this.storage, this.ohosStorage});

  Future<void> write({required String key, required String? value}) async {
    if (storage != null) {
      await storage!.write(key: key, value: value);
    } else if (ohosStorage != null) {
      await ohosStorage!.write(key: key, value: value);
    }
  }

  Future<String?> read({required String key}) async {
    if (storage != null) {
      return await storage!.read(key: key);
    } else if (ohosStorage != null) {
      return await ohosStorage!.read(key: key);
    }
    return null;
  }

  Future<void> delete({required String key}) async {
    if (storage != null) {
      await storage!.delete(key: key);
    } else if (ohosStorage != null) {
      await ohosStorage!.delete(key: key);
    }
  }
}
