import 'package:url_launcher/url_launcher.dart';

Future<bool> openLockerDirections({
  double? latitude,
  double? longitude,
  String? address,
}) async {
  final Uri? uri;
  if (latitude != null && longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=driving',
    );
  } else if (address != null && address.trim().isNotEmpty) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(address.trim())}',
    );
  } else {
    uri = null;
  }

  if (uri == null) return false;
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
