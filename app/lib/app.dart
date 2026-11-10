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
        // Expense Tracker palette: neon blue on warm cream, ink-navy text.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0091FF),
          surface: const Color(0xFFFAF5EA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F0E2),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 19, color: Color(0xFF182740)),
          bodyMedium: TextStyle(fontSize: 17, color: Color(0xFF182740)),
        ),
      ),
      home: app.languageChosen ? const HomeScreen() : const LanguageScreen(),
    );
  }
}
