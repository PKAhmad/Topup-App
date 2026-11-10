class OperatorInfo {
  final int operatorId;
  final String name;
  final String countryIso;
  final String denominationType; // FIXED | RANGE
  final int? localMinMinor;
  final int? localMaxMinor;
  final List<int> fixedLocalAmountsMajor;
  final String? logoUrl;

  const OperatorInfo({
    required this.operatorId,
    required this.name,
    required this.countryIso,
    required this.denominationType,
    this.localMinMinor,
    this.localMaxMinor,
    this.fixedLocalAmountsMajor = const [],
    this.logoUrl,
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> j) => OperatorInfo(
        operatorId: j['operatorId'] as int,
        name: j['name'] as String,
        countryIso: j['countryIso'] as String,
        denominationType: j['denominationType'] as String,
        localMinMinor: j['localMinMinor'] as int?,
        localMaxMinor: j['localMaxMinor'] as int?,
        fixedLocalAmountsMajor:
            ((j['fixedLocalAmountsMajor'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
        logoUrl: j['logoUrl'] as String?,
      );

  bool get isFixed => denominationType == 'FIXED';

  /// Preset amounts for the big-chip screen (RANGE operators).
  List<int> presetAmountsMajor(String currencyIso) {
    const presets = [50, 100, 200, 300, 500, 1000, 2000];
    final min = (localMinMinor ?? 0) ~/ 100;
    final max = (localMaxMinor ?? 1 << 30) ~/ 100;
    return presets.where((a) => a >= min && a <= max).toList();
  }
}

class TopupCreated {
  final String topupId;
  final String status;
  final String? clientSecret;
  final String operatorName;
  final int amountLocalMinor;
  final String localCurrency;
  final int totalMinor;
  final int feeMinor;
  final String chargeCurrency;

  const TopupCreated({
    required this.topupId,
    required this.status,
    required this.clientSecret,
    required this.operatorName,
    required this.amountLocalMinor,
    required this.localCurrency,
    required this.totalMinor,
    required this.feeMinor,
    required this.chargeCurrency,
  });

  factory TopupCreated.fromJson(Map<String, dynamic> j) => TopupCreated(
        topupId: j['topupId'] as String,
        status: j['status'] as String,
        clientSecret: j['clientSecret'] as String?,
        operatorName: j['operatorName'] as String,
        amountLocalMinor: j['amountLocalMinor'] as int,
        localCurrency: j['localCurrency'] as String,
        totalMinor: j['totalMinor'] as int,
        feeMinor: j['feeMinor'] as int,
        chargeCurrency: j['chargeCurrency'] as String,
      );
}

class TopupHistoryItem {
  final String id;
  final String recipientPhone;
  final String operatorName;
  final int amountLocalMinor;
  final String localCurrency;
  final int totalMinor;
  final String chargeCurrency;
  final String status;
  final String createdAt;

  const TopupHistoryItem({
    required this.id,
    required this.recipientPhone,
    required this.operatorName,
    required this.amountLocalMinor,
    required this.localCurrency,
    required this.totalMinor,
    required this.chargeCurrency,
    required this.status,
    required this.createdAt,
  });

  factory TopupHistoryItem.fromJson(Map<String, dynamic> j) => TopupHistoryItem(
        id: j['id'] as String,
        recipientPhone: j['recipientPhone'] as String,
        operatorName: j['operatorName'] as String,
        amountLocalMinor: j['amountLocalMinor'] as int,
        localCurrency: (j['localCurrency'] ?? '') as String,
        totalMinor: j['totalMinor'] as int,
        chargeCurrency: j['chargeCurrency'] as String,
        status: j['status'] as String,
        createdAt: j['createdAt'] as String,
      );
}
