class NotificationDataPayload {
  final String actionType;
  final String? referenceId;
  final String? url;
  final Map<String, dynamic>? additionalContext;

  const NotificationDataPayload({
    required this.actionType,
    this.referenceId,
    this.url,
    this.additionalContext,
  });

  factory NotificationDataPayload.fromJson(Map<String, dynamic> json) {
    return NotificationDataPayload(
      actionType:
          (json['actionType'] ?? json['type'] ?? json['referenceType'] ?? '')
              .toString(),
      referenceId: json['referenceId']?.toString(),
      url: json['url']?.toString(),
      additionalContext: json['additionalContext'] as Map<String, dynamic>?,
    );
  }
}

class NotificationModel {
  final String id;
  final String? userId;
  final String title;
  final String body;
  final NotificationDataPayload? dataPayload;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    this.dataPayload,
    this.isRead = false,
    required this.createdAt,
    this.updatedAt,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      dataPayload: dataPayload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawTitle = (json['title'] ?? 'Thông báo').toString();
    final bodyContent =
        (json['body'] ?? json['content'] ?? json['message'] ?? '').toString();

    final createdAtStr = (json['createdAt'] ?? DateTime.now().toIso8601String())
        .toString();
    final updatedAtStr = (json['updatedAt'] ?? json['readAt'] ?? createdAtStr)
        .toString();
    final payload = json['dataPayload'] is Map<String, dynamic>
        ? json['dataPayload'] as Map<String, dynamic>
        : <String, dynamic>{
            if (json['type'] != null) 'type': json['type'],
            if (json['referenceId'] != null) 'referenceId': json['referenceId'],
            if (json['referenceType'] != null)
              'referenceType': json['referenceType'],
          };

