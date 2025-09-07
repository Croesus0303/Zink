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
  String get signInOrSignUp => 'Giriş Yap veya Kayıt Ol';

  @override
  String get newUserPrompt => 'Zink\'te yeni misin? Google hesabınla kayıt ol';

  @override
  String get existingUserPrompt =>
      'Zaten hesabın var mı? Devam etmek için giriş yap';

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
  String get comments => 'Yorumlar';

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

  @override
  String get welcomeToZink => 'Zink\'e Hoşgeldin!';

  @override
  String get onboardingSubtitle => 'Başlamak için profilini ayarlayalım';

  @override
  String get chooseUsername => 'Kullanıcı adı seç';

  @override
  String get enterUsername => 'Kullanıcı adını gir';

  @override
  String get whatsYourAge => 'Yaşın kaç?';

  @override
  String get enterAge => 'Yaşını gir';

  @override
  String get completeSetup => 'Kurulumu Tamamla';

  @override
  String get usernameRequired => 'Kullanıcı adı gerekli';

  @override
  String get usernameTooShort => 'Kullanıcı adı en az 3 karakter olmalı';

  @override
  String get usernameTooLong => 'Kullanıcı adı 20 karakterden az olmalı';

  @override
  String get usernameInvalidChars =>
      'Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir';

  @override
  String get ageRequired => 'Yaş gerekli';

  @override
  String get enterValidNumber => 'Lütfen geçerli bir sayı girin';

  @override
  String get ageTooYoung => 'En az 13 yaşında olmalısınız';

  @override
  String get enterValidAge => 'Lütfen geçerli bir yaş girin';

  @override
  String get privacyNote =>
      'Devam ederek Hizmet Şartlarımızı ve Gizlilik Politikamızı kabul etmiş olursunuz. Bilgileriniz güvenlidir ve sadece deneyiminizi geliştirmek için kullanılacaktır.';

  @override
  String get profilePicture => 'Profil Fotoğrafı';

  @override
  String get changeProfilePicture => 'Profil Fotoğrafını Değiştir';

  @override
  String get displayName => 'Görünen Ad';

  @override
  String get basicInformation => 'Temel Bilgiler';

  @override
  String get socialMediaLinks => 'Sosyal Medya Bağlantıları';

  @override
  String get instagram => 'Instagram';

  @override
  String get twitter => 'Twitter';

  @override
  String get facebook => 'Facebook';

  @override
  String get linkedin => 'LinkedIn';

  @override
  String get website => 'Web Sitesi';

  @override
  String get settings => 'Ayarlar';

  @override
  String get email => 'E-posta';

  @override
  String get enterEmail => 'E-postanızı girin';

  @override
  String get password => 'Şifre';

  @override
  String get enterPassword => 'Şifrenizi girin';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get reenterPassword => 'Şifrenizi tekrar girin';

  @override
  String get pleaseEnterEmail => 'Lütfen e-postanızı girin';

  @override
  String get pleaseEnterValidEmail => 'Lütfen geçerli bir e-posta girin';

  @override
  String get pleaseEnterPassword => 'Lütfen şifrenizi girin';

  @override
  String get passwordTooShort => 'Şifre en az 6 karakter olmalı';

  @override
  String get pleaseConfirmPassword => 'Lütfen şifrenizi onaylayın';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get app => 'Uygulama';

  @override
  String get about => 'Hakkında';

  @override
  String version(String version) {
    return 'Sürüm $version';
  }

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get helpAndSupport => 'Yardım ve Destek';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get permanentlyDeleteAccount =>
      'Hesabınızı ve tüm verilerinizi kalıcı olarak silin';

  @override
  String get close => 'Kapat';

  @override
  String get socialPhotoSharingApp =>
      'Etkinlikler ve anlar için sosyal fotoğraf paylaşım uygulaması.';

  @override
  String get zinkPrivacyPolicy => 'Zink Gizlilik Politikası';

  @override
  String lastUpdated(String year) {
    return 'Son güncelleme: $year';
  }

  @override
  String get informationWeCollect => 'Topladığımız Bilgiler';

  @override
  String get howWeUseInformation => 'Bilgileri Nasıl Kullanırız';

  @override
  String get informationSharing => 'Bilgi Paylaşımı';

  @override
  String get dataSecurity => 'Veri Güvenliği';

  @override
  String get yourRights => 'Haklarınız';

  @override
  String get contactUs => 'Bize Ulaşın';

  @override
  String get frequentlyAskedQuestions => 'Sık Sorulan Sorular';

  @override
  String get howCreateAccount =>
      'Nasıl hesap oluştururum?\nKayıt ol düğmesine dokunun ve hesabınızı oluşturmak için talimatları izleyin.';

  @override
  String get howPostPhoto =>
      'Nasıl fotoğraf paylaşırım?\nEtkinlikler bölümündeki kamera simgesine dokunun ve aktif bir etkinlik seçin.';

  @override
  String get howLikeSubmission =>
      'Bir gönderiyi nasıl beğenirim?\nHerhangi bir fotoğraf gönderisinin altındaki kalp simgesine dokunun.';

  @override
  String get howEditProfile =>
      'Profilimi nasıl düzenlerim?\nProfil > Menü > Profili Düzenle\'ye gidin.';

  @override
  String get contactSupport => 'Destek İletişim';

  @override
  String get emailSupport => 'E-posta: support@zinkapp.com';

  @override
  String get responseTime => 'Yanıt süresi: 24-48 saat';

  @override
  String get urgentIssuesNote =>
      'Acil durumlar için konu satırına \"ACİL\" yazın.';

  @override
  String get appVersion => 'Uygulama Sürümü';

  @override
  String get platformMobile => 'Platform: Mobil Uygulama';

  @override
  String get reportBug => 'Hata Bildir';

  @override
  String get bugReportInstructions =>
      'Herhangi bir sorunla karşılaştığınızda lütfen şunları açıklayın:\n• Sorun oluştuğunda ne yapıyordunuz\n• Sorunu yeniden oluşturmak için adımlar\n• Cihaz modeliniz ve işletim sistemi sürümü';

  @override
  String get actionCannotBeUndone =>
      'Bu eylem geri alınamaz. Bu, hesabınızı ve tüm ilişkili verileri kalıcı olarak silecektir.';

  @override
  String get enterPasswordToConfirm => 'Onaylamak için lütfen şifrenizi girin:';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get accountDeletedSuccessfully => 'Hesap başarıyla silindi';

  @override
  String get incorrectPassword => 'Yanlış şifre. Lütfen tekrar deneyin.';

  @override
  String get tooManyFailedAttempts =>
      'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';

  @override
  String get failedToDeleteAccount =>
      'Hesap silinirken hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get finalConfirmation => 'Son Onay';

  @override
  String get absolutelySureWarning =>
      'Kesinlikle emin misiniz? Bu eylem geri alınamaz ve şunları kalıcı olarak silecektir:\n\n• Profil ve hesap verileriniz\n• Tüm gönderileriniz ve yarışma katılımlarınız\n• Sohbet geçmişiniz\n• Diğer tüm ilgili veriler\n\nBu eylem geri alınamaz.';

  @override
  String get yesDeleteMyAccount => 'Evet, Hesabımı Sil';

  @override
  String get eventNotFound => 'Etkinlik Bulunamadı';

  @override
  String get errorLoadingEvent => 'Etkinlik yüklenirken hata';

  @override
  String get goBack => 'Geri Dön';

  @override
  String get submissionLimitReached => 'Gönderim Sınırına Ulaşıldı';

  @override
  String get usedAllSubmissions =>
      'Bu etkinlik için tüm gönderimlerinizi kullandınız.';

  @override
  String get challenge => 'Görev';

  @override
  String get endingSoon => 'Yakında bitiyor';

  @override
  String get yourPhoto => 'Fotoğrafınız';

  @override
  String get addYourPhoto => 'Fotoğrafınızı ekleyin';

  @override
  String get submissionGuidelines => 'Gönderim Kuralları';

  @override
  String get matchChallengeTheme =>
      'Fotoğrafınızın görev temasına uygun olduğundan emin olun';

  @override
  String get useGoodLighting => 'İyi ışıklandırma ve net odak kullanın';

  @override
  String get originalPhotosOnly =>
      'Sadece orijinal fotoğraflar - ekran görüntüsü veya indirilen resimler kabul edilmez';

  @override
  String failedToTakePhoto(String error) {
    return 'Fotoğraf çekilirken hata: $error';
  }

  @override
  String failedToSelectPhoto(String error) {
    return 'Fotoğraf seçilirken hata: $error';
  }

  @override
  String get pleaseSelectPhotoFirst => 'Lütfen önce bir fotoğraf seçin';

  @override
  String get userNotAuthenticated => 'Kullanıcı kimlik doğrulaması yapılmamış';

  @override
  String failedToSubmitPhoto(String error) {
    return 'Fotoğraf gönderilirken hata: $error';
  }

  @override
  String get submitting => 'Gönderiliyor...';

  @override
  String get errorLoadingSubmissionData => 'Gönderim verileri yüklenirken hata';

  @override
  String get authenticationRequired => 'Kimlik Doğrulama Gerekli';

  @override
  String get pleaseSignInToSubmit =>
      'Fotoğraf göndermek için lütfen giriş yapın';

  @override
  String get submissionNotFound => 'Gönderim Bulunamadı';

  @override
  String get errorLoadingSubmission => 'Gönderim yüklenirken hata';

  @override
  String get photo => 'Fotoğraf';

  @override
  String get deletePost => 'Gönderiyi Sil';

  @override
  String get sureDeletePost =>
      'Bu gönderiyi silmek istediğinizden emin misiniz? Bu eylem geri alınamaz.';

  @override
  String get postDeletedSuccessfully => 'Gönderi başarıyla silindi';

  @override
  String get failedToDeletePost => 'Gönderi silinirken hata oluştu';

  @override
  String get messages => 'Mesajlar';

  @override
  String get errorLoadingChats => 'Sohbetler yüklenirken hata';

  @override
  String get noConversationsYet => 'Henüz konuşma yok';

  @override
  String get unknownUser => 'Bilinmeyen Kullanıcı';

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get failedToLoadUserData => 'Kullanıcı verileri yüklenemedi';

  @override
  String get chatDeleted => 'Sohbet silindi';

  @override
  String get deleteChat => 'Sohbeti Sil';

  @override
  String get justNow => 'Az önce';

  @override
  String get user => 'Kullanıcı';

  @override
  String get errorLoadingMessages => 'Mesajlar yüklenirken hata';

  @override
  String get typeMessage => 'Bir mesaj yazın...';

  @override
  String get userNotFound => 'Kullanıcı bulunamadı';

  @override
  String pageNotFound(String location) {
    return 'Sayfa bulunamadı: $location';
  }

  @override
  String get goHome => 'Ana Sayfaya Git';

  @override
  String get noSubmissionsYet => 'Henüz gönderim yok';

  @override
  String get beFirstToSubmit => 'İlk fotoğrafı gönderen siz olun!';

  @override
  String get errorLoadingSubmissions => 'Gönderimler yüklenirken hata';

  @override
  String get anonymousWinner => 'Anonim Kazanan';

  @override
  String get championOfEvent => 'Bu etkinliğin şampiyonu!';

  @override
  String get storageTest => 'Depolama Testi';

  @override
  String get testStorageConnection => 'Depolama Bağlantısını Test Et';

  @override
  String get pickImageAndUpload => 'Resim Seç ve Yükle';

  @override
  String get selectedImage => 'Seçilen Resim:';

  @override
  String get accountExistsWithDifferentCredential =>
      'Bu kimlik bilgisi ile farklı bir hesap zaten var.';

  @override
  String get credentialMalformedOrExpired =>
      'Alınan kimlik bilgisi hatalı veya süresi dolmuş.';

  @override
  String get operationNotAllowed =>
      'Bu işleme izin verilmiyor. Lütfen destek ile iletişime geçin.';

  @override
  String get userAccountDisabled => 'Bu kullanıcı hesabı devre dışı bırakıldı.';

  @override
  String get noUserFoundWithEmail =>
      'Bu e-posta adresi ile kullanıcı bulunamadı.';

  @override
  String get incorrectPasswordTryAgain =>
      'Yanlış şifre. Lütfen tekrar deneyin.';

  @override
  String get tooManyRequestsTryLater =>
      'Çok fazla istek. Daha sonra tekrar deneyin.';

  @override
  String get networkErrorCheckConnection =>
      'Ağ hatası. Lütfen bağlantınızı kontrol edin.';

  @override
  String get emailAlreadyRegistered =>
      'Bu e-posta adresi zaten kayıtlı. Lütfen bunun yerine giriş yapın.';

  @override
  String get enterValidEmailAddress =>
      'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get passwordTooWeak =>
      'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';

  @override
  String get signOutAndSignInAgain =>
      'Bu isteği tekrar denemeden önce lütfen çıkış yapın ve tekrar giriş yapın.';

  @override
  String get verificationCodeInvalid =>
      'Doğrulama kodu geçersiz. Lütfen tekrar deneyin.';

  @override
  String get verificationIdInvalid =>
      'Doğrulama kimliği geçersiz. Lütfen tekrar deneyin.';

  @override
  String get authenticationFailedTryAgain =>
      'Kimlik doğrulama başarısız. Lütfen tekrar deneyin.';

  @override
  String failedToLoadChat(String error) {
    return 'Sohbet yüklenemedi: $error';
  }

  @override
  String failedToSendMessage(String error) {
    return 'Mesaj gönderilemedi: $error';
  }

  @override
  String get noConversationsDescription =>
      'Birinin profilini ziyaret ederek bir konuşma başlatın';

  @override
  String get startConversation => 'Konuşmayı başlat!';

  @override
  String failedToDeleteChat(String error) {
    return 'Sohbet silinemedi: $error';
  }

  @override
  String get sureDeleteChat =>
      'Bu sohbeti silmek istediğinizden emin misiniz? Bu eylem geri alınamaz.';

  @override
  String yesterday(String time) {
    return 'Dün $time';
  }

  @override
  String daysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String hoursLeft(int hours, int minutes) {
    return '${hours}s ${minutes}dk kaldı';
  }

  @override
  String minutesLeft(int minutes) {
    return '${minutes}dk kaldı';
  }

  @override
  String get active => 'Aktif';

  @override
  String get ended => 'Bitti';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}dk önce';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}s önce';
  }

  @override
  String daysAgoShort(int days) {
    return '${days}g önce';
  }

  @override
  String get profileNotSetUp => 'Profil henüz ayarlanmamış';

  @override
  String get pleaseCompleteProfileSetup =>
      'Lütfen profil kurulumunu tamamlayın';

  @override
  String errorLoadingProfile(String error) {
    return 'Profil yüklenirken hata: $error';
  }

  @override
  String get spotlight => 'ÖNEÇIKAN';
}
