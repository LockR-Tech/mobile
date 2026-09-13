import 'package:envied/envied.dart';

part 'env_config.g.dart';

@Envied(path: '.env')
// Trigger rebuild
abstract class EnvConfig {
  @EnviedField(
    varName: 'API_BASE_URL',
    defaultValue: 'https://api.locker-drone.tech',
    //'http://10.0.2.2:3000', // 10.0.2.2 is Android emulator's alias for host localhost
  )
  static const String apiBaseUrl = _EnvConfig.apiBaseUrl;

  // Google Web (server) client ID — passed as `serverClientId` to google_sign_in
  // so Google sign-in returns an ID token whose audience the backend (Firebase
  // Admin) can verify. PUBLIC value (also present in
  // android/app/google-services.json oauth_client type 3), not a secret.
  static const String googleWebClientId =
      '1007589685877-s8jcspo0fsils3f97sqgrmfaqhakrsam.apps.googleusercontent.com';

  // @EnviedField(varName: 'GOOGLE_MAPS_API_KEY', defaultValue: '')
  // static const String googleMapsApiKey = _EnvConfig.googleMapsApiKey;

  // iOS Client ID (for iOS native authentication)
  // @EnviedField(varName: 'GOOGLE_IOS_CLIENT_ID', defaultValue: '')
  // static const String googleIosClientId = _EnvConfig.googleIosClientId;

  // @EnviedField(varName: 'GOOGLE_ANDROID_CLIENT_ID', defaultValue: '')
  // static const String googleAndroidClientId = _EnvConfig.googleAndroidClientId;
}
