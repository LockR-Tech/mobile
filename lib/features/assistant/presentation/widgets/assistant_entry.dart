import 'package:flutter/material.dart';

import '../../data/models/assistant_models.dart';
import '../providers/assistant_availability.dart';

/// Lối vào trợ lý: chỉ dựng [builder] khi `GET /api/assistant/status` báo
/// `enabled == true`; chưa biết / đang tắt / lỗi ⇒ không hiện gì.
class AssistantEntryGate extends StatefulWidget {
  const AssistantEntryGate({
    super.key,
    required this.builder,
    this.availability,
  });

  final WidgetBuilder builder;

  /// Mặc định [AssistantAvailability.instance].
  final AssistantAvailability? availability;

  @override
  State<AssistantEntryGate> createState() => _AssistantEntryGateState();
}

class _AssistantEntryGateState extends State<AssistantEntryGate> {
  late final AssistantAvailability _availability =
      widget.availability ?? AssistantAvailability.instance;

  @override
  void initState() {
    super.initState();
    _availability.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AssistantStatus?>(
      valueListenable: _availability,
      builder: (context, status, _) => status?.enabled == true
          ? widget.builder(context)
          : const SizedBox.shrink(),
    );
  }
}
