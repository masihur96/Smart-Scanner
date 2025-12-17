// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'স্মার্ট কিউআর স্ক্যানার';

  @override
  String get scanHistory => 'স্ক্যান ইতিহাস';

  @override
  String get noHistory => 'কোন স্ক্যান ইতিহাস পাওয়া যায়নি।';

  @override
  String get clearHistory => 'ইতিহাস মুছুন';

  @override
  String get clearHistoryConfirmation =>
      'আপনি কি নিশ্চিত যে আপনি সমস্ত ইতিহাস মুছে ফেলতে চান?';

  @override
  String get cancel => 'বাতিল';

  @override
  String get delete => 'মুছুন';

  @override
  String get searchHistory => 'ইতিহাস খুঁজুন...';

  @override
  String get scanResult => 'স্ক্যান ফলাফল';

  @override
  String get open => 'খুলুন';

  @override
  String get copy => 'কপি';

  @override
  String get share => 'শেয়ার';

  @override
  String get copiedToClipboard => 'ক্লিপবোর্ডে কপি করা হয়েছে';

  @override
  String get cameraPermissionRequired =>
      'কিউআর কোড স্ক্যান করতে ক্যামেরার অনুমতি প্রয়োজন।';

  @override
  String get grantPermission => 'অনুমতি দিন';

  @override
  String get securityWarning => 'নিরাপত্তা সতর্কতা';

  @override
  String get insecureConnectionMessage =>
      'এই লিঙ্কটি নিরাপদ সংযোগ (HTTPS) ব্যবহার করে না। আপনি কি নিশ্চিত যে আপনি এটি খুলতে চান?';

  @override
  String get openAnyway => 'তবুও খুলুন';

  @override
  String get website => 'ওয়েবসাইট';

  @override
  String get email => 'ইমেল';

  @override
  String get phone => 'ফোন নম্বর';

  @override
  String get wifi => 'ওয়াইফাই নেটওয়ার্ক';

  @override
  String get location => 'অবস্থান';

  @override
  String get text => 'টেক্সট';
}
