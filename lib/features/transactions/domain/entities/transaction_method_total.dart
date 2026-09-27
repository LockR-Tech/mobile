class TransactionMethodTotal {
  final String period;
  final String selectedMethod;
  final double totalAmount;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;
  final Map<String, double> summary;
  final List<MethodTotalItem> methods;

  const TransactionMethodTotal({
    required this.period,
    required this.selectedMethod,
    required this.totalAmount,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
    required this.summary,
    required this.methods,
  });

  factory TransactionMethodTotal.empty([String period = 'ALL', String method = 'ALL']) {
    return TransactionMethodTotal(
      period: period,
      selectedMethod: method,
      totalAmount: 0.0,
      totalExpense: 0.0,
      totalIncome: 0.0,
      transactionCount: 0,
      summary: const {
        'WALLET': 0.0,
        'SEPAY': 0.0,
        'VNPAY': 0.0,
        'MOMO': 0.0,
        'WITHDRAW': 0.0,
      },
      methods: const [],
    );
  }

  factory TransactionMethodTotal.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final summaryMap = <String, double>{};
    if (json['summary'] is Map) {
      (json['summary'] as Map).forEach((k, v) {
        summaryMap[k.toString()] = parseDouble(v);
      });
    }

    final methodsList = <MethodTotalItem>[];
    if (json['methods'] is List) {
      for (final item in json['methods']) {
        if (item is Map<String, dynamic>) {
          methodsList.add(MethodTotalItem.fromJson(item));
        }
      }
    }

    return TransactionMethodTotal(
      period: json['period']?.toString() ?? 'ALL',
      selectedMethod: json['selectedMethod']?.toString() ?? 'ALL',
      totalAmount: parseDouble(json['totalAmount']),
      totalExpense: parseDouble(json['totalExpense']),
      totalIncome: parseDouble(json['totalIncome']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
      summary: summaryMap,
      methods: methodsList,
    );
  }
}

class MethodTotalItem {
  final String method;
  final String label;
  final double totalAmount;
  final double totalExpense;
  final double totalIncome;
  final int transactionCount;

  const MethodTotalItem({
    required this.method,
    required this.label,
    required this.totalAmount,
    required this.totalExpense,
    required this.totalIncome,
    required this.transactionCount,
  });

  factory MethodTotalItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return MethodTotalItem(
      method: json['method']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      totalAmount: parseDouble(json['totalAmount']),
      totalExpense: parseDouble(json['totalExpense']),
      totalIncome: parseDouble(json['totalIncome']),
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }
}
