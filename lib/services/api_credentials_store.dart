import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ApiCredentialKind { gemini, render }

class ApiCredentials {
  const ApiCredentials({
    required this.geminiApiKey,
    required this.renderApiKey,
  });

  const ApiCredentials.empty() : geminiApiKey = '', renderApiKey = '';

  final String geminiApiKey;
  final String renderApiKey;

  bool get hasGeminiApiKey => geminiApiKey.trim().isNotEmpty;
  bool get hasRenderApiKey => renderApiKey.trim().isNotEmpty;
  bool get isComplete => hasGeminiApiKey && hasRenderApiKey;

  ApiCredentials copyWith({String? geminiApiKey, String? renderApiKey}) {
    return ApiCredentials(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      renderApiKey: renderApiKey ?? this.renderApiKey,
    );
  }

  ApiCredentials trimmed() {
    return ApiCredentials(
      geminiApiKey: geminiApiKey.trim(),
      renderApiKey: renderApiKey.trim(),
    );
  }

  ApiCredentials mergeMissing(ApiCredentials fallback) {
    return ApiCredentials(
      geminiApiKey: hasGeminiApiKey ? geminiApiKey : fallback.geminiApiKey,
      renderApiKey: hasRenderApiKey ? renderApiKey : fallback.renderApiKey,
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
  static const String _renderKey = 'archivision.render_api_key';

  final FlutterSecureStorage _storage;
  final SharedPreferencesAsync _preferences;

  @override
  Future<ApiCredentials> readCredentials() async {
    final secureCredentials = await _readSecureCredentials();
    final fallbackCredentials = await _readPreferenceCredentials();

    final geminiApiKey = secureCredentials.geminiApiKey.isNotEmpty
        ? secureCredentials.geminiApiKey
        : fallbackCredentials.geminiApiKey;
    final renderApiKey = secureCredentials.renderApiKey.isNotEmpty
        ? secureCredentials.renderApiKey
        : fallbackCredentials.renderApiKey;

    return ApiCredentials(
      geminiApiKey: geminiApiKey,
      renderApiKey: renderApiKey,
    ).trimmed();
  }

  @override
  Future<void> saveCredentials(ApiCredentials credentials) async {
    final normalized = credentials.trimmed();
    await saveKey(ApiCredentialKind.gemini, normalized.geminiApiKey);
    await saveKey(ApiCredentialKind.render, normalized.renderApiKey);
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
      ApiCredentialKind.render => _renderKey,
    };

    await _preferences.setString(key, normalized);

    try {
      await _storage.write(key: key, value: normalized);
    } catch (_) {
      // Fallback persistence via SharedPreferences is already written above.
    }
  }

  @override
  Future<void> clearKey(ApiCredentialKind kind) async {
    final key = switch (kind) {
      ApiCredentialKind.gemini => _geminiKey,
      ApiCredentialKind.render => _renderKey,
    };

    await _preferences.remove(key);

    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Ignore secure-store cleanup failures when fallback storage was cleared.
    }
  }

  Future<ApiCredentials> _readSecureCredentials() async {
    try {
      final geminiApiKey = await _storage.read(key: _geminiKey) ?? '';
      final renderApiKey = await _storage.read(key: _renderKey) ?? '';
      return ApiCredentials(
        geminiApiKey: geminiApiKey,
        renderApiKey: renderApiKey,
      ).trimmed();
    } catch (_) {
      return const ApiCredentials.empty();
    }
  }

  Future<ApiCredentials> _readPreferenceCredentials() async {
    final geminiApiKey = await _preferences.getString(_geminiKey) ?? '';
    final renderApiKey = await _preferences.getString(_renderKey) ?? '';
    return ApiCredentials(
      geminiApiKey: geminiApiKey,
      renderApiKey: renderApiKey,
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
      ApiCredentialKind.render => _credentials.copyWith(
        renderApiKey: normalized,
      ),
    };
  }

  @override
  Future<void> clearKey(ApiCredentialKind kind) async {
    await saveKey(kind, '');
  }
}
