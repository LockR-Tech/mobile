import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

/// Kết quả kiểm tra thời tiết của server (`DroneWeatherAssessment`): cùng một
/// nguồn với bước chặn đặt đơn / phóng drone, nên khách, KTV và admin thấy như nhau.
class DroneWeather {
  const DroneWeather({
    required this.status,
    required this.message,
    this.checkedAt,
    this.maxWindKmh = 0,
    this.maxGustKmh = 0,
    this.maxPrecipitationMm = 0,
    this.provider,
    this.temperatureC,
    this.condition,
  });

  /// SAFE | UNSAFE | UNAVAILABLE.
  final String status;
  final String message;
  final DateTime? checkedAt;
  final double maxWindKmh;
  final double maxGustKmh;
  final double maxPrecipitationMm;
  final String? provider;
  final double? temperatureC;
  final String? condition;

  bool get safe => status == 'SAFE';
  bool get unavailable => status == 'UNAVAILABLE';

  String? get providerLabel => switch (provider) {
    'OPEN_METEO' => 'Open-Meteo',
    'MET_NORWAY' => 'MET Norway',
    _ => null,
  };

  static DroneWeather? fromJson(Object? raw) {
    if (raw is! Map) return null;
    double num0(Object? v) =>
        v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final temp = raw['temperatureC'];
    final condition = raw['condition']?.toString();
    return DroneWeather(
      status: '${raw['status'] ?? 'UNAVAILABLE'}'.toUpperCase(),
      message: '${raw['message'] ?? 'Không thể xác nhận thời tiết tuyến bay.'}',
      checkedAt: DateTime.tryParse('${raw['checkedAt'] ?? ''}'),
      maxWindKmh: num0(raw['maxWindSpeedKmh']),
      maxGustKmh: num0(raw['maxWindGustKmh']),
      maxPrecipitationMm: num0(raw['maxPrecipitationMm']),
      provider: raw['provider']?.toString(),
      temperatureC: temp is num ? temp.toDouble() : double.tryParse('$temp'),
      condition: condition == null || condition.isEmpty || condition == 'null'
          ? null
          : condition,
    );
  }
}

typedef DroneRouteWeatherLoader =
    Future<Map<String, dynamic>> Function(int orderId);
typedef DroneLockerWeatherLoader =
    Future<List<Map<String, dynamic>>> Function();

/// Một dòng tóm tắt thời tiết (dùng trong thẻ tuyến bay và danh sách tủ).
class DroneWeatherSummary extends StatelessWidget {
  const DroneWeatherSummary({super.key, required this.weather, this.title});

