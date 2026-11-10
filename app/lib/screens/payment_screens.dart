import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/phone_input.dart';
import '../services/speech_composer.dart';
import '../state/app_state.dart';
import '../state/topup_flow.dart';
import '../widgets/widgets.dart';

String moneyText(int minor, String currency) =>
    '${(minor / 100).toStringAsFixed(2)} $currency';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _api = ApiClient();
  bool _connecting = true;
  bool _serverOffline = false;
  bool _paying = false;
  TopupCreated? _created;
  // One idempotency key per review visit: safe retries, no double charge.
  final String _idemKey =
      'app-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 30)}';

  @override
  void initState() {
    super.initState();
    // LOCAL-FIRST: the review renders instantly from the phone's own data.
    // The server call below only adds the exact total + enables payment.
    WidgetsBinding.instance.addPostFrameCallback((_) => _create());
  }

  Future<void> _create() async {
    final app = context.read<AppState>();
    final flow = context.read<TopupFlow>();
    setState(() {
      _connecting = true;
      _serverOffline = false;
    });
    try {
      final created = await _api.createTopup(
        recipientPhone: flow.e164!,
        operatorId: flow.operator!.operatorId,
        amountLocalMajor: flow.amountLocalMajor!,
        idempotencyKey: _idemKey,
      );
      flow.setCreated(created);
      if (!mounted) return;
      setState(() {
        _created = created;
        _connecting = false;
      });
      // Speak the whole review: amount, number read-back, total price.
      await app.voice.speakSequence(SpeechComposer.reviewSpeech(
        amountMajor: flow.amountLocalMajor!,
        localCurrency: created.localCurrency,
        e164: flow.e164!,
        totalMinor: created.totalMinor,
        chargeCurrency: created.chargeCurrency,
        lang: app.lang,
      ));
    } catch (_) {
      if (!mounted) return;
      // NOT a dead end: the review stays on screen, the payment state is
      // explained in words, and the user can retry or go back.
      setState(() {
        _connecting = false;
        _serverOffline = true;
      });
    }
  }

  Future<void> _pay() async {
    final app = context.read<AppState>();
    final created = _created;
    if (created == null) {
      // Payments are not live yet — say so plainly instead of an error.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(app.t('server_offline'), style: const TextStyle(fontSize: 17))),
      );
      await app.voice.speak('prompt_error');
      return;
    }
    if (AppConfig.stripePublishableKey.isEmpty || created.clientSecret == null) {
      // Honest dev state: without the Phase 0 Stripe keys the sheet cannot open.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stripe is not configured yet (Phase 0 keys missing)')),
      );
      return;
    }
    setState(() => _paying = true);
    try {
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: created.clientSecret!,
          merchantDisplayName: 'Mobile Credit',
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProcessingScreen(topupId: created.topupId)),
      );
    } on stripe.StripeException catch (_) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(app.t('error_generic'))),
      );
      await app.voice.speak('prompt_error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flow = context.watch<TopupFlow>();
    final created = _created;
    final opName = created?.operatorName ??
        (flow.operator!.name.isEmpty ? app.t('country_${flow.countryIso}') : flow.operator!.name);
    final currency = created?.localCurrency ?? flow.localCurrency;
    return StepScaffold(
      title: app.t('review_title'),
      promptKey: 'prompt_review',
      step: 4,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              children: [
                _row(context, Icons.phone_android, app.t('send_to'), groupForDisplay(flow.e164!)),
                _row(context, Icons.cell_tower, app.t('operator_label'), opName),
                _row(context, Icons.send_to_mobile, app.t('you_send'),
                    '${flow.amountLocalMajor} $currency'),
                if (created != null) ...[
                  const Divider(height: 32),
                  _row(context, Icons.payments, app.t('total_to_pay'),
                      moneyText(created.totalMinor, created.chargeCurrency), big: true),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_connecting)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(app.t('connecting'), style: const TextStyle(fontSize: 17))),
                ],
              ),
            ),
          if (_serverOffline)
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_off, color: AppColors.muted, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(app.t('server_offline'), style: const TextStyle(fontSize: 17))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.refresh),
                    label: Text(app.t('try_again'), style: const TextStyle(fontSize: 17)),
                  ),
                ],
              ),
            ),
          const Spacer(),
          BigButton(
            icon: Icons.lock,
            label: app.t('pay_now'),
            onPressed: _paying ? null : _pay,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, String value, {bool big = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: big ? 34 : 28, color: AppColors.blue),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: big ? 22 : 19)),
          const Spacer(),
          Text(value,
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: big ? 26 : 21, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// After the card payment, the backend webhook drives delivery.
/// This screen polls the transaction until it settles.
class ProcessingScreen extends StatefulWidget {
  final String topupId;
  const ProcessingScreen({super.key, required this.topupId});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().voice.speak('prompt_processing');
      _poll();
    });
  }

  Future<void> _poll() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      TopupHistoryItem? item;
      try {
        item = await _api.getTopup(widget.topupId);
      } catch (_) {
        item = null;
      }
      if (!mounted) return;
      final s = item?.status;
      if (s == 'DELIVERED') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultScreen(success: true)),
        );
        return;
      }
      if (s == 'REFUNDED' || s == 'REFUND_FAILED' || s == 'PAYMENT_FAILED' || s == 'FAILED') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResultScreen(success: false)),
        );
        return;
      }
    }
    // Still processing after ~90s: the money is safe (state machine holds it);
    // send the user home — the result will show in History.
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 5, color: AppColors.blue),
              const SizedBox(height: 24),
              Text(app.t('processing'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final bool success;
  const ResultScreen({super.key, required this.success});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      app.voice.speak(success ? 'prompt_success' : 'prompt_failed_refund');
    });
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(success ? Icons.check_circle : Icons.cancel,
                    size: 120, color: success ? Colors.green : Colors.red),
              const SizedBox(height: 20),
              Text(success ? app.t('success_title') : app.t('failed_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              if (!success) ...[
                const SizedBox(height: 12),
                Text(app.t('failed_refund'),
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
              ],
              const SizedBox(height: 44),
                BigButton(
                  icon: Icons.home,
                  label: app.t('done_btn'),
                  onPressed: () {
                    context.read<TopupFlow>().reset();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _statusKey(String status) {
    switch (status) {
      case 'DELIVERED':
        return 'status_delivered';
      case 'REFUNDED':
        return 'status_refunded';
      case 'SENDING':
      case 'PAID':
        return 'status_sending';
      case 'PAYMENT_FAILED':
      case 'FAILED':
      case 'REFUND_FAILED':
        return 'status_failed';
      default:
        return 'status_pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return StepScaffold(
      title: app.t('history'),
      promptKey: 'prompt_history',
      body: FutureBuilder<List<TopupHistoryItem>>(
        future: ApiClient().myTopups(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(app.t('error_generic'), style: const TextStyle(fontSize: 20)));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(app.t('empty_history'),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 21)),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = items[i];
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    it.status == 'DELIVERED' ? Icons.check_circle : Icons.info,
                    color: it.status == 'DELIVERED' ? Colors.green : Colors.orange,
                    size: 34,
                  ),
                  title: Text(groupForDisplay(it.recipientPhone),
                      textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${it.operatorName} • ${(it.amountLocalMinor / 100).toStringAsFixed(0)} ${it.localCurrency} • ${moneyText(it.totalMinor, it.chargeCurrency)}'),
                  trailing: Text(app.t(_statusKey(it.status)), style: const TextStyle(fontSize: 16)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
