import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { loadConfig } from './config/configuration';

async function bootstrap() {
  // rawBody: true is required to verify Stripe webhook signatures.
  const app = await NestFactory.create(AppModule, { rawBody: true });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  const cfg = loadConfig();
  await app.listen(cfg.port);
  // eslint-disable-next-line no-console
  console.log(`Topup backend listening on :${cfg.port} (Reloadly sandbox=${cfg.reloadly.sandbox}, charge currency ${cfg.chargeCurrency})`);
}
bootstrap();