  final DroneWeather weather;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final (Color tone, Color bg, IconData icon, String label) = weather.safe
        ? (
            const Color(0xFF15803D),
            const Color(0xFFF0FDF4),
            Icons.wb_sunny_outlined,
            'Bay được',
          )
        : weather.unavailable
        ? (
            const Color(0xFF64748B),
            const Color(0xFFF1F5F9),
            Icons.cloud_off_outlined,
            'Chưa có dự báo',
          )
        : (
            const Color(0xFFB91C1C),
            const Color(0xFFFEF2F2),
            Icons.thunderstorm_outlined,
            'Không an toàn để bay',
          );
    final facts = <String>[
      if (weather.condition != null) weather.condition!,
      if (weather.temperatureC != null)
        '${weather.temperatureC!.toStringAsFixed(0)}°C',
      if (!weather.unavailable) ...[
        'Gió ${weather.maxWindKmh.toStringAsFixed(0)} km/h',
        'Giật ${weather.maxGustKmh.toStringAsFixed(0)} km/h',
        'Mưa ${weather.maxPrecipitationMm.toStringAsFixed(1)} mm',
      ],
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: tone, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                Text(
                  label,
                  style: TextStyle(color: tone, fontWeight: FontWeight.w800),
                ),
                if (facts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      facts.join(' · '),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                if (!weather.safe)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      weather.message,
                      style: TextStyle(fontSize: 12, color: tone),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [
                      'Dự báo 30 phút tới',
                      if (weather.checkedAt != null)
                        'cập nhật ${formatDateTimeVn(weather.checkedAt!.toLocal())}',
                      if (weather.providerLabel != null)
                        'nguồn ${weather.providerLabel}',
                    ].join(' · '),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thời tiết dọc tuyến bay của một đơn: tủ bay → tủ nhận. Khách và KTV dùng chung.
class DroneRouteWeatherCard extends StatefulWidget {
  const DroneRouteWeatherCard({
    super.key,
    required this.orderId,
    this.asTechnician = false,
    this.load,
    this.refreshKey,
  });

  final int orderId;
  final bool asTechnician;
  final DroneRouteWeatherLoader? load;

  /// Đổi giá trị (vd. chặng đơn) ⇒ tải lại.
  final Object? refreshKey;

  @override
  State<DroneRouteWeatherCard> createState() => _DroneRouteWeatherCardState();
}

class _DroneRouteWeatherCardState extends State<DroneRouteWeatherCard> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant DroneRouteWeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.orderId != widget.orderId) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader =
          widget.load ??
          (id) => LockerOpsService().droneRouteWeather(
            id,
            asTechnician: widget.asTechnician,
          );
      final data = await loader(widget.orderId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = LockerOpsService.errorMessage(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final weather = DroneWeather.fromJson(_data?['weather']);
    if (!_loading && _error == null && weather == null) {
      return const SizedBox.shrink();
    }
    final from = _data?['sourceLockerName']?.toString();
    final to = _data?['destinationLockerName']?.toString();
    return Container(
      key: const ValueKey('drone-route-weather'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.air_rounded, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Thời tiết tuyến bay',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              IconButton(
                key: const ValueKey('drone-route-weather-refresh'),
                tooltip: 'Tải lại',
                visualDensity: VisualDensity.compact,
                onPressed: _loading ? null : _fetch,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          if (from != null || to != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${from ?? 'Tủ bay'} → ${to ?? 'Tủ nhận'}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          if (_loading && weather == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 3),
            )
          else if (_error != null && weather == null)
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12.5),
            )
          else if (weather != null)
            DroneWeatherSummary(weather: weather),
        ],
      ),
    );
  }
}

/// Thời tiết tại các tủ có bãi đáp drone — KTV xem trước khi nhận / phóng đơn.
class DroneLockerWeatherList extends StatefulWidget {
  const DroneLockerWeatherList({super.key, this.load});

  final DroneLockerWeatherLoader? load;

  @override
  State<DroneLockerWeatherList> createState() => _DroneLockerWeatherListState();
}

class _DroneLockerWeatherListState extends State<DroneLockerWeatherList> {
  List<Map<String, dynamic>> _lockers = const [];
  String? _error;
  bool _loading = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lockers =
          await (widget.load ?? LockerOpsService().droneLockerWeather)();
      if (!mounted) return;
      setState(() {
        _lockers = lockers;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = LockerOpsService.errorMessage(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chưa có tủ nào có bãi đáp: không chiếm chỗ trên màn điều phối.
    if (!_loading && _error == null && _lockers.isEmpty) {
      return const SizedBox.shrink();
    }
    final weathers = [
      for (final locker in _lockers)
        (locker, DroneWeather.fromJson(locker['weather'])),
    ];
    final unsafe = weathers.where((e) => e.$2 != null && !e.$2!.safe).length;
    final headline = _loading
        ? 'Đang tải thời tiết các tủ…'
        : _error != null
        ? _error!
        : unsafe == 0
        ? 'Cả ${weathers.length} tủ đều bay được trong 30 phút tới'
        : '$unsafe/${weathers.length} tủ đang không bay được hoặc chưa có dự báo';
    // Material (không phải Container có màu) để ListTile vẽ được nền và hiệu ứng chạm.
    return Padding(
      key: const ValueKey('drone-locker-weather'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                unsafe == 0
                    ? Icons.wb_sunny_outlined
                    : Icons.thunderstorm_outlined,
                color: unsafe == 0
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
              ),
              title: const Text(
                'Thời tiết tại các tủ drone',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(headline, style: const TextStyle(fontSize: 12.5)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: _loading ? null : _fetch,
                    icon: const Icon(Icons.refresh),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    for (final (locker, weather) in weathers)
                      if (weather != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: DroneWeatherSummary(
                            weather: weather,
                            title:
                                '${locker['name'] ?? locker['code'] ?? 'Tủ #${locker['lockerId']}'}',
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
