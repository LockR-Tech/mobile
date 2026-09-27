class SpendingStats {
  final String period;
  final double totalExpense;
  final double totalIncome;
  final double netChange;
  final int transactionCount;
  final Map<String, double> byService;
  final Map<String, double> byMethod;

  const SpendingStats({
    required this.period,
    required this.totalExpense,
    required this.totalIncome,
    required this.netChange,
    required this.transactionCount,
    required this.byService,
    required this.byMethod,
  });

  factory SpendingStats.empty([String period = 'ALL']) {
    return SpendingStats(
      period: period,
      totalExpense: 0,
      totalIncome: 0,
      netChange: 0,
      transactionCount: 0,
      byService: {
        'RENTAL': 0,
        'SEND': 0,
        'TOPUP': 0,
        'WITHDRAW': 0,
        'OTHER': 0,
      },
      byMethod: {
        'WALLET': 0,
        'SEPAY': 0,
        'VNPAY': 0,
        'MOMO': 0,
        'WITHDRAW': 0,
      },
    );
  }

  factory SpendingStats.fromJson(Map<String, dynamic> json) {
    Map<String, double> parseMap(dynamic mapData) {
      if (mapData is! Map) return {};
      final result = <String, double>{};
      mapData.forEach((k, v) {
        if (v is num) {
          result[k.toString()] = v.toDouble();
        } else if (v is String) {
          result[k.toString()] = double.tryParse(v) ?? 0.0;
        }
      });
      return result;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return SpendingStats(
      period: json['period'] as String? ?? 'ALL',
      totalExpense: parseDouble(json['totalExpense']),
      totalIncome: parseDouble(json['totalIncome']),
      netChange: parseDouble(json['netChange']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      byService: parseMap(json['byService']),
      byMethod: parseMap(json['byMethod']),
    );
  }
}