    return NotificationModel(
      id: (json['id'] ?? json['notificationId'] ?? '').toString(),
      userId: json['userId']?.toString(),
      title: _translateTitle(rawTitle),
      body: _translateBody(bodyContent),
      dataPayload: payload.isNotEmpty
          ? NotificationDataPayload.fromJson(payload)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(createdAtStr).toLocal(),
      updatedAt: DateTime.parse(updatedAtStr).toLocal(),
    );
  }

  // ── Translation helpers ───────────────────────────────────────────────────

  static const _titleMap = <String, String>{
    'Rental expired': 'Đơn thuê đã hết hạn',
    'Pickup overdue': 'Quá hạn lấy hàng',
    'Rental extended': 'Gia hạn thuê thành công',
    'Parcel waiting for you': 'Có bưu kiện đang chờ bạn',
    'Parcel stored': 'Đã lưu bưu kiện',
    'Order delegated': 'Ủy quyền lấy hàng',
    'Order confirmed': 'Đơn hàng đã xác nhận',
    'Order cancelled': 'Đơn hàng đã bị hủy',
    'Order canceled': 'Đơn hàng đã bị hủy',
    'Payment successful': 'Thanh toán thành công',
    'Payment failed': 'Thanh toán thất bại',
    'New order': 'Đơn hàng mới',
    'Order initialized': 'Đơn hàng đã tạo',
    'Order storing': 'Đang lưu trữ',
    'Order ready': 'Sẵn sàng lấy hàng',
    'Order completed': 'Đơn hàng hoàn tất',
    'Order returned': 'Đã trả lại',
  };

  static String _translateTitle(String title) =>
      _titleMap[title] ?? _translateDynamicTitle(title);

  // Handles "Order <status>" patterns not in the static map
  static String _translateDynamicTitle(String title) {
    final orderStatusMatch = RegExp(
      r'^Order\s+(\w+)$',
      caseSensitive: false,
    ).firstMatch(title);
    if (orderStatusMatch != null) {
      final status = orderStatusMatch.group(1)!.toLowerCase();
      final vn = _statusVn(status);
      return 'Đơn hàng — $vn';
    }
    return title;
  }

  static String _translateBody(String body) {
    // "Rental ORD-xxx expired at <ISO>. Overtime fee applies."
    body = body.replaceAllMapped(
      RegExp(
        r'Rental (ORD-\S+) expired at (\S+)\. Overtime fee applies\.',
      ),
      (m) =>
          'Đơn thuê ${m[1]} đã hết hạn lúc ${_fmtIso(m[2]!)}. Phí quá giờ sẽ được áp dụng.',
    );

    // "Order ORD-xxx passed its pickup deadline <ISO>. Overtime fee applies."
    body = body.replaceAllMapped(
      RegExp(
        r'Order (ORD-\S+) passed its pickup deadline (\S+)\. Overtime fee applies\.',
      ),
      (m) =>
          'Đơn ${m[1]} đã quá hạn lấy hàng lúc ${_fmtIso(m[2]!)}. Phí quá giờ sẽ được áp dụng.',
    );

    // "Parcel ORD-xxx is still waiting. Overtime fee applies."
    body = body.replaceAllMapped(
      RegExp(r'Parcel (ORD-\S+) is still waiting\. Overtime fee applies\.'),
      (m) =>
          'Bưu kiện ${m[1]} vẫn đang chờ lấy. Phí quá giờ sẽ được áp dụng.',
    );

    // "Rental ORD-xxx extended until <ISO>"
    body = body.replaceAllMapped(
      RegExp(r'Rental (ORD-\S+) extended until (\S+)'),
      (m) => 'Đơn thuê ${m[1]} đã được gia hạn đến ${_fmtIso(m[2]!)}.',
    );

    // "Parcel ORD-xxx is waiting in locker <id>"
    body = body.replaceAllMapped(
      RegExp(r'Parcel (ORD-\S+) is waiting in locker (\S+)'),
      (m) => 'Bưu kiện ${m[1]} đang chờ tại tủ ${m[2]}.',
    );

    // "Parcel ORD-xxx stored. Receiver <phone>..."
    body = body.replaceAllMapped(
      RegExp(r'Parcel (ORD-\S+) stored\. Receiver (\S+)'),
      (m) => 'Đã lưu bưu kiện ${m[1]}. Người nhận: ${m[2]}.',
    );

    // "Order ORD-xxx pickup delegated to <phone>"
    body = body.replaceAllMapped(
      RegExp(r'Order (ORD-\S+) pickup delegated to (\S+)'),
      (m) => 'Đơn ${m[1]} đã được ủy quyền lấy cho ${m[2]}.',
    );

    // "Order ORD-xxx changed from <STATUS> to <STATUS>"
    body = body.replaceAllMapped(
      RegExp(r'Order (ORD-\S+) changed from (\w+) to (\w+)'),
      (m) =>
          'Đơn ${m[1]} chuyển trạng thái từ ${_statusVn(m[2]!.toLowerCase())} sang ${_statusVn(m[3]!.toLowerCase())}.',
    );

    return body;
  }

  static String _statusVn(String status) {
    const map = <String, String>{
      'initialized': 'Đã tạo',
      'storing': 'Đang lưu trữ',
      'ready': 'Sẵn sàng lấy',
      'completed': 'Hoàn tất',
      'canceled': 'Đã hủy',
      'cancelled': 'Đã hủy',
      'returned': 'Đã trả',
      'pending': 'Chờ xử lý',
      'active': 'Đang hoạt động',
      'expired': 'Hết hạn',
      'overdue': 'Quá hạn',
    };
    return map[status] ?? status;
  }

  static String _fmtIso(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$hh:$mm $dd/$mo/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class NotificationListResponse {
  final List<NotificationModel> items;
  final NotificationMeta meta;

  const NotificationListResponse({required this.items, required this.meta});

  factory NotificationListResponse.fromApiPayload(
    dynamic payload, {
    required int page,
    required int limit,
  }) {
    if (payload is List) {
      final items = payload
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
      return NotificationListResponse(
        items: items,
        meta: NotificationMeta(
          itemCount: items.length,
          totalItems: items.length,
          itemsPerPage: limit,
          totalPages: 1,
          currentPage: page,
        ),
      );
    }
    if (payload is Map<String, dynamic>) {
      return NotificationListResponse.fromJson(payload);
    }
    return NotificationListResponse(
      items: const [],
      meta: NotificationMeta(
        itemCount: 0,
        totalItems: 0,
        itemsPerPage: limit,
        totalPages: 1,
        currentPage: page,
      ),
    );
  }

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final hasMeta = json.containsKey('meta') && json['meta'] != null;
    final hasItems = json.containsKey('items') && json['items'] != null;

    List<NotificationModel> parsedItems = [];
    if (hasItems) {
      parsedItems = (json['items'] as List<dynamic>)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    NotificationMeta parsedMeta;
    if (hasMeta) {
      parsedMeta = NotificationMeta.fromJson(
        json['meta'] as Map<String, dynamic>,
      );
    } else {
      // Fallback for empty state where pagination is flattened in the response
      parsedMeta = NotificationMeta(
        itemCount: 0,
        totalItems: json['total'] as int? ?? 0,
        itemsPerPage: json['limit'] as int? ?? 15,
        totalPages: json['totalPages'] as int? ?? 0,
        currentPage: json['page'] as int? ?? 1,
      );
    }

    return NotificationListResponse(items: parsedItems, meta: parsedMeta);
  }
}

class NotificationMeta {
  final int itemCount;
  final int totalItems;
  final int itemsPerPage;
  final int totalPages;
  final int currentPage;

  const NotificationMeta({
    required this.itemCount,
    required this.totalItems,
    required this.itemsPerPage,
    required this.totalPages,
    required this.currentPage,
  });

  factory NotificationMeta.fromJson(Map<String, dynamic> json) {
    return NotificationMeta(
      itemCount: (json['itemCount'] ?? 0) as int,
      totalItems: (json['totalItems'] ?? 0) as int,
      itemsPerPage: (json['itemsPerPage'] ?? 15) as int,
      totalPages: (json['totalPages'] ?? 0) as int,
      currentPage: (json['currentPage'] ?? 1) as int,
    );
  }
}
