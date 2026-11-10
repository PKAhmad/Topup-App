import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
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
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6ED3FF), AppColors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 14, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.phone_android, size: 48, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Mobile Credit',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.ink)),
                const SizedBox(height: 36),
                for (final lang in Strings.languages) ...[
                  GlassCard(
                    selected: app.lang == lang,
                    onTap: () async {
                      await app.setLanguage(lang);
                      await app.voice.speak('prompt_welcome');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.volume_up, size: 28, color: AppColors.blue),
                        const SizedBox(width: 12),
                        Text(Strings.languageNames[lang]!,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      ],
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
          // Hero card — the modern top-up app front door.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [AppColors.blueLight, AppColors.blue],
            begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.blue.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      child: const Icon(Icons.send_to_mobile, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(app.t('tagline'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(app.t('choose_country'),
                    style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final iso in CountryDial.starterCountries)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(99),
                            onTap: () {
                              flow.reset();
                              flow.setCountry(iso);
                              Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => const NumberScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(CountryDial.flagByIso[iso] ?? '🏳️',
                                      style: const TextStyle(fontSize: 19)),
                                  const SizedBox(width: 6),
                                  Text(app.t('country_$iso'),
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
            color: AppColors.muted,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          const Spacer(),
          GlassCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(app.t('voice_guidance'), style: const TextStyle(fontSize: 19)),
                  secondary: const Icon(Icons.volume_up, size: 30, color: AppColors.blue),
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
        ],
      ),
    );
  }
}

class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flow = context.read<TopupFlow>();
    final q = _query.trim().toLowerCase();
    final countries = CountryDial.starterCountries.where((iso) {
      if (q.isEmpty) return true;
      return app.t('country_$iso').toLowerCase().contains(q) ||
          iso.toLowerCase().contains(q) ||
          (CountryDial.dialByIso[iso] ?? '').contains(q);
    }).toList();
    return StepScaffold(
      title: app.t('choose_country'),
      promptKey: 'prompt_choose_country',
      step: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 19),
            decoration: InputDecoration(
              hintText: app.t('search_country'),
              prefixIcon: const Icon(Icons.search, color: AppColors.blue),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.85),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.blue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: countries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final iso = countries[i];
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap: () {
                    flow.setCountry(iso);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NumberScreen()));
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
                        ),
                        alignment: Alignment.center,
                        child: Text(CountryDial.flagByIso[iso] ?? '🏳️',
                            style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(app.t('country_$iso'),
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                      ),
                      Text('+${CountryDial.dialByIso[iso]}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 16, color: AppColors.muted)),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                );
              },
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
  bool _confirming = false;
  String? _error;
  OperatorInfo? _previewOp;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Live, offline preview while typing: country + operator from the number
  /// itself. No network, no waiting.
  void _updatePreview(String raw) {
    final flow = context.read<TopupFlow>();
    OperatorInfo? op;
    try {
      final e164 = buildE164(flow.countryIso!, raw);
      if (isPlausibleE164(e164)) op = localOperatorHint(e164);
    } catch (_) {
      op = null;
    }
    if (op != _previewOp) setState(() => _previewOp = op);
  }

  /// INSTANT detection: the country comes from the dial code and the operator
  /// from the number prefix — both computed on the phone. The user goes
  /// straight to the read-back; the backend confirmation (5 s leash) only
  /// refines the operator in the background and never blocks this screen.
  void _detect() {
    final app = context.read<AppState>();
    final flow = context.read<TopupFlow>();
    try {
      final e164 = buildE164(flow.countryIso!, _controller.text);
      if (!isPlausibleE164(e164)) throw const FormatException('implausible');
      final local = localOperatorHint(e164);
      if (local == null) throw const FormatException('unknown country');
      flow.setNumber(e164, local);
      setState(() {
        _confirming = true;
        _error = null;
      });
      // THE safety step: read the number back, digit by digit.
      app.voice.speakSequence(SpeechComposer.phoneReadback(e164));
      _confirmInBackground(e164);
    } catch (_) {
      setState(() => _error = app.t('invalid_number'));
      app.voice.speak('prompt_invalid_number');
    }
  }

  Future<void> _confirmInBackground(String e164) async {
    try {
      final remote = await _api.detectOperator(e164);
      if (!mounted) return;
      final flow = context.read<TopupFlow>();
      if (flow.e164 == e164) {
        flow.setNumber(e164, remote);
        setState(() {});
      }
    } catch (_) {
      // Backend unreachable or slow: the local detection stands.
    }
  }

  String _operatorLine(AppState app, OperatorInfo op) =>
      op.name.isEmpty ? app.t('operator_auto') : '${app.t('operator_label')}: ${op.name}';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final flow = context.watch<TopupFlow>();
    final selectedIso = flow.countryIso!;
    if (_confirming && flow.e164 != null) {
      final iso = flow.countryIso!; // follows the number, not the tap
      return StepScaffold(
        title: app.t('confirm_q'),
        promptKey: 'prompt_confirm_number',
        step: 2,
        autoSpeak: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  Text('${CountryDial.flagByIso[iso]} ${app.t('country_$iso')}',
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  Text(groupForDisplay(flow.e164!),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text(_operatorLine(app, flow.operator!),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.blue)),
                ],
              ),
            ),
            const Spacer(),
            BigButton(
              icon: Icons.check_circle,
              label: app.t('yes_correct'),
              color: Colors.green.shade600,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AmountScreen()),
              ),
            ),
            const SizedBox(height: 14),
            BigButton(
              icon: Icons.cancel,
              label: app.t('no_change'),
              color: Colors.red.shade600,
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
      step: 2,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${CountryDial.flagByIso[selectedIso]} ${app.t('country_$selectedIso')}  (+${CountryDial.dialByIso[selectedIso]})',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onChanged: _updatePreview,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: app.t('number_example'),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.85),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.22)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.blue, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
          ),
          if (_previewOp != null) ...[
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(CountryDial.flagByIso[_previewOp!.countryIso] ?? '🏳️',
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '${app.t('country_${_previewOp!.countryIso}')} • ${_operatorLine(app, _previewOp!)}',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 19)),
          ],
          const Spacer(),
          BigButton(
            icon: Icons.arrow_forward,
            label: app.t('continue_btn'),
            onPressed: _detect,
          ),
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
      step: 3,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.blueLight, AppColors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (op.name.isEmpty ? app.t('country_${flow.countryIso}') : op.name)
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(op.name.isEmpty ? app.t('country_${flow.countryIso}') : op.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(groupForDisplay(flow.e164!),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 16, color: AppColors.muted)),
                    ],
                  ),
                ),
                Text(CountryDial.flagByIso[flow.countryIso!] ?? '🏳️', style: const TextStyle(fontSize: 30)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.6,
              children: [
                for (final a in amounts)
                  GlassCard(
                    selected: _selected == a,
                    onTap: () => _pick(a),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (amounts.length > 2 && a == amounts[2])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [AppColors.blueLight, AppColors.blue]),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(app.t('popular'),
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          Text('$a',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: _selected == a ? AppColors.blue : AppColors.ink)),
                          Text(currency,
                              style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!op.isFixed) ...[
            GlassCard(
              padding: const EdgeInsets.all(10),
              child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: app.t('other_amount'),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.85),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.22)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.blue, width: 2),
                      ),
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
