import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';
import 'app.dart';
import 'config.dart';
import 'state/app_state.dart';
import 'state/topup_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  await appState.load();
  if (AppConfig.stripePublishableKey.isNotEmpty) {
    stripe.Stripe.publishableKey = AppConfig.stripePublishableKey;
    await stripe.Stripe.instance.applySettings();
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider(create: (_) => TopupFlow()),
      ],
      child: const TopupApp(),
    ),
  );
}
