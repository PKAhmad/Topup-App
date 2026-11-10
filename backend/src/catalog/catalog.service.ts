import { Injectable, Logger } from '@nestjs/common';
import { ReloadlyClient } from '../reloadly/reloadly.client';
import { ReloadlyOperator } from '../reloadly/reloadly.types';
import { CatalogOperatorRecord, InMemoryCatalogRepository } from '../store/repositories';
import { toMinor } from '../domain/pricing';

@Injectable()
export class CatalogService {
  private readonly logger = new Logger(CatalogService.name);
  constructor(
    private readonly reloadly: ReloadlyClient,
    private readonly repo: InMemoryCatalogRepository,
  ) {}

  private toRecord(op: ReloadlyOperator): CatalogOperatorRecord {
    const id = (op.id ?? op.operatorId) as number;
    return {
      operatorId: id,
      name: op.name,
      countryIso: op.country.isoName,
      denominationType: op.denominationType,
      localMinMinor: op.localMinAmount != null ? toMinor(op.localMinAmount) : null,
      localMaxMinor: op.localMaxAmount != null ? toMinor(op.localMaxAmount) : null,
      fixedLocalAmountsMajor: op.localFixedAmounts || [],
      supportsData: !!op.supportsDataPlans,
      logoUrl: op.logoUrls?.[0] || null,
    };
  }

  /** Pull a country's operators from Reloadly into the local catalog. */
  async syncCountry(countryIso: string): Promise<number> {
    const ops = await this.reloadly.listOperatorsByCountry(countryIso);
    for (const op of ops) await this.repo.upsertOperator(this.toRecord(op));
    this.logger.log(`Catalog sync ${countryIso}: ${ops.length} operators`);
    return ops.length;
  }

  /** Afghanistan first (our core market), then the diaspora's main destinations. */
  async syncCoreCountries(): Promise<Record<string, number>> {
    const core = ['AF', 'DE', 'PK', 'IR', 'TR', 'AE', 'US', 'GB'];
    const out: Record<string, number> = {};
    for (const iso of core) {
      try { out[iso] = await this.syncCountry(iso); }
      catch (e) { this.logger.warn(`Catalog sync failed for ${iso}: ${(e as Error).message}`); out[iso] = 0; }
    }
    return out;
  }

  listByCountry(iso: string) { return this.repo.listByCountry(iso); }
  getOperator(id: number) { return this.repo.getOperator(id); }
}
