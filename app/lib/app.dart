import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/flow_screens.dart';
import 'state/app_state.dart';

class TopupApp extends StatelessWidget {
  const TopupApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return MaterialApp(
      title: 'Mobile Credit',
      debugShowCheckedModeBanner: false,
      locale: Locale(app.lang),
      supportedLocales: const [Locale('ps'), Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 19),
          bodyMedium: TextStyle(fontSize: 17),
        ),
      ),
      home: app.languageChosen ? const HomeScreen() : const LanguageScreen(),
    );
  }
}
