import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/screens/add_class_screen.dart';
import 'package:teachly/screens/main_navigation_screen.dart';
import 'package:teachly/screens/notes_screen.dart';
import 'package:teachly/screens/reminders_screen.dart';
import 'package:teachly/screens/student_group_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyText = Color(0xFF777777);

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // =========================================================
  // ADD CLASS
  // =========================================================

  Future<void> _openAddClass() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddClassScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // FIRESTORE - CLASSES
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _classesStream() {
    final user = _currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('classes')
        .where(
          'userId',
          isEqualTo: user.uid,
        )
        .snapshots();
  }

  // =========================================================
  // FIRESTORE - STUDENTS
  // =========================================================

  CollectionReference<Map<String, dynamic>> _studentsCollection() {
    final user = _currentUser;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('students');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream() {
    final user = _currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _studentsCollection().snapshots();
  }

  // =========================================================
  // TEACHER NAME
  // =========================================================

  Future<String> _getTeacherName() async {
    final user = _currentUser;

    if (user == null) {
      return 'Teacher';
    }

    if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        if (data != null) {
          final possibleNames = [
            data['name'],
            data['fullName'],
            data['displayName'],
            data['username'],
          ];

          for (final value in possibleNames) {
            if (value != null &&
                value.toString().trim().isNotEmpty) {
              return value.toString().trim();
            }
          }
        }
      }
    } catch (_) {}

    if (user.email != null &&
        user.email!.trim().isNotEmpty) {
      final emailName = user.email!.split('@').first;

      if (emailName.isNotEmpty) {
        return emailName;
      }
    }

    return 'Teacher';
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  String _getTodayName() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[DateTime.now().weekday - 1];
  }

  String _getLocalizedDay(
    BuildContext context,
    String englishDay,
  ) {
    final l10n = AppLocalizations.of(context);

    switch (englishDay) {
      case 'Saturday':
        return l10n.saturday;
      case 'Sunday':
        return l10n.sunday;
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      default:
        return englishDay;
    }
  }

  String _getTodayDate(
    BuildContext context,
  ) {
    final now = DateTime.now();

    final isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    if (isArabic) {
      const months = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];

      return '${now.day} ${months[now.month - 1]} ${now.year}';
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // STUDENT SCHEDULE HELPERS
  // =========================================================

  List<Map<String, dynamic>> _getStudentSchedules(
    Map<String, dynamic> data,
  ) {
    final schedules = data['schedules'];

    if (schedules is List && schedules.isNotEmpty) {
      return schedules
          .whereType<Map>()
          .map(
            (schedule) => Map<String, dynamic>.from(schedule),
          )
          .toList();
    }

    // ---------------------------------------------------------
    // OLD DATA SUPPORT
    // ---------------------------------------------------------

    final day = data['day']?.toString() ?? '';

    final startTime = data['startTime']?.toString() ?? '';

    final endTime = data['endTime']?.toString() ?? '';

    if (day.isEmpty ||
        startTime.isEmpty ||
        endTime.isEmpty) {
      return [];
    }

    return [
      {
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
      },
    ];
  }

  int _timeToMinutes(String time) {
    try {
      final parts = time.trim().split(' ');

      final timePart = parts.first;

      final period = parts.length > 1
          ? parts[1].toUpperCase()
          : '';

      final timeParts = timePart.split(':');

      int hour = int.parse(timeParts[0]);

      final int minute = timeParts.length > 1
          ? int.parse(timeParts[1])
          : 0;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  // =========================================================
  // TODAY STUDENT GROUPS
  // =========================================================

  List<_StudentHomeGroup> _getTodayStudentGroups(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String today,
  ) {
    final Map<String, _StudentHomeGroup> groups = {};

    for (final studentDoc in docs) {
      final data = studentDoc.data();

      final studentName =
          data['name']?.toString().trim() ?? '';

      if (studentName.isEmpty) {
        continue;
      }

      final subject =
          data['subject']?.toString() ?? '';

      final grade =
          data['grade']?.toString() ?? '';

      final schedules =
          _getStudentSchedules(data);

      for (final schedule in schedules) {
        final day =
            schedule['day']?.toString() ?? '';

        if (day != today) {
          continue;
        }

        final startTime =
            schedule['startTime']?.toString() ?? '';

        final endTime =
            schedule['endTime']?.toString() ?? '';

        if (startTime.isEmpty ||
            endTime.isEmpty) {
          continue;
        }

        // Same criteria:
        // day + start + end + subject + grade

        final groupKey =
            '$day|$startTime|$endTime|$subject|$grade';

        if (!groups.containsKey(groupKey)) {
          groups[groupKey] = _StudentHomeGroup(
            day: day,
            subject: subject,
            grade: grade,
            startTime: startTime,
            endTime: endTime,
            students: [],
          );
        }

        if (!groups[groupKey]!.students.contains(studentName)) {
          groups[groupKey]!.students.add(studentName);
        }
      }
    }

    final result = groups.values.toList();

    result.sort(
      (a, b) => _timeToMinutes(
        a.startTime,
      ).compareTo(
        _timeToMinutes(
          b.startTime,
        ),
      ),
    );

    return result;
  }

  // =========================================================
  // SUMMARY DATA
  // =========================================================

  Future<Map<String, int>> _getSummaryData() async {
    final user = _currentUser;

    if (user == null) {
      return {
        'students': 0,
        'present': 0,
        'absent': 0,
        'paid': 0,
      };
    }

    try {
      final studentsSnapshot =
          await _studentsCollection().get();

      int presentCount = 0;
      int absentCount = 0;
      int paidCount = 0;

      // =======================================================
      // TODAY DATE KEY
      // =======================================================

      final todayKey = _getDateKey(DateTime.now());

      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;

        // =====================================================
        // ATTENDANCE - TODAY ONLY
        // =====================================================

        try {
          final attendanceDoc = await _studentsCollection()
              .doc(studentId)
              .collection('attendance')
              .doc(todayKey)
              .get();

          if (attendanceDoc.exists) {
            final attendanceData =
                attendanceDoc.data();

            final status =
                attendanceData?['status']
                    ?.toString()
                    .toLowerCase();

            if (status == 'present') {
              presentCount++;
            } else if (status == 'absent') {
              absentCount++;
            }
          }
        } catch (_) {}

        // =====================================================
        // PAYMENT - TODAY ONLY
        // =====================================================

        try {
          final paymentDoc = await _studentsCollection()
              .doc(studentId)
              .collection('payments')
              .doc(todayKey)
              .get();

          if (paymentDoc.exists) {
            final paymentData =
                paymentDoc.data();

            final paid =
                paymentData?['paid'] ??
                    paymentData?['payment'];

            if (paid == true ||
                paid?.toString().toLowerCase() == 'true') {
              paidCount++;
            }
          }
        } catch (_) {}
      }

      return {
        'students': studentsSnapshot.docs.length,
        'present': presentCount,
        'absent': absentCount,
        'paid': paidCount,
      };
    } catch (_) {
      return {
        'students': 0,
        'present': 0,
        'absent': 0,
        'paid': 0,
      };
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: primaryGreen,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: lightGreen,
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildTodayClasses(),

                  const SizedBox(height: 22),

                  _buildQuickActions(context),

                  const SizedBox(height: 22),

                  _buildSummary(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          const TeachlyBottomNavigation(),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    final l10n =
        AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 14,
        18,
        22,
      ),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  return GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 27,
                    ),
                  );
                },
              ),

              const Spacer(),

              FutureBuilder<String>(
                future: _getTeacherName(),
                builder: (context, snapshot) {
                  return const Text(
                    'Teachly 📖',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),

              const Spacer(),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                  Positioned(
                    right: 0,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration:
                          const BoxDecoration(
                        color: Color(0xFFFF4D4D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const CircleAvatar(
                  backgroundColor: Color(0xFFE5E5E5),
                  child: Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: FutureBuilder<String>(
                  future: _getTeacherName(),
                  builder: (context, snapshot) {
                    final name =
                        snapshot.data ?? 'Teacher';

                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.welcomeBack,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '$name 👋',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DRAWER
  // =========================================================

  Widget _buildDrawer() {
    final l10n =
        AppLocalizations.of(context);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                24,
              ),
              decoration: const BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft:
                      Radius.circular(24),
                  bottomRight:
                      Radius.circular(24),
                ),
              ),
              child: FutureBuilder<String>(
                future: _getTeacherName(),
                builder: (context, snapshot) {
                  final name =
                      snapshot.data ?? 'Teacher';

                  return Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const CircleAvatar(
                          backgroundColor:
                              Color(0xFFE5E5E5),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey,
                            size: 31,
                          ),
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Teachly',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            _buildDrawerItem(
              icon: Icons.home_rounded,
              title: l10n.home,
              index: 0,
            ),

            _buildDrawerItem(
              icon: Icons.calendar_month_outlined,
              title: l10n.schedule,
              index: 1,
            ),

            _buildDrawerItem(
              icon: Icons.groups_outlined,
              title: l10n.studentList,
              index: 2,
            ),

            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: l10n.settings,
              index: 3,
            ),

            const Spacer(),

            const Divider(
              color: Color(0xFFEAEAEA),
              indent: 20,
              endIndent: 20,
            ),

            Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 15,
              ),
              child: _buildDrawerItem(
                icon: Icons.close_rounded,
                title: l10n.close,
                index: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final navigation =
        TeachlyNavigation.of(context);

    final selected =
        navigation.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: selected
            ? softGreen
            : null,
        leading: Icon(
          icon,
          color: selected
              ? primaryGreen
              : greyText,
          size: 23,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected
                ? primaryGreen
                : textColor,
            fontSize: 14,
            fontWeight: selected
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);

          if (index >= 0) {
            navigation.onTabChanged(index);
          }
        },
      ),
    );
  }

  // =========================================================
  // TODAY'S CLASSES
  // =========================================================

  Widget _buildTodayClasses() {
    final l10n =
        AppLocalizations.of(context);

    final today =
        _getTodayName();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.todayClasses,
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: textColor,
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTap: () {
                TeachlyNavigation.of(context)
                    .onTabChanged(1);
              },
              child: Text(
                l10n.viewSchedule,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          '▦ ${_getLocalizedDay(context, today)}, '
          '${_getTodayDate(context)}',
          style: const TextStyle(
            color: greyText,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 13),

        StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _classesStream(),
          builder:
              (context, classSnapshot) {
            if (classSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child:
                      CircularProgressIndicator(
                    color: primaryGreen,
                  ),
                ),
              );
            }

            if (classSnapshot.hasError) {
              return _buildEmptyClasses(
                l10n.error,
              );
            }

            final classDocs =
                classSnapshot.data?.docs ?? [];

            return StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _studentsStream(),
              builder: (
                context,
                studentSnapshot,
              ) {
                if (studentSnapshot
                        .connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.all(20),
                      child:
                          CircularProgressIndicator(
                        color:
                            primaryGreen,
                      ),
                    ),
                  );
                }

                if (studentSnapshot.hasError) {
                  return _buildEmptyClasses(
                    l10n.error,
                  );
                }

                final studentDocs =
                    studentSnapshot.data?.docs ?? [];

                // =================================================
                // NORMAL CLASSES
                // =================================================

                final todayClasses =
                    classDocs.where(
                  (doc) {
                    final data =
                        doc.data();

                    return data['day'] ==
                        today;
                  },
                ).toList();

                todayClasses.sort(
                  (a, b) {
                    final aTime =
                        (a.data()['startMinutes']
                                as num?)
                            ?.toInt() ??
                            _timeToMinutes(
                              a.data()['startTime']
                                      ?.toString() ??
                                  '',
                            );

                    final bTime =
                        (b.data()['startMinutes']
                                as num?)
                            ?.toInt() ??
                            _timeToMinutes(
                              b.data()['startTime']
                                      ?.toString() ??
                                  '',
                            );

                    return aTime.compareTo(
                      bTime,
                    );
                  },
                );

                // =================================================
                // STUDENT GROUPS
                // =================================================

                final studentGroups =
                    _getTodayStudentGroups(
                  studentDocs,
                  today,
                );

                // =================================================
                // COMBINED TIMELINE
                // =================================================

                final List<_HomeScheduleItem>
                    items = [];

                for (final doc in todayClasses) {
                  final data = doc.data();

                  final startTime =
                      data['startTime']
                              ?.toString() ??
                          '';

                  final startMinutes =
                      (data['startMinutes']
                              as num?)
                          ?.toInt() ??
                          _timeToMinutes(
                            startTime,
                          );

                  items.add(
                    _HomeScheduleItem.classItem(
                      data: data,
                      startMinutes:
                          startMinutes,
                    ),
                  );
                }

                for (final group in studentGroups) {
                  items.add(
                    _HomeScheduleItem.studentGroup(
                      group: group,
                      startMinutes:
                          _timeToMinutes(
                        group.startTime,
                      ),
                    ),
                  );
                }

                items.sort(
                  (a, b) =>
                      a.startMinutes.compareTo(
                    b.startMinutes,
                  ),
                );

                if (items.isEmpty) {
                  return _buildEmptyClasses(
                    l10n.noClassesToday,
                  );
                }

                return Column(
                  children: [
                    for (
                      int i = 0;
                      i < items.length;
                      i++
                    ) ...[
                      if (items[i].isStudentGroup)
                        _buildStudentGroupCard(
                          items[i].studentGroup!,
                        )
                      else
                        _buildFirestoreClassCard(
                          items[i].classData!,
                        ),

                      if (i != items.length - 1)
                        const SizedBox(
                          height: 11,
                        ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  // =========================================================
  // STUDENT GROUP CARD
  // =========================================================

  Widget _buildStudentGroupCard(
    _StudentHomeGroup group,
  ) {
    final studentCount =
        group.students.length;

    String time =
        group.startTime;

    String period = '';

    if (group.startTime.contains(' ')) {
      final parts =
          group.startTime.split(' ');

      time = parts[0];

      if (parts.length > 1) {
        period = parts[1];
      }
    }

    final duration =
        '${group.startTime} - ${group.endTime}';

    final studentsText =
        studentCount == 1
            ? '1 Student'
            : '$studentCount Students';

    // =========================================================
    // CLICKABLE STUDENT GROUP
    // =========================================================

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentGroupScreen(
              day: group.day,
              startTime: group.startTime,
              endTime: group.endTime,
              subject: group.subject,
              grade: group.grade,
            ),
          ),
        );
      },
      child: _buildClassCard(
        time: time,
        period: period,
        subject: group.subject.isEmpty
            ? 'Student Class'
            : group.subject,
        grade: group.grade,
        room: studentsText,
        duration: duration,
      ),
    );
  }

  // =========================================================
  // EMPTY CLASSES
  // =========================================================

  Widget _buildEmptyClasses(
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 25,
        horizontal: 15,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: primaryGreen,
            size: 30,
          ),

          const SizedBox(height: 8),

          Text(
            message,
            style: const TextStyle(
              color: greyText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FIRESTORE CLASS CARD
  // =========================================================

  Widget _buildFirestoreClassCard(
    Map<String, dynamic> data,
  ) {
    final l10n =
        AppLocalizations.of(context);

    final subject =
        data['subject'] ?? l10n.subject;

    final grade =
        data['grade'] ?? '';

    final room =
        data['room'] ?? '';

    final startTime =
        data['startTime'] ?? '';

    final endTime =
        data['endTime'] ?? '';

    String time =
        startTime.toString();

    String period = '';

    if (startTime.toString().contains(' ')) {
      final parts =
          startTime.toString().split(' ');

      time = parts[0];

      if (parts.length > 1) {
        period = parts[1];
      }
    }

    final duration =
        '$startTime - $endTime';

    final roomText =
        room.toString().isEmpty
            ? l10n.room
            : '${l10n.room} ${room.toString()}';

    return _buildClassCard(
      time: time,
      period: period,
      subject: subject.toString(),
      grade: grade.toString(),
      room: roomText,
      duration: duration,
    );
  }

  // =========================================================
  // CLASS CARD
  // =========================================================

  Widget _buildClassCard({
    required String time,
    required String period,
    required String subject,
    required String grade,
    required String room,
    required String duration,
  }) {
    return Container(
      width: double.infinity,
      height: 82,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style:
                      const TextStyle(
                    color:
                        primaryGreen,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style:
                      const TextStyle(
                    color:
                        primaryGreen,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 7),

          Container(
            width: 1,
            height: 48,
            color:
                const Color(0xFFE7E7E7),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        textColor,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  grade,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        greyText,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      color: greyText,
                      size: 13,
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    Expanded(
                      child: Text(
                        duration,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              greyText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Container(
            constraints:
                const BoxConstraints(
              maxWidth: 78,
            ),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration:
                BoxDecoration(
              color: softGreen,
              borderRadius:
                  BorderRadius.circular(
                7,
              ),
            ),
            child: Text(
              room,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    primaryGreen,
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // QUICK ACTIONS
  // =========================================================

  Widget _buildQuickActions(
    BuildContext context,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style:
              TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color: textColor,
          ),
        ),

        const SizedBox(height: 11),

        Row(
          children: [
            Expanded(
              child:
                  _buildActionCard(
                icon: Icons.add,
                title: l10n.addClass,
                onTap:
                    _openAddClass,
              ),
            ),

            const SizedBox(
                width: 11),

            Expanded(
              child:
                  _buildActionCard(
                icon:
                    Icons
                        .edit_note_rounded,
                title: l10n.notes,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const NotesScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(
                width: 11),

            Expanded(
              child:
                  _buildActionCard(
                icon:
                    Icons
                        .notifications_none_rounded,
                title:
                    l10n.classReminders,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const RemindersScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(
                color: softGreen,
                borderRadius:
                    BorderRadius.circular(
                  9,
                ),
              ),
              child: Icon(
                icon,
                color:
                    primaryGreen,
                size: 21,
              ),
            ),

            const SizedBox(
                height: 8),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
                color:
                    textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummary() {
    final l10n =
        AppLocalizations.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          l10n.total,
          style:
              const TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color: textColor,
          ),
        ),

        const SizedBox(
            height: 11),

        FutureBuilder<Map<String, int>>(
          future: _getSummaryData(),
          builder:
              (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return Row(
                children: [
                  _buildLoadingSummaryCard(),
                  const SizedBox(
                      width: 8),
                  _buildLoadingSummaryCard(),
                  const SizedBox(
                      width: 8),
                  _buildLoadingSummaryCard(),
                  const SizedBox(
                      width: 8),
                  _buildLoadingSummaryCard(),
                ],
              );
            }

            final data =
                snapshot.data ??
                    {
                      'students': 0,
                      'present': 0,
                      'absent': 0,
                      'paid': 0,
                    };

            return Row(
              children: [
                _buildSummaryCard(
                  number:
                      '${data['students'] ?? 0}',
                  title: l10n.total,
                ),

                const SizedBox(
                    width: 8),

                _buildSummaryCard(
                  number:
                      '${data['present'] ?? 0}',
                  title:
                      l10n.present,
                ),

                const SizedBox(
                    width: 8),

                _buildSummaryCard(
                  number:
                      '${data['absent'] ?? 0}',
                  title:
                      l10n.absent,
                ),

                const SizedBox(
                    width: 8),

                _buildSummaryCard(
                  number:
                      '${data['paid'] ?? 0}',
                  title:
                      l10n.paid,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingSummaryCard() {
    return Expanded(
      child: Container(
        height: 72,
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  primaryGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String number,
    required String title,
  }) {
    return Expanded(
      child: Container(
        height: 72,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              number,
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color:
                    textColor,
              ),
            ),

            const SizedBox(
                height: 4),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              maxLines: 2,
              style:
                  const TextStyle(
                fontSize: 9,
                color:
                    greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// STUDENT HOME GROUP
// =============================================================

class _StudentHomeGroup {
  final String day;
  final String subject;
  final String grade;
  final String startTime;
  final String endTime;
  final List<String> students;

  _StudentHomeGroup({
    required this.day,
    required this.subject,
    required this.grade,
    required this.startTime,
    required this.endTime,
    required this.students,
  });
}

// =============================================================
// HOME SCHEDULE ITEM
// =============================================================

class _HomeScheduleItem {
  final bool isStudentGroup;
  final Map<String, dynamic>? classData;
  final _StudentHomeGroup? studentGroup;
  final int startMinutes;

  _HomeScheduleItem.classItem({
    required Map<String, dynamic> data,
    required this.startMinutes,
  })  : isStudentGroup = false,
        classData = data,
        studentGroup = null;

  _HomeScheduleItem.studentGroup({
    required _StudentHomeGroup group,
    required this.startMinutes,
  })  : isStudentGroup = true,
        classData = null,
        studentGroup = group;
}