import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

import 'onboarding_controller.dart';
import 'tour_anchor.dart';

/// Nút "Hướng dẫn" nhỏ (dấu ?) cho thanh đầu trang đã chật nút (trang chủ KTV tủ / KTV drone): đặt cạnh nhãn vai
/// trò để không lấy thêm chỗ của tên. Mang neo `app-guide-button` như nút của trang chủ khách (F3-G13).
class TourGuideMiniButton extends StatelessWidget {
  const TourGuideMiniButton({super.key});

  @override
  Widget build(BuildContext context) => TourAnchor(
        'app-guide-button',
        child: Tooltip(
          message: context.l10n.tourHeaderButton,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              key: const ValueKey('tour-guide-mini'),
              customBorder: const CircleBorder(),
              onTap: OnboardingController.instance.openGuide,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.question_mark_rounded, size: 15, color: Colors.white),
              ),
            ),
          ),
        ),
      );
}
