export interface AppConfig {
  port: number;
  chargeCurrency: string;
  feeBps: number;
  feeFixedMinor: number;
  feeMinMinor: number;
  reloadly: { clientId: string; clientSecret: string; sandbox: boolean };
  stripe: { secretKey: string; webhookSecret: string };
  firebaseAuthEnabled: boolean;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  return {
    port: parseInt(env.PORT || '3000', 10),
    chargeCurrency: (env.CHARGE_CURRENCY || 'EUR').toUpperCase(),
    feeBps: parseInt(env.FEE_BPS || '800', 10),
    feeFixedMinor: parseInt(env.FEE_FIXED_MINOR || '35', 10),
    feeMinMinor: parseInt(env.FEE_MIN_MINOR || '49', 10),
    reloadly: {
      clientId: env.RELOADLY_CLIENT_ID || '',
      clientSecret: env.RELOADLY_CLIENT_SECRET || '',
      sandbox: (env.RELOADLY_SANDBOX || 'true') !== 'false',
    },
    stripe: {
      secretKey: env.STRIPE_SECRET_KEY || '',
      webhookSecret: env.STRIPE_WEBHOOK_SECRET || '',
    },
    firebaseAuthEnabled: env.FIREBASE_AUTH_ENABLED === 'true',
  };
}
