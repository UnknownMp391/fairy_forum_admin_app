import 'package:fairy_forum_admin_app/api/client.dart';
import 'package:fairy_forum_admin_app/config.dart';
import 'package:fairy_forum_admin_app/dto/auth/identity.dart';
import 'package:fairy_forum_admin_app/providers/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'identity.g.dart';

@riverpod
class IdentityStorageNotifier extends _$IdentityStorageNotifier {
  final idKey = SharedPreferencesKeys.adminId;
  final tokenKey = SharedPreferencesKeys.adminToken;

  @override
  FutureOr<IdentityData?> build() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getString(idKey);
    final token = prefs.getString(tokenKey);

    final valid = id != null && token != null;

    return valid ? IdentityData(adminId: id, adminToken: tokenKey) : null;
  }

  Future<void> setIdentity(IdentityData data) async {
    state = AsyncValue.loading();

    final prefs = await SharedPreferences.getInstance();

    prefs.setString(idKey, data.adminId);
    prefs.setString(tokenKey, data.adminToken);

    state = AsyncValue.data(data);
  }

  Future<void> clearIdentity() async {
    state = AsyncValue.loading();

    final prefs = await SharedPreferences.getInstance();

    prefs.remove(idKey);
    prefs.remove(tokenKey);

    state = AsyncValue.data(null);
  }
}

@riverpod
Future<bool> isValidIdentityAsync(Ref ref) async {
  final identity = ref
      .watch(identityStorageProvider)
      .whenOrNull(data: (data) => data);

  if (identity != null) {
    try {
      return await checkIdentityValid(identity, ref.read(dioProvider));
    } on NoValidIdentityException {
      return false;
    }
  } else {
    return false;
  }
}

@riverpod
bool isValidIdentity(Ref ref) => ref
    .watch(isValidIdentityAsyncProvider)
    .when(data: (data) => data, error: (_, _) => false, loading: () => false);

@riverpod
bool isValidingIdentity(Ref ref) =>
    ref.watch(isValidIdentityAsyncProvider).isLoading;
