import { ReloadlyClient } from '../src/reloadly/reloadly.client';
import { ReloadlyError } from '../src/reloadly/reloadly.types';

function jsonResponse(status: number, body: any) {
  return { ok: status >= 200 && status < 300, status, json: async () => body } as any;
}

describe('ReloadlyClient', () => {
  it('authenticates once and caches the token across calls', async () => {
    const calls: { url: string; init: any }[] = [];
    const fetchFn: any = async (url: string, init: any) => {
      calls.push({ url, init });
      if (url.includes('auth.reloadly.com')) return jsonResponse(200, { access_token: 'tok-1', expires_in: 3600 });
      return jsonResponse(200, { balance: 250, currencyCode: 'USD' });
    };
    const client = new ReloadlyClient({ clientId: 'id', clientSecret: 'sec', sandbox: true }, fetchFn);
    const b1 = await client.getBalance();
    const b2 = await client.getBalance();
    expect(b1.balance).toBe(250);
    expect(b2.balance).toBe(250);
    const authCalls = calls.filter((c) => c.url.includes('auth.reloadly.com'));
    expect(authCalls.length).toBe(1);
    expect(calls[1].url).toBe('https://topups-sandbox.reloadly.com/accounts/balance');
    expect(calls[1].init.headers.Authorization).toBe('Bearer tok-1');
    expect(calls[1].init.headers.Accept).toBe('application/com.reloadly.topups-v1+json');
    const authBody = JSON.parse(authCalls[0].init.body);
    expect(authBody.grant_type).toBe('client_credentials');
    expect(authBody.audience).toBe('https://topups-sandbox.reloadly.com');
  });

  it('builds the auto-detect URL with encoded phone and country code', async () => {
    const urls: string[] = [];
    const fetchFn: any = async (url: string) => {
      urls.push(url);
      if (url.includes('auth.reloadly.com')) return jsonResponse(200, { access_token: 't', expires_in: 3600 });
      return jsonResponse(200, { id: 999, name: 'Roshan Afghanistan', country: { isoName: 'AF' }, denominationType: 'RANGE' });
    };
    const client = new ReloadlyClient({ clientId: 'id', clientSecret: 'sec', sandbox: true }, fetchFn);
    const op = await client.autoDetectOperator('+93791234567', 'AF');
    expect(op.id).toBe(999);
    expect(urls[1]).toContain('/operators/auto-detect/phone/%2B93791234567/country-code/AF');
  });

  it('sends a topup with our customIdentifier and maps API errors', async () => {
    const bodies: any[] = [];
    const fetchFn: any = async (url: string, init: any) => {
      if (url.includes('auth.reloadly.com')) return jsonResponse(200, { access_token: 't', expires_in: 3600 });
      bodies.push(JSON.parse(init.body));
      return jsonResponse(200, { transactionId: 42, operatorId: 999, status: 'SUCCESSFUL' });
    };
    const client = new ReloadlyClient({ clientId: 'id', clientSecret: 'sec', sandbox: true }, fetchFn);
    const resp = await client.sendTopup({
      operatorId: 999, amount: 500, useLocalAmount: true, customIdentifier: 'our-uuid-1',
      recipientPhone: { countryCode: 'AF', number: '+93791234567' },
    });
    expect(resp.status).toBe('SUCCESSFUL');
    expect(bodies[0].customIdentifier).toBe('our-uuid-1');

    const errFetch: any = async (url: string) => {
      if (url.includes('auth.reloadly.com')) return jsonResponse(200, { access_token: 't', expires_in: 3600 });
      return jsonResponse(401, { errorCode: 'UNAUTHORIZED', message: 'bad token' });
    };
    const bad = new ReloadlyClient({ clientId: 'id', clientSecret: 'sec', sandbox: true }, errFetch);
    await expect(bad.getBalance()).rejects.toBeInstanceOf(ReloadlyError);
  });

  it('refuses to run without credentials', async () => {
    const client = new ReloadlyClient({ clientId: '', clientSecret: '', sandbox: true }, fetch as any);
    await expect(client.getBalance()).rejects.toThrow(/not configured/);
  });
});
