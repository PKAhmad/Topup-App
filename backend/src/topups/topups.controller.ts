import { Body, Controller, Get, Headers, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { IsNumber, IsOptional, IsPositive, IsString, MinLength } from 'class-validator';
import { AuthGuard } from '../auth/auth.guard';
import { TopupsService } from './topups.service';
import { PaymentsProvider } from '../payments/payments.provider';
import { Inject } from '@nestjs/common';

export class CreateTopupDto {
  @IsString() recipientPhone: string;
  @IsOptional() @IsNumber() operatorId?: number;
  @IsNumber() @IsPositive() amountLocalMajor: number;
  @IsString() @MinLength(8) idempotencyKey: string;
}

@Controller('topups')
@UseGuards(AuthGuard)
export class TopupsController {
  constructor(private readonly topups: TopupsService) {}

  @Post()
  async create(@Req() req: any, @Body() dto: CreateTopupDto) {
    const result = await this.topups.createTopup({ userId: req.userId, ...dto });
    return {
      topupId: result.topup.id,
      status: result.topup.status,
      clientSecret: result.clientSecret,
      reused: result.reused,
      recipientPhone: result.topup.recipientPhone,
      operatorName: result.topup.operatorName,
      amountLocalMinor: result.topup.amountLocalMinor,
      localCurrency: result.topup.localCurrency,
      totalMinor: result.topup.totalMinor,
      feeMinor: result.topup.feeMinor,
      chargeCurrency: result.topup.chargeCurrency,
    };
  }

  // Declared before ':id' so 'detect-operator' is not captured as an id.
  @Get('detect-operator')
  detect(@Query('phone') phone: string) { return this.topups.detectOperator(phone); }

  @Get('mine')
  listMine(@Req() req: any) { return this.topups.listUserTopups(req.userId); }

  @Get(':id')
  getOne(@Param('id') id: string) { return this.topups.getTopup(id); }
}

@Controller('webhooks')
export class StripeWebhookController {
  constructor(
    private readonly topups: TopupsService,
    @Inject('PAYMENTS') private readonly payments: PaymentsProvider,
  ) {}

  // Signature-verified Stripe webhook. Raw body is required for verification
  // (main.ts boots Nest with rawBody: true).
  @Post('stripe')
  async stripe(@Req() req: any, @Headers('stripe-signature') signature: string) {
    const event = this.payments.verifyWebhook(req.rawBody, signature);
    if (!event.paymentIntentId) return { received: true };
    if (event.type === 'payment_intent.succeeded') {
      await this.topups.handlePaymentSucceeded(event.paymentIntentId);
    } else if (event.type === 'payment_intent.payment_failed') {
      await this.topups.handlePaymentFailed(event.paymentIntentId);
    }
    return { received: true };
  }
}
