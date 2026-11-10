/// Build-time configuration (pass with --dart-define).
/// API_BASE_URL: Phase 1 backend. Android emulator reaches the host at 10.0.2.2.
/// STRIPE_PUBLISHABLE_KEY: pk_test_... from the Stripe dashboard (Phase 0).
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  // Phase 2 dev auth: matches the backend's dev guard (x-user-id header).
  // Phase 2.5 replaces this with Firebase ID tokens.
  static const String devUserId = String.fromEnvironment(
    'DEV_USER_ID',
    defaultValue: 'dev-user-1',
  );
}
