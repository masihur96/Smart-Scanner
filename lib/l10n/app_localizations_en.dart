// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart QR Scanner';

  @override
  String get scanHistory => 'Scan History';

  @override
  String get noHistory => 'No scan history found.';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get clearHistoryConfirmation =>
      'Are you sure you want to delete all history?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get searchHistory => 'Search history...';

  @override
  String get scanResult => 'Scan Result';

  @override
  String get open => 'Open';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to scan QR codes.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get securityWarning => 'Security Warning';

  @override
  String get insecureConnectionMessage =>
      'This link does not use a secure connection (HTTPS). Are you sure you want to open it?';

  @override
  String get openAnyway => 'Open Anyway';

  @override
  String get website => 'Website';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone Number';

  @override
  String get wifi => 'WiFi Network';

  @override
  String get location => 'Location';

  @override
  String get text => 'Text';
}
