import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.dart';
import '../services/voice_service.dart';

/// App-wide settings: language + voice on/off, persisted on the device.
class AppState extends ChangeNotifier {
  final VoiceService voice = VoiceService();
  String lang = 'ps';
  bool voiceEnabled = true;
  bool languageChosen = false;

  String t(String key) => Strings.t(lang, key);
  bool get isRtl => lang == 'ps' || lang == 'fa';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? 'ps';
    voiceEnabled = prefs.getBool('voice') ?? true;
    languageChosen = prefs.getBool('languageChosen') ?? false;
    voice.lang = lang;
    voice.enabled = voiceEnabled;
    notifyListeners();
  }

  Future<void> setLanguage(String newLang, {bool chosen = true}) async {
    lang = newLang;
    languageChosen = chosen;
    voice.lang = newLang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', newLang);
    await prefs.setBool('languageChosen', chosen);
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool on) async {
    voiceEnabled = on;
    voice.enabled = on;
    if (!on) await voice.stop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voice', on);
    notifyListeners();
  }
}
