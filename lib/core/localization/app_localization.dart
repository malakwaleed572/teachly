import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _translations = {
    // ============================================================
    // ENGLISH
    // ============================================================
    'en': {
      // Navigation
      'home': 'Home',
      'schedule': 'Schedule',
      'studentList': 'Student List',
      'settings': 'Settings',

      // Home
      'todayClasses': "Today's Classes",
      'addClass': 'Add Class',
      'addStudent': 'Add Student',
      'students': 'Students',
      'total': 'TOTAL',
      'groups': 'GROUPS',
      'noClassesToday': 'No classes today',
      'noStudents': 'No students yet',
      'viewSchedule': 'View Schedule',
      'viewStudents': 'View Students',

      // Months
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',
      // Settings
      'personalInformation': 'Personal Information',
      'changePassword': 'Change Password',
      'notificationPreferences': 'Notification Preferences',
      'appSettings': 'APP SETTINGS',
      'language': 'Language',
      'english': 'English',
      'arabic': 'Arabic',

      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'close': 'Close',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'update': 'Update',
      'done': 'Done',
      'back': 'Back',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',

      // User
      'name': 'Name',
      'email': 'Email',
      'phone': 'Phone',
      'user': 'User',
      'noEmail': 'No email',

      // Logout
      'logout': 'Log Out',
      'areYouSureLogout': 'Are you sure you want to log out?',

      // Password
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'forgotPassword': 'Forgot Password?',
      'changePasswordTitle': 'Change Password',
      'passwordResetEmail': 'A password reset email will be sent to:',
      'passwordResetInstructions':
          'Open the email and follow the instructions to create a new password.',
      'sendEmail': 'Send Email',
      'passwordResetSent': 'Password reset email sent successfully.',

      // Notifications
      'classReminders': 'Class Reminders',
      'generalNotifications': 'General Notifications',
      'classReminderDescription': 'Receive reminders for your classes',
      'generalNotificationDescription': 'Receive general app notifications',
      'notificationsSaved': 'Notification preferences saved.',

      // Messages
      'languageSaved': 'Language saved successfully.',
      'personalInfoSaved': 'Personal information updated successfully.',
      'emailCannotChange': 'Email cannot be changed from here.',
      'enterName': 'Enter your name',
      'pleaseEnterName': 'Please enter your name.',
      'noAccount': 'No account was found with this email.',
      'invalidEmail': 'The email address is invalid.',
      'somethingWentWrong': 'Something went wrong.',
      'deletedSuccessfully': 'Deleted successfully.',
      'savedSuccessfully': 'Saved successfully.',

      // Classes
      'class': 'Class',
      'classes': 'Classes',
      'subject': 'Subject',
      'grade': 'Grade',
      'room': 'Room',
      'note': 'Note',
      'notes': 'Notes',
      'day': 'Day',
      'startTime': 'Start Time',
      'endTime': 'End Time',
      'time': 'Time',
      'addNewClass': 'Add New Class',
      'editClass': 'Edit Class',
      'saveClass': 'Save Class',
      'updateClass': 'Update Class',
      'deleteClass': 'Delete Class',
      'classDetails': 'Class Details',
      'noClasses': 'No classes found.',

      // Subjects
      'math': 'Math',
      'science': 'Science',
      'arabicSubject': 'Arabic',
      'englishSubject': 'English',

      // Grades
      'grade1': 'Grade 1',
      'grade2': 'Grade 2',
      'grade3': 'Grade 3',
      'grade4': 'Grade 4',
      'grade5': 'Grade 5',
      'grade6': 'Grade 6',
      'grade7': 'Grade 7',
      'grade8': 'Grade 8',
      'grade9': 'Grade 9',
      'grade10': 'Grade 10',
      'grade11': 'Grade 11',
      'grade12': 'Grade 12',

      // Days
      'saturday': 'Saturday',
      'sunday': 'Sunday',
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',

      // Students
      'student': 'Student',
      'studentName': 'Student Name',
      'parentName': 'Parent Name',
      'parentPhone': 'Parent Phone',
      'addNewStudent': 'Add New Student',
      'editStudent': 'Edit Student',
      'saveStudent': 'Save Student',
      'updateStudent': 'Update Student',
      'deleteStudent': 'Delete Student',
      'studentDetails': 'Student Details',
      'noStudentsFound': 'No students found.',
      'selectGrade': 'Select Grade',
      'selectSubject': 'Select Subject',

      // Attendance
      'attendance': 'Attendance',
      'present': 'Present',
      'absent': 'Absent',
      'notMarked': 'Not Marked',

      // Payment
      'payment': 'Payment',
      'paid': 'Paid',
      'notPaid': 'Not Paid',

      // Groups
      'allStudents': 'All Students',
      'group': 'Group',
      'selectGroup': 'Select Group',

      // Schedule
      'mySchedule': 'My Schedule',
      'monthlySchedule': 'Monthly Schedule',
      'previousMonth': 'Previous Month',
      'nextMonth': 'Next Month',

      // Authentication
      'login': 'Login',
      'signup': 'Sign Up',
      'signIn': 'Sign In',
      'createAccount': 'Create Account',
      'welcomeBack': 'Welcome Back',
      'welcomeToTeachly': 'Welcome to Teachly',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'enterEmail': 'Enter your email',
      'enterPassword': 'Enter your password',
      'enterPhone': 'Enter your phone number',
      'noNotes': 'No notes yet',
'addNote': 'Add Note',
'editNote': 'Edit Note',
'noteTitle': 'Title',
'noteContent': 'Content',
'enterNoteTitle': 'Enter note title',
'enterNoteContent': 'Enter note content',
'noReminders': 'No reminders yet',
'addReminder': 'Add Reminder',
'editReminder': 'Edit Reminder',
'reminderTitle': 'Title',
'reminderDescription': 'Description',
'reminderDate': 'Date',
'reminderTime': 'Time',
'selectReminderDate': 'Select reminder date',
'selectReminderTime': 'Select reminder time',
'selectReminderDateTime': 'Please select date and time',
'enterReminderTitle': 'Enter reminder title',
'enterReminderDescription': 'Enter reminder description',
    },

    // ============================================================
    // ARABIC
    // ============================================================
    'ar': {
      // Navigation
      'home': 'الرئيسية',
      'schedule': 'الجدول',
      'studentList': 'قائمة الطلاب',
      'settings': 'الإعدادات',

      // Home
      'todayClasses': 'حصص اليوم',
      'addClass': 'إضافة حصة',
      'addStudent': 'إضافة طالب',
      'students': 'الطلاب',
      'total': 'الإجمالي',
      'groups': 'المجموعات',
      'noClassesToday': 'لا توجد حصص اليوم',
      'noStudents': 'لا يوجد طلاب حتى الآن',
      'viewSchedule': 'عرض الجدول',
      'viewStudents': 'عرض الطلاب',

      // Months
      'january': 'يناير',
      'february': 'فبراير',
      'march': 'مارس',
      'april': 'أبريل',
      'may': 'مايو',
      'june': 'يونيو',
      'july': 'يوليو',
      'august': 'أغسطس',
      'september': 'سبتمبر',
      'october': 'أكتوبر',
      'november': 'نوفمبر',
      'december': 'ديسمبر',
      // Settings
      'personalInformation': 'المعلومات الشخصية',
      'changePassword': 'تغيير كلمة المرور',
      'notificationPreferences': 'إعدادات الإشعارات',
      'appSettings': 'إعدادات التطبيق',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'arabic': 'العربية',

      // Common
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'close': 'إغلاق',
      'delete': 'حذف',
      'edit': 'تعديل',
      'add': 'إضافة',
      'update': 'تحديث',
      'done': 'تم',
      'back': 'رجوع',
      'confirm': 'تأكيد',
      'yes': 'نعم',
      'no': 'لا',
      'search': 'بحث',
      'loading': 'جاري التحميل...',
      'error': 'خطأ',
      'retry': 'إعادة المحاولة',

      // User
      'name': 'الاسم',
      'email': 'البريد الإلكتروني',
      'phone': 'رقم الهاتف',
      'user': 'مستخدم',
      'noEmail': 'لا يوجد بريد إلكتروني',

      // Logout
      'logout': 'تسجيل الخروج',
      'areYouSureLogout': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',

      // Password
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'changePasswordTitle': 'تغيير كلمة المرور',
      'passwordResetEmail': 'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى:',
      'passwordResetInstructions':
          'افتح البريد الإلكتروني واتبع التعليمات لإنشاء كلمة مرور جديدة.',
      'sendEmail': 'إرسال البريد',
      'passwordResetSent': 'تم إرسال رابط إعادة تعيين كلمة المرور بنجاح.',

      // Notifications
      'classReminders': 'تذكيرات الحصص',
      'generalNotifications': 'الإشعارات العامة',
      'classReminderDescription': 'استقبال تذكيرات الحصص',
      'generalNotificationDescription': 'استقبال الإشعارات العامة للتطبيق',
      'notificationsSaved': 'تم حفظ إعدادات الإشعارات.',

      // Messages
      'languageSaved': 'تم حفظ اللغة بنجاح.',
      'personalInfoSaved': 'تم تحديث المعلومات الشخصية بنجاح.',
      'emailCannotChange': 'لا يمكن تغيير البريد الإلكتروني من هنا.',
      'enterName': 'أدخل اسمك',
      'pleaseEnterName': 'من فضلك أدخل اسمك.',
      'noAccount': 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني.',
      'invalidEmail': 'البريد الإلكتروني غير صالح.',
      'somethingWentWrong': 'حدث خطأ ما.',
      'deletedSuccessfully': 'تم الحذف بنجاح.',
      'savedSuccessfully': 'تم الحفظ بنجاح.',

      // Classes
      'class': 'الحصة',
      'classes': 'الحصص',
      'subject': 'المادة',
      'grade': 'الصف',
      'room': 'الغرفة',
      'note': 'ملاحظة',
      'notes': 'ملاحظات',
      'day': 'اليوم',
      'startTime': 'وقت البداية',
      'endTime': 'وقت النهاية',
      'time': 'الوقت',
      'addNewClass': 'إضافة حصة جديدة',
      'editClass': 'تعديل الحصة',
      'saveClass': 'حفظ الحصة',
      'updateClass': 'تحديث الحصة',
      'deleteClass': 'حذف الحصة',
      'classDetails': 'تفاصيل الحصة',
      'noClasses': 'لا توجد حصص.',

      // Subjects
      'math': 'رياضيات',
      'science': 'علوم',
      'arabicSubject': 'لغة عربية',
      'englishSubject': 'لغة إنجليزية',

      // Grades
      'grade1': 'الصف الأول',
      'grade2': 'الصف الثاني',
      'grade3': 'الصف الثالث',
      'grade4': 'الصف الرابع',
      'grade5': 'الصف الخامس',
      'grade6': 'الصف السادس',
      'grade7': 'الصف السابع',
      'grade8': 'الصف الثامن',
      'grade9': 'الصف التاسع',
      'grade10': 'الصف العاشر',
      'grade11': 'الصف الحادي عشر',
      'grade12': 'الصف الثاني عشر',

      // Days
      'saturday': 'السبت',
      'sunday': 'الأحد',
      'monday': 'الاثنين',
      'tuesday': 'الثلاثاء',
      'wednesday': 'الأربعاء',
      'thursday': 'الخميس',
      'friday': 'الجمعة',

      // Students
      'student': 'طالب',
      'studentName': 'اسم الطالب',
      'parentName': 'اسم ولي الأمر',
      'parentPhone': 'رقم هاتف ولي الأمر',
      'addNewStudent': 'إضافة طالب جديد',
      'editStudent': 'تعديل الطالب',
      'saveStudent': 'حفظ الطالب',
      'updateStudent': 'تحديث الطالب',
      'deleteStudent': 'حذف الطالب',
      'studentDetails': 'بيانات الطالب',
      'noStudentsFound': 'لا يوجد طلاب.',
      'selectGrade': 'اختر الصف',
      'selectSubject': 'اختر المادة',

      // Attendance
      'attendance': 'الحضور',
      'present': 'حاضر',
      'absent': 'غائب',
      'notMarked': 'لم يتم التحديد',

      // Payment
      'payment': 'الدفع',
      'paid': 'مدفوع',
      'notPaid': 'غير مدفوع',

      // Groups
      'allStudents': 'كل الطلاب',
      'group': 'المجموعة',
      'selectGroup': 'اختر المجموعة',

      // Schedule
      'mySchedule': 'جدولي',
      'monthlySchedule': 'الجدول الشهري',
      'previousMonth': 'الشهر السابق',
      'nextMonth': 'الشهر التالي',

      // Authentication
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'signIn': 'دخول',
      'createAccount': 'إنشاء حساب',
      'welcomeBack': 'مرحبًا بعودتك',
      'welcomeToTeachly': 'مرحبًا بك في Teachly',
      'dontHaveAccount': 'ليس لديك حساب؟',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',
      'enterEmail': 'أدخل بريدك الإلكتروني',
      'enterPassword': 'أدخل كلمة المرور',
      'enterPhone': 'أدخل رقم هاتفك',
      'noNotes': 'لا توجد ملاحظات حتى الآن',
'addNote': 'إضافة ملاحظة',
'editNote': 'تعديل الملاحظة',
'noteTitle': 'العنوان',
'noteContent': 'المحتوى',
'enterNoteTitle': 'أدخل عنوان الملاحظة',
'enterNoteContent': 'أدخل محتوى الملاحظة',
'noReminders': 'لا توجد تذكيرات حتى الآن',
'addReminder': 'إضافة تذكير',
'editReminder': 'تعديل التذكير',
'reminderTitle': 'العنوان',
'reminderDescription': 'الوصف',
'reminderDate': 'التاريخ',
'reminderTime': 'الوقت',
'selectReminderDate': 'اختر تاريخ التذكير',
'selectReminderTime': 'اختر وقت التذكير',
'selectReminderDateTime': 'من فضلك اختر التاريخ والوقت',
'enterReminderTitle': 'أدخل عنوان التذكير',
'enterReminderDescription': 'أدخل وصف التذكير',
    },
  };

  String translate(String key) {
    final languageCode = locale.languageCode;

    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  // Navigation
  String get home => translate('home');
  String get schedule => translate('schedule');
  String get studentList => translate('studentList');
  String get settings => translate('settings');

  // Home
  String get todayClasses => translate('todayClasses');
  String get addClass => translate('addClass');
  String get addStudent => translate('addStudent');
  String get students => translate('students');
  String get total => translate('total');
  String get groups => translate('groups');
  String get noClassesToday => translate('noClassesToday');
  String get noStudents => translate('noStudents');
  String get viewSchedule => translate('viewSchedule');
  String get viewStudents => translate('viewStudents');

  // Settings
  String get personalInformation => translate('personalInformation');

  String get changePassword => translate('changePassword');

  String get notificationPreferences => translate('notificationPreferences');

  String get appSettings => translate('appSettings');

  String get language => translate('language');

  String get english => translate('english');

  String get arabic => translate('arabic');

  // Common
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get close => translate('close');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get update => translate('update');
  String get done => translate('done');
  String get back => translate('back');
  String get confirm => translate('confirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');

  // User
  String get name => translate('name');
  String get email => translate('email');
  String get phone => translate('phone');
  String get user => translate('user');
  String get noEmail => translate('noEmail');

  // Logout
  String get logout => translate('logout');

  String get areYouSureLogout => translate('areYouSureLogout');

  // Password
  String get password => translate('password');

  String get confirmPassword => translate('confirmPassword');

  String get forgotPassword => translate('forgotPassword');

  String get changePasswordTitle => translate('changePasswordTitle');

  String get passwordResetEmail => translate('passwordResetEmail');

  String get passwordResetInstructions =>
      translate('passwordResetInstructions');

  String get sendEmail => translate('sendEmail');

  String get passwordResetSent => translate('passwordResetSent');

  // Notifications
  String get classReminders => translate('classReminders');

  String get generalNotifications => translate('generalNotifications');

  String get classReminderDescription => translate('classReminderDescription');

  String get generalNotificationDescription =>
      translate('generalNotificationDescription');

  String get notificationsSaved => translate('notificationsSaved');

  // Messages
  String get languageSaved => translate('languageSaved');

  String get personalInfoSaved => translate('personalInfoSaved');

  String get emailCannotChange => translate('emailCannotChange');

  String get enterName => translate('enterName');

  String get pleaseEnterName => translate('pleaseEnterName');

  String get noAccount => translate('noAccount');

  String get invalidEmail => translate('invalidEmail');

  String get somethingWentWrong => translate('somethingWentWrong');

  String get deletedSuccessfully => translate('deletedSuccessfully');

  String get savedSuccessfully => translate('savedSuccessfully');

  // Classes
  String get className => translate('class');

  String get classes => translate('classes');

  String get subject => translate('subject');

  String get grade => translate('grade');

  String get room => translate('room');

  String get note => translate('note');

  String get notes => translate('notes');

  String get day => translate('day');

  String get startTime => translate('startTime');

  String get endTime => translate('endTime');

  String get time => translate('time');

  String get addNewClass => translate('addNewClass');

  String get editClass => translate('editClass');

  String get saveClass => translate('saveClass');

  String get updateClass => translate('updateClass');

  String get deleteClass => translate('deleteClass');

  String get classDetails => translate('classDetails');

  String get noClasses => translate('noClasses');

  // Subjects
  String get math => translate('math');

  String get science => translate('science');

  String get arabicSubject => translate('arabicSubject');

  String get englishSubject => translate('englishSubject');

  // Grades
  String get grade1 => translate('grade1');

  String get grade2 => translate('grade2');

  String get grade3 => translate('grade3');

  String get grade4 => translate('grade4');

  String get grade5 => translate('grade5');

  String get grade6 => translate('grade6');

  String get grade7 => translate('grade7');

  String get grade8 => translate('grade8');

  String get grade9 => translate('grade9');

  String get grade10 => translate('grade10');

  String get grade11 => translate('grade11');

  String get grade12 => translate('grade12');

  // Days
  String get saturday => translate('saturday');

  String get sunday => translate('sunday');

  String get monday => translate('monday');

  String get tuesday => translate('tuesday');

  String get wednesday => translate('wednesday');

  String get thursday => translate('thursday');

  String get friday => translate('friday');

  // Students
  String get student => translate('student');

  String get studentName => translate('studentName');

  String get parentName => translate('parentName');

  String get parentPhone => translate('parentPhone');

  String get addNewStudent => translate('addNewStudent');

  String get editStudent => translate('editStudent');

  String get saveStudent => translate('saveStudent');

  String get updateStudent => translate('updateStudent');

  String get deleteStudent => translate('deleteStudent');

  String get studentDetails => translate('studentDetails');

  String get noStudentsFound => translate('noStudentsFound');

  String get selectGrade => translate('selectGrade');

  String get selectSubject => translate('selectSubject');

  // Attendance
  String get attendance => translate('attendance');

  String get present => translate('present');

  String get absent => translate('absent');

  String get notMarked => translate('notMarked');

  // Payment
  String get payment => translate('payment');

  String get paid => translate('paid');

  String get notPaid => translate('notPaid');

  // Groups
  String get allStudents => translate('allStudents');

  String get group => translate('group');

  String get selectGroup => translate('selectGroup');

  // Schedule
  String get mySchedule => translate('mySchedule');

  String get monthlySchedule => translate('monthlySchedule');

  String get previousMonth => translate('previousMonth');

  String get nextMonth => translate('nextMonth');

// Months
String get january =>
    translate('january');

String get february =>
    translate('february');

String get march =>
    translate('march');

String get april =>
    translate('april');

String get may =>
    translate('may');

String get june =>
    translate('june');

String get july =>
    translate('july');

String get august =>
    translate('august');

String get september =>
    translate('september');

String get october =>
    translate('october');

String get november =>
    translate('november');

String get december =>
    translate('december');
  // Authentication
  String get login => translate('login');

  String get signup => translate('signup');

  String get signIn => translate('signIn');

  String get createAccount => translate('createAccount');

  String get welcomeBack => translate('welcomeBack');

  String get welcomeToTeachly => translate('welcomeToTeachly');

  String get dontHaveAccount => translate('dontHaveAccount');

  String get alreadyHaveAccount => translate('alreadyHaveAccount');

  String get enterEmail => translate('enterEmail');

  String get enterPassword => translate('enterPassword');

  String get enterPhone => translate('enterPhone');
  String get noNotes => translate('noNotes');
String get addNote => translate('addNote');
String get editNote => translate('editNote');
String get noteTitle => translate('noteTitle');
String get noteContent => translate('noteContent');
String get enterNoteTitle => translate('enterNoteTitle');
String get enterNoteContent => translate('enterNoteContent');
String get noReminders => translate('noReminders');
String get addReminder => translate('addReminder');
String get editReminder => translate('editReminder');
String get reminderTitle => translate('reminderTitle');
String get reminderDescription => translate('reminderDescription');
String get reminderDate => translate('reminderDate');
String get reminderTime => translate('reminderTime');
String get selectReminderDate => translate('selectReminderDate');
String get selectReminderTime => translate('selectReminderTime');
String get selectReminderDateTime => translate('selectReminderDateTime');
String get enterReminderTitle => translate('enterReminderTitle');
String get enterReminderDescription =>
    translate('enterReminderDescription');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) {
    return false;
  }
}
