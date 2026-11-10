import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { AuthGuard } from '../auth/auth.guard';
import { CatalogService } from './catalog.service';
import { ReloadlyClient } from '../reloadly/reloadly.client';

@Controller('catalog')
@UseGuards(AuthGuard)
export class CatalogController {
  constructor(
    private readonly catalog: CatalogService,
    private readonly reloadly: ReloadlyClient,
  ) {}

  @Get('countries/:iso/operators')
  operators(@Param('iso') iso: string) { return this.catalog.listByCountry(iso.toUpperCase()); }

  @Post('sync/:iso')
  async sync(@Param('iso') iso: string) {
    const count = await this.catalog.syncCountry(iso.toUpperCase());
    return { country: iso.toUpperCase(), operators: count };
  }

  @Post('sync-core')
  syncCore() { return this.catalog.syncCoreCountries(); }

  /** Ops check: our prepaid float at Reloadly — topups fail when this hits zero. */
  @Get('balance')
  balance() { return this.reloadly.getBalance(); }
}
