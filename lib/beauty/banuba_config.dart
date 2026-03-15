/// Banuba configuration.
///
/// Preferred: provide tokens via --dart-define so secrets are not committed.
/// Example:
/// flutter run --dart-define=BANUBA_CLIENT_TOKEN=... --dart-define=BANUBA_AR_CLOUD_TOKEN=...
class BanubaConfig {
  // Optional fallback for local-only testing if you really want to paste directly.
  // Keep these empty in source control.
  static const _clientTokenFallback = '';
  static const _arCloudTokenFallback = '';

  static const clientToken = String.fromEnvironment(
    'BANUBA_CLIENT_TOKEN',
    defaultValue: _clientTokenFallback,
  );

  static const arCloudToken = String.fromEnvironment(
    'BANUBA_AR_CLOUD_TOKEN',
    defaultValue: _arCloudTokenFallback,
  );

  static bool get hasClientToken => clientToken.trim().isNotEmpty;
  static bool get hasArCloudToken => arCloudToken.trim().isNotEmpty;
  static bool get hasRequiredTokens => hasClientToken && hasArCloudToken;
}
