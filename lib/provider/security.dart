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
final _showUnlock = ValueNotifier(false);

final secureStorage = SecureStorage(
  ohosStorage: RunPlatform.isOhos ? const ohos.FlutterSecureStorage() : null,
  storage: RunPlatform.isOhos ? null : const FlutterSecureStorage(),
);

@Riverpod(keepAlive: true)
List<BiometricType> biometrics(Ref ref) => [];

@Riverpod(keepAlive: true)
class BiometricNotifier extends _$BiometricNotifier {
  final String cacheKey = "certimate-biometric";

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
  final String cacheKey = "certimate-privacy-blur";

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
  try {
    final biometrics = await _auth.getAvailableBiometrics();
    if (biometrics.isNotEmpty) {
      return biometrics;
    } else {
      return [BiometricType.strong];
    }
  } catch (e) {
    return [];
  }
}

final _privacyBlurDialogTag = "privacyBlurDialog";

void onAppLifecycleStateChangeBySecurity(
  WidgetRef ref,
  AppLifecycleState? previous,
  AppLifecycleState current,
) {
  final privacyBlur = ref.read(privacyBlurProvider);
  final biometrics = ref.read(biometricsProvider);
  final biometric = ref.read(biometricProvider);
  if (current == AppLifecycleState.inactive) {
    if (privacyBlur || biometric) {
      _showPrivacyBlurDialog(biometrics);
    }
  } else if (current == AppLifecycleState.resumed) {
    if (biometric &&
        DateTime.now().millisecondsSinceEpoch - _lastUnlockTime > 60 * 1000) {
      // 距离上次解锁超过 1 分钟
      _showUnlock.value = true;
    }
    if (_showUnlock.value) {
      // 需要解锁
      _showPrivacyBlurDialog(biometrics);
    } else {
      // 不需要解锁，直接关闭模糊弹窗
      SmartDialog.dismiss(tag: _privacyBlurDialogTag);
    }
  }
}

Future<bool> _localAuth() async {
  final didAuthenticate = await localAuthenticate(S.current.unlockAppTip);
  if (didAuthenticate) {
    _showUnlock.value = false;
    SmartDialog.dismiss(tag: _privacyBlurDialogTag);
  }
  return didAuthenticate;
}

void _showPrivacyBlurDialog(List<BiometricType> biometrics) {
  if (SmartDialog.checkExist(tag: _privacyBlurDialogTag)) {
    return;
  }
  SmartDialog.show(
    tag: _privacyBlurDialogTag,
    animationType: SmartAnimationType.fade,
    maskWidget: const SizedBox(),
    builder: (context) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          alignment: Alignment.center,
          color: Colors.white.withValues(alpha: 0.01),
          child: ValueListenableBuilder(
            valueListenable: _showUnlock,
            builder: (_, value, child) {
              return value ? child! : const SizedBox();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoWell(
                  onPressed: () => _localAuth(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      biometrics.contains(BiometricType.face)
                          ? const Icon(TablerIcons.face_id, size: 32)
                          : const Icon(TablerIcons.fingerprint_scan, size: 32),
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

Future<bool> localAuthenticate(String msg) async {
  try {
    final didAuthenticate = await _auth.authenticate(localizedReason: msg);
    if (didAuthenticate) {
      // 避免开启后台锁定后立马发起认证
      _lastUnlockTime = DateTime.now().millisecondsSinceEpoch;
    }
    return didAuthenticate;
  } on PlatformException catch (e) {
    if (e.code != "UserCancelled") {
      SmartDialog.showToast(
        e.code == "NotEnrolled" ||
                e.message == "No Biometrics enrolled on this device."
            ? S.current.noCredentialsSetTip
            : (e.message ?? e.code),
      );
    }
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
