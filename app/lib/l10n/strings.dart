// UI strings in Pashto (default), Dari, English — plain Dart, no Flutter
// imports, so the parity test can run anywhere. RULE: every key must exist
// in all three languages (test/string_parity in tool/verify_pure.dart).
class Strings {
  static const List<String> languages = ['ps', 'fa', 'en'];
  static const Map<String, String> languageNames = {
    'ps': 'پښتو',
    'fa': 'دری',
    'en': 'English',
  };

  static const Map<String, Map<String, String>> _table = {
    'app_name': {'ps': 'موبایل کرېډېټ', 'fa': 'کریدیت موبایل', 'en': 'Mobile Credit'},
    'tagline': {'ps': 'خپلو خپلوانو ته کرېډېټ ولېږئ', 'fa': 'برای خانواده‌تان کریدیت بفرستید', 'en': 'Send credit to your family'},
    'continue_btn': {'ps': 'دوام', 'fa': 'ادامه', 'en': 'Continue'},
    'back': {'ps': 'شاته', 'fa': 'برگشت', 'en': 'Back'},
    'listen': {'ps': 'واورئ', 'fa': 'بشنوید', 'en': 'Listen'},
    'choose_language': {'ps': 'ژبه وټاکئ', 'fa': 'زبان را انتخاب کنید', 'en': 'Choose your language'},
    'new_topup': {'ps': 'نوی کرېډېټ لېږل', 'fa': 'ارسال کریدیت جدید', 'en': 'New top-up'},
    'history': {'ps': 'پخواني لېږل', 'fa': 'تاریخچه', 'en': 'History'},
    'settings': {'ps': 'تنظیمات', 'fa': 'تنظیمات', 'en': 'Settings'},
    'voice_guidance': {'ps': 'غږ لارښوونه', 'fa': 'راهنمای صوتی', 'en': 'Voice guidance'},
    'language': {'ps': 'ژبه', 'fa': 'زبان', 'en': 'Language'},
    'choose_country': {'ps': 'هېواد وټاکئ', 'fa': 'کشور را انتخاب کنید', 'en': 'Choose the country'},
    'enter_number': {'ps': 'شمېره ولیکئ', 'fa': 'شماره را وارد کنید', 'en': 'Enter the number'},
    'number_example': {'ps': 'بېلګه: 079 123 4567', 'fa': 'مثال: 079 123 4567', 'en': 'Example: 079 123 4567'},
    'detecting': {'ps': 'شبکه موندل کېږي...', 'fa': 'در حال یافتن شبکه...', 'en': 'Finding the network...'},
    'operator_label': {'ps': 'شبکه', 'fa': 'شبکه', 'en': 'Network'},
    'operator_auto': {'ps': 'شبکه: په اتومات ډول', 'fa': 'شبکه: خودکار', 'en': 'Network: automatic'},
    'confirm_q': {'ps': 'ایا دا شمېره سمه ده؟', 'fa': 'آیا این شماره درست است؟', 'en': 'Is this number correct?'},
    'yes_correct': {'ps': 'هو، سمه ده', 'fa': 'بله، درست است', 'en': 'Yes, correct'},
    'no_change': {'ps': 'نه، بدلول یې', 'fa': 'نه، تغییرش بده', 'en': 'No, change it'},
    'choose_amount': {'ps': 'مقدار وټاکئ', 'fa': 'مبلغ را انتخاب کنید', 'en': 'Choose the amount'},
    'other_amount': {'ps': 'بل مقدار', 'fa': 'مبلغ دیگر', 'en': 'Other amount'},
    'amount_label': {'ps': 'مقدار', 'fa': 'مبلغ', 'en': 'Amount'},
    'review_title': {'ps': 'معلومات وګورئ', 'fa': 'جزئیات را بررسی کنید', 'en': 'Check the details'},
    'send_to': {'ps': 'شمېره', 'fa': 'شماره', 'en': 'Number'},
    'you_send': {'ps': 'تاسو لېږئ', 'fa': 'شما می‌فرستید', 'en': 'You send'},
    'total_to_pay': {'ps': 'ټول قیمت', 'fa': 'قیمت کل', 'en': 'Total to pay'},
    'pay_now': {'ps': 'پیسې ورکړئ', 'fa': 'پرداخت کنید', 'en': 'Pay now'},
    'processing': {'ps': 'لېږل کېږي...', 'fa': 'در حال ارسال...', 'en': 'Sending...'},
    'success_title': {'ps': 'بریالی شو!', 'fa': 'موفقانه ارسال شد!', 'en': 'Sent!'},
    'failed_title': {'ps': 'ونه شو', 'fa': 'ارسال نشد', 'en': "It didn't go through"},
    'failed_refund': {'ps': 'ستاسو پیسې بېرته ستاسو کارت ته ستونېږي', 'fa': 'پول شما به کارت‌تان برگردانده می‌شود', 'en': 'Your money will be returned to your card'},
    'done_btn': {'ps': 'بشپړ شو', 'fa': 'تمام', 'en': 'Done'},
    'try_again': {'ps': 'بیا هڅه وکړئ', 'fa': 'دوباره تلاش کنید', 'en': 'Try again'},
    'error_generic': {'ps': 'ستونزه رامنځته شوه', 'fa': 'مشکلی پیش آمد', 'en': 'Something went wrong'},
    'invalid_number': {'ps': 'دا شمېره سمه نه ده', 'fa': 'این شماره درست نیست', 'en': 'This number is not valid'},
    'home': {'ps': 'لومړی مخ', 'fa': 'صفحه اصلی', 'en': 'Home'},
    'empty_history': {'ps': 'تر اوسه مو کرېډېټ نه دی لېږلی', 'fa': 'هنوز کریدیتی نفرستاده‌اید', 'en': "You haven't sent any credit yet"},
    'status_delivered': {'ps': 'لېږل شوی', 'fa': 'ارسال شد', 'en': 'Delivered'},
    'status_refunded': {'ps': 'پیسې بېرته ستون شوې', 'fa': 'پول برگردانده شد', 'en': 'Refunded'},
    'status_sending': {'ps': 'لېږل کېږي', 'fa': 'در حال ارسال', 'en': 'Sending'},
    'status_failed': {'ps': 'ناکام شو', 'fa': 'ناموفق', 'en': 'Failed'},
    'status_pending': {'ps': 'انتظار کې', 'fa': 'در انتظار', 'en': 'Waiting'},
    'country_AF': {'ps': 'افغانستان', 'fa': 'افغانستان', 'en': 'Afghanistan'},
    'country_PK': {'ps': 'پاکستان', 'fa': 'پاکستان', 'en': 'Pakistan'},
    'country_IR': {'ps': 'ایران', 'fa': 'ایران', 'en': 'Iran'},
    'country_DE': {'ps': 'المان', 'fa': 'آلمان', 'en': 'Germany'},
    'country_TR': {'ps': 'ترکیه', 'fa': 'ترکیه', 'en': 'Turkey'},
    'country_AE': {'ps': 'امارات', 'fa': 'امارات', 'en': 'UAE'},
    'country_SA': {'ps': 'سعودي عربستان', 'fa': 'عربستان سعودی', 'en': 'Saudi Arabia'},
    'country_US': {'ps': 'امریکا', 'fa': 'آمریکا', 'en': 'USA'},
    'country_GB': {'ps': 'انګلستان', 'fa': 'انگلستان', 'en': 'United Kingdom'},
    'country_FR': {'ps': 'فرانسه', 'fa': 'فرانسه', 'en': 'France'},
    'country_NL': {'ps': 'هالنډ', 'fa': 'هلند', 'en': 'Netherlands'},
    'country_SE': {'ps': 'سویډن', 'fa': 'سوئد', 'en': 'Sweden'},
  };

  static String t(String lang, String key) {
    final row = _table[key];
    if (row == null) return key;
    return row[lang] ?? row['en'] ?? key;
  }

  static Iterable<String> get keys => _table.keys;
  static bool has(String lang, String key) => _table[key]?[lang] != null;
}
