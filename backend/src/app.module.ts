import { Module } from '@nestjs/common';
import { loadConfig } from './config/configuration';
import { LedgerService } from './ledger/ledger.service';
import { ReloadlyClient } from './reloadly/reloadly.client';
import { StripePaymentsProvider } from './payments/payments.provider';
import { InMemoryCatalogRepository, InMemoryTopupRepository } from './store/repositories';
import { CatalogService } from './catalog/catalog.service';
import { CatalogController } from './catalog/catalog.controller';
import { TopupsService } from './topups/topups.service';
import { StripeWebhookController, TopupsController } from './topups/topups.controller';

const cfg = loadConfig();

@Module({
  controllers: [TopupsController, StripeWebhookController, CatalogController],
  providers: [
    { provide: 'APP_CONFIG', useValue: cfg },
    LedgerService,
    InMemoryCatalogRepository,
    { provide: 'TOPUP_REPO', useClass: InMemoryTopupRepository },
    { provide: ReloadlyClient, useFactory: () => new ReloadlyClient(cfg.reloadly) },
    { provide: 'RELOADLY', useFactory: (c: ReloadlyClient) => c, inject: [ReloadlyClient] },
    { provide: 'PAYMENTS', useFactory: () => new StripePaymentsProvider(cfg.stripe) },
    CatalogService,
    TopupsService,
  ],
})
export class AppModule {}
