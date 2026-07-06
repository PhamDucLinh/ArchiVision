import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ApiCredentialKind { gemini }

class ApiCredentials {
  const ApiCredentials({required this.geminiApiKey});

  const ApiCredentials.empty() : geminiApiKey = '';

  final String geminiApiKey;

  bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
  bool get isComplete => hasGeminiApiKey;

  ApiCredentials copyWith({String? geminiApiKey}) {
    return ApiCredentials(geminiApiKey: geminiApiKey ?? this.geminiApiKey);
  }

  ApiCredentials trimmed() {
    return ApiCredentials(geminiApiKey: geminiApiKey.trim());
  }

  ApiCredentials mergeMissing(ApiCredentials fallback) {
    return ApiCredentials(
      geminiApiKey: hasGeminiApiKey ? geminiApiKey : fallback.geminiApiKey,
    ).trimmed();
  }
}

abstract interface class ApiCredentialsStore {
  Future<ApiCredentials> readCredentials();

  Future<void> saveCredentials(ApiCredentials credentials);

  Future<void> saveKey(ApiCredentialKind kind, String value);

  Future<void> clearKey(ApiCredentialKind kind);
}

class SecureApiCredentialsStore implements ApiCredentialsStore {
  SecureApiCredentialsStore({
    FlutterSecureStorage? storage,
    SharedPreferencesAsync? preferences,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const String _geminiKey = 'archivision.gemini_api_key';
  static const String _legacyRenderKey = 'archivision.render_api_key';

  final FlutterSecureStorage _storage;
  final SharedPreferencesAsync _preferences;

  @override
  Future<ApiCredentials> readCredentials() async {
    final secureCredentials = await _readSecureCredentials();
    final fallbackCredentials = await _readPreferenceCredentials();

    final geminiApiKey = secureCredentials.hasGeminiApiKey
        ? secureCredentials.geminiApiKey
        : fallbackCredentials.geminiApiKey;

    return ApiCredentials(geminiApiKey: geminiApiKey).trimmed();
  }

  @override
  Future<void> saveCredentials(ApiCredentials credentials) async {
    final normalized = credentials.trimmed();
    await saveKey(ApiCredentialKind.gemini, normalized.geminiApiKey);
  }

  @override
  Future<void> saveKey(ApiCredentialKind kind, String value) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      await clearKey(kind);
      return;
    }

    final key = switch (kind) {
      ApiCredentialKind.gemini => _geminiKey,
    };

    await _preferences.setString(key, normalized);
    await _preferences.remove(_legacyRenderKey);

    try {
      await _storage.write(key: key, value: normalized);
      await _storage.delete(key: _legacyRenderKey);
    } catch (_) {
      // Fallback persistence via SharedPreferences is already written above.
    }
  }

  @override
  Future<void> clearKey(ApiCredentialKind kind) async {
    final key = switch (kind) {
      ApiCredentialKind.gemini => _geminiKey,
    };

    await _preferences.remove(key);
    await _preferences.remove(_legacyRenderKey);

    try {
      await _storage.delete(key: key);
      await _storage.delete(key: _legacyRenderKey);
    } catch (_) {
      // Ignore secure-store cleanup failures when fallback storage was cleared.
    }
  }

  Future<ApiCredentials> _readSecureCredentials() async {
    try {
      final geminiApiKey = await _storage.read(key: _geminiKey) ?? '';
      final legacyRenderApiKey =
          await _storage.read(key: _legacyRenderKey) ?? '';
      return ApiCredentials(
        geminiApiKey: _resolveGeminiKey(
          primary: geminiApiKey,
          legacy: legacyRenderApiKey,
        ),
      ).trimmed();
    } catch (_) {
      return const ApiCredentials.empty();
    }
  }

  Future<ApiCredentials> _readPreferenceCredentials() async {
    final geminiApiKey = await _preferences.getString(_geminiKey) ?? '';
    final legacyRenderApiKey =
        await _preferences.getString(_legacyRenderKey) ?? '';
    return ApiCredentials(
      geminiApiKey: _resolveGeminiKey(
        primary: geminiApiKey,
        legacy: legacyRenderApiKey,
      ),
    ).trimmed();
  }
}

class MemoryApiCredentialsStore implements ApiCredentialsStore {
  MemoryApiCredentialsStore({ApiCredentials? initialCredentials})
    : _credentials = (initialCredentials ?? const ApiCredentials.empty())
          .trimmed();

  ApiCredentials _credentials;

  @override
  Future<ApiCredentials> readCredentials() async => _credentials;

  @override
  Future<void> saveCredentials(ApiCredentials credentials) async {
    _credentials = credentials.trimmed();
  }

  @override
  Future<void> saveKey(ApiCredentialKind kind, String value) async {
    final normalized = value.trim();
    _credentials = switch (kind) {
      ApiCredentialKind.gemini => _credentials.copyWith(
        geminiApiKey: normalized,
      ),
    };
  }

  @override
  Future<void> clearKey(ApiCredentialKind kind) async {
    await saveKey(kind, '');
  }
}

String _resolveGeminiKey({required String primary, required String legacy}) {
  if (primary.trim().isNotEmpty) {
    return primary;
  }
  return legacy;
}
