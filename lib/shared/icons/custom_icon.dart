import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomIcons {
  CustomIcons._(); // prevent instantiation

  static Widget drawer(Color color, double size) {
    return SvgPicture.asset(
      'assets/icons/drawer.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget package(Color color, double size) {
    return SvgPicture.asset(
      'assets/icons/package.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
