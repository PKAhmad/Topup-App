import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../services/api_client.dart';
import '../services/phone_input.dart';
import '../services/speech_composer.dart';
import '../state/app_state.dart';
import '../state/topup_flow.dart';
import '../widgets/widgets.dart';
import 'payment_screens.dart';

const Map<String, String> currencyByIso = {
  'AF': 'AFN', 'PK': 'PKR', 'IR': 'IRR', 'DE': 'EUR', 'TR': 'TRY',
  'AE': 'AED', 'SA': 'SAR', 'US': 'USD', 'GB': 'GBP', 'FR': 'EUR',
  'NL': 'EUR', 'SE': 'SEK',
};

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.phone_android, size: 72, color: Colors.green),
              const SizedBox(height: 12),
              const Text('Mobile Credit',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 36),
              for (final lang in Strings.languages) ...[
                SizedBox(
                  height: 72,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await app.setLanguage(lang);
                      await app.voice.speak('prompt_welcome');
                    },
                    icon: const Icon(Icons.volume_up, size: 28),
                    label: Text(Strings.languageNames[lang]!,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: app.lang == lang ? Colors.green : Colors.grey, width: app.lang == lang ? 3 : 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 10),
              BigButton(
                icon: Icons.arrow_forward,
                label: app.t('continue_btn'),
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flow = context.read<TopupFlow>();
    return StepScaffold(
      title: app.t('app_name'),
      promptKey: 'prompt_welcome',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(app.t('tagline'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 36),
          BigButton(
            icon: Icons.send_to_mobile,
            label: app.t('new_topup'),
            onPressed: () {
              flow.reset();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CountryScreen()));
            },
          ),
          const SizedBox(height: 16),
          BigButton(
            icon: Icons.history,
            label: app.t('history'),
            color: Colors.blueGrey,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          const Spacer(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(app.t('voice_guidance'), style: const TextStyle(fontSize: 19)),
                    secondary: const Icon(Icons.volume_up, size: 30),
                    value: app.voiceEnabled,
                    onChanged: (v) => app.setVoiceEnabled(v),
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final lang in Strings.languages)
                        ChoiceChip(
                          label: Text(Strings.languageNames[lang]!, style: const TextStyle(fontSize: 18)),
                          selected: app.lang == lang,
                          onSelected: (_) => app.setLanguage(lang),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CountryScreen extends StatelessWidget {
  const CountryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flow = context.read<TopupFlow>();
    return StepScaffold(
      title: app.t('choose_country'),
      promptKey: 'prompt_choose_country',
      body: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.25,
        children: [
          for (final iso in CountryDial.starterCountries)
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                flow.setCountry(iso);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NumberScreen()));
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(CountryDial.flagByIso[iso] ?? '🏳️', style: const TextStyle(fontSize: 46)),
                    const SizedBox(height: 6),
                    Text(app.t('country_$iso'),
                        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NumberScreen extends StatefulWidget {
  const NumberScreen({super.key});

  @override
  State<NumberScreen> createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen> {
  final _controller = TextEditingController();
  final _api = ApiClient();
  bool _busy = false;
  bool _confirming = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    final app = context.read<AppState>();
    final flow = context.read<TopupFlow>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final e164 = buildE164(flow.countryIso!, _controller.text);
      if (!isPlausibleE164(e164)) throw const FormatException('implausible');
      final op = await _api.detectOperator(e164);
      flow.setNumber(e164, op);
      setState(() => _confirming = true);
      // THE safety step: read the number back, digit by digit.
      await app.voice.speakSequence(SpeechComposer.phoneReadback(e164));
    } catch (_) {
      setState(() => _error = app.t('invalid_number'));
      await app.voice.speak('prompt_invalid_number');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flow = context.watch<TopupFlow>();
    final iso = flow.countryIso!;
    if (_confirming && flow.e164 != null) {
      return StepScaffold(
        title: app.t('confirm_q'),
        promptKey: 'prompt_confirm_number',
        autoSpeak: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text('${CountryDial.flagByIso[iso]} ${app.t('country_$iso')}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text(groupForDisplay(flow.e164!),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('${app.t('operator_label')}: ${flow.operator!.name}',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
            const Spacer(),
            BigButton(
              icon: Icons.check_circle,
              label: app.t('yes_correct'),
              color: Colors.green.shade700,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AmountScreen()),
              ),
            ),
            const SizedBox(height: 14),
            BigButton(
              icon: Icons.cancel,
              label: app.t('no_change'),
              color: Colors.red.shade700,
              onPressed: () {
                setState(() => _confirming = false);
                app.voice.speak('prompt_enter_number');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }
    return StepScaffold(
      title: app.t('enter_number'),
      promptKey: 'prompt_enter_number',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${CountryDial.flagByIso[iso]} ${app.t('country_$iso')}  (+${CountryDial.dialByIso[iso]})',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: app.t('number_example'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 19)),
          ],
          const Spacer(),
          BigButton(
            icon: Icons.search,
            label: app.t('operator_label'),
            onPressed: _busy ? null : _detect,
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 12),
              Text(app.t('detecting'), style: const TextStyle(fontSize: 18)),
            ]),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class AmountScreen extends StatefulWidget {
  const AmountScreen({super.key});

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final _customController = TextEditingController();
  int? _selected;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _pick(int amount) {
    final app = context.read<AppState>();
    final flow = context.read<TopupFlow>();
    setState(() => _selected = amount);
    flow.setAmount(amount, currencyByIso[flow.countryIso] ?? 'AFN');
    app.voice.speakSequence(
      SpeechComposer.amountEcho(amount, flow.localCurrency, app.lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flow = context.watch<TopupFlow>();
    final op = flow.operator!;
    final currency = currencyByIso[flow.countryIso] ?? '';
    final amounts = op.isFixed && op.fixedLocalAmountsMajor.isNotEmpty
        ? op.fixedLocalAmountsMajor
        : op.presetAmountsMajor(flow.countryIso!);
    return StepScaffold(
      title: app.t('choose_amount'),
      promptKey: 'prompt_choose_amount',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${op.name} • ${groupForDisplay(flow.e164!)}',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.6,
              children: [
                for (final a in amounts)
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _pick(a),
                    child: Card(
                      color: _selected == a ? Colors.green.shade600 : null,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Center(
                        child: Text('$a $currency',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _selected == a ? Colors.white : null)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!op.isFixed) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: app.t('other_amount'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  iconSize: 30,
                  onPressed: () {
                    final v = int.tryParse(_customController.text);
                    if (v != null && v > 0) _pick(v);
                  },
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomBar: BigButton(
        icon: Icons.arrow_forward,
        label: app.t('continue_btn'),
        onPressed: _selected == null
            ? null
            : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReviewScreen()),
                ),
      ),
    );
  }
}
