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
  String get appTagline => 'AI Destekli Fotoğraf Yarışmaları';

  @override
  String get continueWithGoogle => 'Google ile Devam Et';

  @override
  String get signInOrSignUp => 'Giriş Yap veya Kaydol';

  @override
  String get newUserPrompt => 'Zink\'te yeni misin? Google hesabınla kaydol';

  @override
  String get existingUserPrompt =>
      'Zaten hesabın var mı? Devam etmek için giriş yap';

  @override
  String get continueWithApple => 'Apple ile Devam Et';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signOutConfirmation => 'Çıkış yapmak istediğinden emin misin?';

  @override
  String welcome(String name) {
    return 'Hoş geldin $name!';
  }

  @override
  String get home => 'Ana Sayfa';

  @override
  String get noActiveChallenges => 'Şu anda aktif yarışma yok';

  @override
  String get activeChallenge => 'Aktif Yarışma';

  @override
  String get pastChallenges => 'Geçmiş Yarışmalar';

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
    return '$count beğeni';
  }

  @override
  String commentCount(int count) {
    return '$count yorum';
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
  String get myChallenges => 'Yarışmalarım';

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
  String get somethingWentWrong => 'Bir şeyler ters gitti';

  @override
  String get newChallengeAvailable => 'Yeni yarışma mevcut!';

  @override
  String get challengeEndingSoon => 'Yarışma yakında bitiyor!';

  @override
  String get submissionSuccessful => 'Fotoğraf başarıyla gönderildi!';

  @override
  String get submit => 'Gönder';

  @override
  String get welcomeToZink => 'Zink\'e Hoş Geldin!';

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
      'Devam ederek Hizmet Şartlarımızı ve Gizlilik Politikamızı kabul etmiş olursunuz.';

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
  String get howWeUseInformation => 'Bilgilerinizi Nasıl Kullanırız';

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
      'Nasıl hesap oluştururum?\nKaydol butonuna dokunun ve yönergeleri takip edin.';

  @override
  String get howPostPhoto =>
      'Nasıl fotoğraf paylaşırım?\nEtkinlikler bölümündeki kamera simgesine dokunun.';

  @override
  String get howLikeSubmission =>
      'Bir gönderiyi nasıl beğenirim?\nKalp simgesine dokunun.';

  @override
  String get howEditProfile =>
      'Profilimi nasıl düzenlerim?\nProfil > Menü > Profili Düzenle\'ye gidin.';

  @override
  String get contactSupport => 'Destek ile İletişim';

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
      'Sorun yaşarsanız lütfen açıklayın:\n• Ne yaptığınızda sorun oluştu\n• Sorunu tekrarlama adımları\n• Cihaz ve işletim sistemi bilgisi';

  @override
  String get actionCannotBeUndone =>
      'Bu işlem geri alınamaz. Hesabınızı kalıcı olarak silecektir.';

  @override
  String get enterPasswordToConfirm => 'Onaylamak için şifrenizi girin:';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get accountDeletedSuccessfully => 'Hesap başarıyla silindi';

  @override
  String get incorrectPassword => 'Yanlış şifre. Tekrar deneyin.';

  @override
  String get tooManyFailedAttempts =>
      'Çok fazla başarısız deneme. Daha sonra tekrar deneyin.';

  @override
  String get failedToDeleteAccount => 'Hesap silinemedi. Tekrar deneyin.';

  @override
  String get finalConfirmation => 'Son Onay';

  @override
  String get absolutelySureWarning =>
      'Kesinlikle emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get yesDeleteMyAccount => 'Evet, Hesabımı Sil';

  @override
  String get eventNotFound => 'Etkinlik Bulunamadı';

  @override
  String get errorLoadingEvent => 'Etkinlik yüklenirken hata oluştu';

  @override
  String get goBack => 'Geri Dön';

  @override
  String get submissionLimitReached => 'Gönderi Limitine Ulaşıldı';

  @override
  String get usedAllSubmissions =>
      'Bu etkinlik için tüm gönderilerinizi kullandınız.';

  @override
  String get challenge => 'Yarışma';

  @override
  String get endingSoon => 'Yakında bitiyor';

  @override
  String get yourPhoto => 'Fotoğrafın';

  @override
  String get addYourPhoto => 'Fotoğrafını ekle';

  @override
  String get submissionGuidelines => 'Gönderi Kuralları';

  @override
  String get matchChallengeTheme =>
      'Fotoğrafınızın yarışma temasına uygun olduğundan emin olun';

  @override
  String get useGoodLighting => 'İyi aydınlatma ve net odak kullanın';

  @override
  String get originalPhotosOnly => 'Sadece orijinal fotoğraflar kabul edilir';

  @override
  String get cameraPermissionDenied =>
      'Fotoğraf çekmek için kamera izni gereklidir';

  @override
  String get photoLibraryPermissionDenied =>
      'Fotoğraf seçmek için fotoğraf kitaplığı izni gereklidir';

  @override
  String failedToTakePhoto(String error) {
    return 'Fotoğraf çekilemedi: $error';
  }

  @override
  String failedToSelectPhoto(String error) {
    return 'Fotoğraf seçilemedi: $error';
  }

  @override
  String get pleaseSelectPhotoFirst => 'Lütfen önce bir fotoğraf seçin';

  @override
  String get userNotAuthenticated => 'Kullanıcı doğrulanmadı';

  @override
  String failedToSubmitPhoto(String error) {
    return 'Fotoğraf gönderilemedi: $error';
  }

  @override
  String get submitting => 'Gönderiliyor...';

  @override
  String get errorLoadingSubmissionData =>
      'Gönderi verileri yüklenirken hata oluştu';

  @override
  String get authenticationRequired => 'Doğrulama Gerekli';

  @override
  String get pleaseSignInToSubmit => 'Fotoğraf göndermek için giriş yapın';

  @override
  String get submissionNotFound => 'Gönderi Bulunamadı';

  @override
  String get errorLoadingSubmission => 'Gönderi yüklenirken hata oluştu';

  @override
  String get photo => 'Fotoğraf';

  @override
  String get deletePost => 'Gönderiyi Sil';

  @override
  String get sureDeletePost =>
      'Bu gönderiyi silmek istediğinizden emin misiniz?';

  @override
  String get postDeletedSuccessfully => 'Gönderi başarıyla silindi';

  @override
  String get failedToDeletePost => 'Gönderi silinemedi';

  @override
  String get messages => 'Mesajlar';

  @override
  String get errorLoadingChats => 'Sohbetler yüklenirken hata oluştu';

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
  String get errorLoadingMessages => 'Mesajlar yüklenirken hata oluştu';

  @override
  String get typeMessage => 'Mesaj yazın...';

  @override
  String get userNotFound => 'Kullanıcı bulunamadı';

  @override
  String pageNotFound(String location) {
    return 'Sayfa bulunamadı: $location';
  }

  @override
  String get goHome => 'Ana Sayfaya Git';

  @override
  String get noSubmissionsYet => 'Henüz gönderi yok';

  @override
  String get beFirstToSubmit => 'Fotoğraf gönderen ilk kişi ol!';

  @override
  String get errorLoadingSubmissions => 'Gönderiler yüklenirken hata oluştu';

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
      'Farklı kimlik bilgileriyle bir hesap mevcut.';

  @override
  String get credentialMalformedOrExpired =>
      'Kimlik bilgisi hatalı veya süresi dolmuş.';

  @override
  String get operationNotAllowed => 'Bu işleme izin verilmiyor.';

  @override
  String get userAccountDisabled => 'Kullanıcı hesabı devre dışı bırakılmış.';

  @override
  String get noUserFoundWithEmail =>
      'Bu e-posta adresine sahip kullanıcı bulunamadı.';

  @override
  String get incorrectPasswordTryAgain => 'Yanlış şifre. Tekrar deneyin.';

  @override
  String get tooManyRequestsTryLater =>
      'Çok fazla istek. Daha sonra tekrar deneyin.';

  @override
  String get networkErrorCheckConnection =>
      'Ağ hatası. Bağlantınızı kontrol edin.';

  @override
  String get emailAlreadyRegistered => 'Bu e-posta adresi zaten kayıtlı.';

  @override
  String get enterValidEmailAddress => 'Geçerli bir e-posta adresi girin.';

  @override
  String get passwordTooWeak => 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';

  @override
  String get signOutAndSignInAgain => 'Çıkış yapın ve tekrar giriş yapın.';

  @override
  String get verificationCodeInvalid => 'Doğrulama kodu geçersiz.';

  @override
  String get verificationIdInvalid => 'Doğrulama kimliği geçersiz.';

  @override
  String get authenticationFailedTryAgain =>
      'Kimlik doğrulama başarısız. Tekrar deneyin.';

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
      'Birinin profilini ziyaret ederek konuşma başlatın';

  @override
  String get startConversation => 'Konuşmayı başlat!';

  @override
  String failedToDeleteChat(String error) {
    return 'Sohbet silinemedi: $error';
  }

  @override
  String get sureDeleteChat => 'Bu sohbeti silmek istediğinizden emin misiniz?';

  @override
  String yesterdayAt(String time) {
    return 'Dün $time';
  }

  @override
  String daysAgo(int days) {
    return '$days gün önce';
  }

  @override
  String hoursLeft(int hours, int minutes) {
    return '${hours}sa ${minutes}dk kaldı';
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
    return '${hours}sa önce';
  }

  @override
  String daysAgoShort(int days) {
    return '${days}g önce';
  }

  @override
  String get comments => 'Yorumlar';

  @override
  String get profileNotSetUp => 'Profil henüz ayarlanmadı';

  @override
  String get pleaseCompleteProfileSetup =>
      'Lütfen profil kurulumunuzu tamamlayın';

  @override
  String errorLoadingProfile(String error) {
    return 'Profil yüklenirken hata oluştu: $error';
  }

  @override
  String get spotlight => 'SPOT IŞIĞI';

  @override
  String get pastTasks => 'Geçmiş Görevler';

  @override
  String get noActiveTasksRight => 'Şu anda aktif görev yok';

  @override
  String get tasksLoading => 'Görevler yükleniyor...';

  @override
  String get errorLoadingTasks => 'Görevler yüklenirken hata oluştu';

  @override
  String get noPastTasksYet => 'Henüz geçmiş görev yok';

  @override
  String get notificationPermissionMessage =>
      'Yeni görevler ve güncellemeler hakkında bildirim almak için izin verin.';

  @override
  String get notNow => 'Şimdi Değil';

  @override
  String get allowPermission => 'İzin Ver';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notificationPermissionGranted => 'Bildirim izni verildi!';

  @override
  String get notificationPermissionDenied => 'Bildirim izni reddedildi.';

  @override
  String get today => 'Bugün';

  @override
  String daysLeft(int days) {
    return '${days}g kaldı';
  }

  @override
  String daysAndHoursLeft(int days, int hours) {
    return '${days}g ${hours}sa kaldı';
  }

  @override
  String get noNotificationsYet => 'Henüz bildirim yok';

  @override
  String get notificationsWillAppearHere =>
      'Beğeniler ve yorumlar hakkında bildirimleri burada alacaksınız';

  @override
  String get errorLoadingNotifications => 'Bildirimler yüklenirken hata oluştu';

  @override
  String get allNotificationsMarkedAsRead =>
      'Tüm bildirimler okundu olarak işaretlendi';

  @override
  String get failedToMarkNotificationsAsRead =>
      'Bildirimler okundu olarak işaretlenemedi';

  @override
  String get failedToDeleteNotification => 'Bildirim silinemedi';

  @override
  String minutesAgoShort(int minutes) {
    return '${minutes}dk önce';
  }

  @override
  String hoursAgoShort(int hours) {
    return '${hours}sa önce';
  }

  @override
  String get yesterday => 'Dün';

  @override
  String weeksAgoShort(int weeks) {
    return '${weeks}h önce';
  }

  @override
  String get timeline => 'Zaman Tüneli';

  @override
  String get events => 'Etkinlikler';

  @override
  String get noPostsYet => 'Henüz gönderi yok';

  @override
  String get checkBackLater =>
      'Yeni gönderiler için daha sonra tekrar kontrol edin';

  @override
  String get errorLoadingTimeline => 'Zaman tüneli yüklenirken hata oluştu';

  @override
  String get unknown => 'Bilinmeyen';
}
