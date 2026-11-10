import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Wizard state for one top-up, carried across the step screens.
class TopupFlow extends ChangeNotifier {
  String? countryIso;
  String? e164;
  OperatorInfo? operator;
  int? amountLocalMajor;
  String localCurrency = 'AFN';
  TopupCreated? created;

  void setCountry(String iso) {
    countryIso = iso;
    notifyListeners();
  }

  void setNumber(String phone, OperatorInfo op) {
    e164 = phone;
    operator = op;
    notifyListeners();
  }

  void setAmount(int major, String currency) {
    amountLocalMajor = major;
    localCurrency = currency;
    notifyListeners();
  }

  void setCreated(TopupCreated c) {
    created = c;
    notifyListeners();
  }

  void reset() {
    countryIso = null;
    e164 = null;
    operator = null;
    amountLocalMajor = null;
    created = null;
    notifyListeners();
  }
}
