import { TopupStatus } from '../domain/transaction-state';

// Repository interfaces: Phase 1 ships in-memory implementations (used by the
// API in dev and by every test). Prisma/PostgreSQL implements the same
// interfaces for production — schema in prisma/schema.prisma.

export interface TopupRecord {
  id: string;
  userId: string;
  idempotencyKey: string;
  recipientPhone: string;
  countryIso: string;
  operatorId: number;
  operatorName: string;
  amountLocalMinor: number;
  localCurrency: string;
  costMinor: number;
  feeMinor: number;
  totalMinor: number;
  chargeCurrency: string;
  status: TopupStatus;
  stripePaymentIntentId: string | null;
  reloadlyTransactionId: number | null;
  failureReason: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface TopupRepository {
  create(rec: TopupRecord): Promise<TopupRecord>;
  getById(id: string): Promise<TopupRecord | null>;
  getByIdempotencyKey(key: string): Promise<TopupRecord | null>;
  getByPaymentIntentId(piId: string): Promise<TopupRecord | null>;
  update(rec: TopupRecord): Promise<TopupRecord>;
  listByUser(userId: string): Promise<TopupRecord[]>;
  listByStatus(status: TopupStatus): Promise<TopupRecord[]>;
}

export class InMemoryTopupRepository implements TopupRepository {
  private byId = new Map<string, TopupRecord>();
  async create(rec: TopupRecord) { this.byId.set(rec.id, { ...rec }); return { ...rec }; }
  async getById(id: string) { const r = this.byId.get(id); return r ? { ...r } : null; }
  async getByIdempotencyKey(key: string) {
    const r = [...this.byId.values()].find((x) => x.idempotencyKey === key);
    return r ? { ...r } : null;
  }
  async getByPaymentIntentId(piId: string) {
    const r = [...this.byId.values()].find((x) => x.stripePaymentIntentId === piId);
    return r ? { ...r } : null;
  }
  async update(rec: TopupRecord) { this.byId.set(rec.id, { ...rec }); return { ...rec }; }
  async listByUser(userId: string) {
    return [...this.byId.values()].filter((x) => x.userId === userId).map((r) => ({ ...r }));
  }
  async listByStatus(status: TopupStatus) {
    return [...this.byId.values()].filter((x) => x.status === status).map((r) => ({ ...r }));
  }
}

export interface CatalogOperatorRecord {
  operatorId: number;
  name: string;
  countryIso: string;
  denominationType: 'FIXED' | 'RANGE';
  localMinMinor: number | null;
  localMaxMinor: number | null;
  fixedLocalAmountsMajor: number[];
  supportsData: boolean;
  logoUrl: string | null;
}

export class InMemoryCatalogRepository {
  private ops = new Map<number, CatalogOperatorRecord>();
  async upsertOperator(rec: CatalogOperatorRecord) { this.ops.set(rec.operatorId, { ...rec }); }
  async getOperator(operatorId: number) { const r = this.ops.get(operatorId); return r ? { ...r } : null; }
  async listByCountry(countryIso: string) {
    return [...this.ops.values()].filter((o) => o.countryIso === countryIso).map((r) => ({ ...r }));
  }
  async all() { return [...this.ops.values()].map((r) => ({ ...r })); }
}
