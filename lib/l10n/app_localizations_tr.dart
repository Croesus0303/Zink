// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Zink';

  @override
  String get appTagline => 'Yapay Zeka Destekli Fotoğraf Görevleri';

  @override
  String get continueWithGoogle => 'Google ile Devam Et';

  @override
  String get continueWithApple => 'Apple ile Devam Et';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String welcome(String name) {
    return 'Hoşgeldin $name!';
  }

  @override
  String get home => 'Ana Sayfa';

  @override
  String get noActiveChallenges => 'Şu anda aktif görev bulunmuyor';

  @override
  String get activeChallenge => 'Aktif Görev';

  @override
  String get pastChallenges => 'Geçmiş Görevler';

  @override
  String timeRemaining(String time) {
    return 'Kalan Süre: $time';
  }

  @override
  String get submitPhoto => 'Fotoğraf Gönder';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get chooseFromGallery => 'Galeriden Seç';

  @override
  String get submissions => 'Gönderiler';

  @override
  String likes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beğeni',
      one: '1 beğeni',
      zero: 'Beğeni yok',
    );
    return '$_temp0';
  }

  @override
  String comments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yorum',
      one: '1 yorum',
      zero: 'Yorum yok',
    );
    return '$_temp0';
  }

  @override
  String get addComment => 'Yorum ekle...';

  @override
  String get profile => 'Profil';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get username => 'Kullanıcı Adı';

  @override
  String get socialLinks => 'Sosyal Medya Bağlantıları';

  @override
  String get myChallenges => 'Görevlerim';

  @override
  String totalSubmissions(int count) {
    return '$count Gönderi';
  }

  @override
  String get mostPopular => 'En Popüler';

  @override
  String get newest => 'En Yeni';

  @override
  String get oldest => 'En Eski';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get error => 'Hata';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get confirm => 'Onayla';

  @override
  String get somethingWentWrong => 'Bir şeyler yanlış gitti';

  @override
  String get newChallengeAvailable => 'Yeni görev mevcut!';

  @override
  String get challengeEndingSoon => 'Görev yakında bitiyor!';

  @override
  String get submissionSuccessful => 'Fotoğraf başarıyla gönderildi!';

  @override
  String get submit => 'Gönder';
}
