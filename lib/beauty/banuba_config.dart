/// Banuba configuration.
///
/// Preferred: provide tokens via --dart-define so secrets are not committed.
/// Example:
/// flutter run --dart-define=BANUBA_CLIENT_TOKEN="..." --dart-define=BANUBA_AR_CLOUD_TOKEN="..."
/// PowerShell note: pass the token directly and do not prefix it with '$'.
class BanubaConfig {
  // Optional fallback for local-only testing if you really want to paste directly.
  // Keep these empty in source control.
  static const _clientTokenFallback = '';
  static const _arCloudTokenFallback = '';

  static const _clientTokenPrimary = String.fromEnvironment(
    'BANUBA_CLIENT_TOKEN',
    defaultValue: '',
  );

  // Backward-compatible alias for CI environments that used another key.
  static const _clientTokenAlias = String.fromEnvironment(
    'BANUBA_TOKEN',
    defaultValue: '',
  );

  static const arCloudToken = String.fromEnvironment(
    'BANUBA_AR_CLOUD_TOKEN',
    defaultValue: _arCloudTokenFallback,
  );

  static String get clientToken {
    final primary = _clientTokenPrimary.trim();
    if (primary.isNotEmpty) return primary;
    final alias = _clientTokenAlias.trim();
    if (alias.isNotEmpty) return alias;
    return _clientTokenFallback.trim();
  }

  static bool get hasClientToken => clientToken.isNotEmpty;
  static bool get hasArCloudToken => arCloudToken.trim().isNotEmpty;
  static bool get hasRequiredTokens => hasClientToken && hasArCloudToken;
}
