import { Injectable, Logger } from '@nestjs/common';
import {
  ReloadlyBalance, ReloadlyCountry, ReloadlyError, ReloadlyOperator,
  ReloadlyTopupRequest, ReloadlyTopupResponse,
} from './reloadly.types';

export interface ReloadlyClientConfig { clientId: string; clientSecret: string; sandbox: boolean; }
type FetchFn = typeof fetch;

/**
 * Reloadly Airtime client — verified against Reloadly's docs (Nov 2026):
 *  - OAuth2 client-credentials: POST https://auth.reloadly.com/oauth/token
 *    with audience = the product base URL. Sandbox tokens live 24h, live 60d.
 *  - Sandbox base: https://topups-sandbox.reloadly.com (preloaded test balance)
 *    Live base:    https://topups.reloadly.com
 *  - Every call needs header Accept: application/com.reloadly.topups-v1+json
 *  - customIdentifier must be unique per top-up and can never be reused.
 */
@Injectable()
export class ReloadlyClient {
  private readonly logger = new Logger(ReloadlyClient.name);
  private token: { value: string; expiresAt: number } | null = null;

  constructor(
    private readonly cfg: ReloadlyClientConfig,
    private readonly fetchFn: FetchFn = fetch,
    private readonly now: () => number = Date.now,
  ) {}

  get baseUrl(): string {
    return this.cfg.sandbox ? 'https://topups-sandbox.reloadly.com' : 'https://topups.reloadly.com';
  }

  private async getAccessToken(): Promise<string> {
    if (this.token && this.now() < this.token.expiresAt - 120_000) return this.token.value;
    if (!this.cfg.clientId || !this.cfg.clientSecret) {
      throw new ReloadlyError(0, 'MISSING_CREDENTIALS', 'Reloadly client_id/client_secret not configured (Phase 0: fill .env)');
    }
    const res = await this.fetchFn('https://auth.reloadly.com/oauth/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        client_id: this.cfg.clientId,
        client_secret: this.cfg.clientSecret,
        grant_type: 'client_credentials',
        audience: this.baseUrl,
      }),
    });
    const body: any = await res.json().catch(() => ({}));
    if (!res.ok || !body.access_token) {
      throw new ReloadlyError(res.status, body.error || 'AUTH_FAILED', `Reloadly auth failed (${res.status})`, body);
    }
    const ttlMs = (body.expires_in ? body.expires_in * 1000 : 3600_000);
    this.token = { value: body.access_token, expiresAt: this.now() + ttlMs };
    return this.token.value;
  }

  private async request<T>(method: string, path: string, body?: unknown): Promise<T> {
    const token = await this.getAccessToken();
    const res = await this.fetchFn(`${this.baseUrl}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'application/com.reloadly.topups-v1+json',
        ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const data: any = await res.json().catch(() => ({}));
    if (!res.ok) {
      throw new ReloadlyError(
        res.status,
        data.errorCode || data.error || null,
        data.message || `Reloadly ${method} ${path} failed (${res.status})`,
        data,
      );
    }
    return data as T;
  }

  getBalance(): Promise<ReloadlyBalance> {
    return this.request<ReloadlyBalance>('GET', '/accounts/balance');
  }

  listCountries(): Promise<ReloadlyCountry[]> {
    return this.request<ReloadlyCountry[]>('GET', '/countries');
  }

  getCountry(iso: string): Promise<ReloadlyCountry> {
    return this.request<ReloadlyCountry>('GET', `/countries/${iso}`);
  }

  listOperatorsByCountry(iso: string): Promise<ReloadlyOperator[]> {
    return this.request<ReloadlyOperator[]>('GET', `/operators/countries/${iso}?includeBundles=true&SuggestedAmounts=true`);
  }

  getOperator(operatorId: number): Promise<ReloadlyOperator> {
    return this.request<ReloadlyOperator>('GET', `/operators/${operatorId}`);
  }

  /** Auto-detect the operator for a phone number (source of truth for operator). */
  autoDetectOperator(phoneE164: string, countryIso: string): Promise<ReloadlyOperator> {
    const phone = encodeURIComponent(phoneE164);
    return this.request<ReloadlyOperator>('GET', `/operators/auto-detect/phone/${phone}/country-code/${countryIso}?includeBundles=true&SuggestedAmounts=true`);
  }

  /** FX quote: how much of the account currency a local amount costs. */
  fxRate(operatorId: number, amountMajor: number, currencyCode?: string): Promise<any> {
    return this.request<any>('POST', '/operators/fx-rate', { operatorId, amount: amountMajor, currencyCode });
  }

  /** Send a top-up synchronously. customIdentifier = our transaction UUID. */
  sendTopup(req: ReloadlyTopupRequest): Promise<ReloadlyTopupResponse> {
    return this.request<ReloadlyTopupResponse>('POST', '/topups', req);
  }

  /** Send a top-up asynchronously; poll with getTopupStatus. */
  sendTopupAsync(req: ReloadlyTopupRequest): Promise<ReloadlyTopupResponse> {
    return this.request<ReloadlyTopupResponse>('POST', '/topups-async', req);
  }

  getTopupStatus(transactionId: number): Promise<ReloadlyTopupResponse> {
    return this.request<ReloadlyTopupResponse>('GET', `/topups/${transactionId}/status`);
  }
}
