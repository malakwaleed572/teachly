import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/core/notifications/notification_service.dart';
import 'package:teachly/screens/main_navigation_screen.dart';

import 'add_class_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyText = Color(0xFF777777);

  DateTime selectedDate = DateTime.now();

  DateTime displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  final ScrollController _daysScrollController =
      ScrollController();

  AppLocalizations get l10n =>
      AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    selectedDate = DateTime.now();

    displayedMonth = DateTime(
      selectedDate.year,
      selectedDate.month,
      1,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay();
    });
  }

  @override
  void dispose() {
    _daysScrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  int _daysInMonth(DateTime month) {
    return DateTime(
      month.year,
      month.month + 1,
      0,
    ).day;
  }

  String _getMonthName(int month) {
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

    return months[month - 1];
  }

  String _getDayShortName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  String _getFirestoreDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getLocalizedFullDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return l10n.monday;
      case DateTime.tuesday:
        return l10n.tuesday;
      case DateTime.wednesday:
        return l10n.wednesday;
      case DateTime.thursday:
        return l10n.thursday;
      case DateTime.friday:
        return l10n.friday;
      case DateTime.saturday:
        return l10n.saturday;
      case DateTime.sunday:
        return l10n.sunday;
      default:
        return '';
    }
  }

  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // =========================================================
  // NOTIFICATION HELPER
  // =========================================================

  int _notificationId(String classId) {
    return classId.hashCode & 0x7fffffff;
  }

  // =========================================================
  // MONTH NAVIGATION
  // =========================================================

  void _goToPreviousMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month - 1,
        1,
      );

      selectedDate = DateTime(
        displayedMonth.year,
        displayedMonth.month,
        1,
      );
    });

    _scrollToStart();
  }

  void _goToNextMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + 1,
        1,
      );

      selectedDate = DateTime(
        displayedMonth.year,
        displayedMonth.month,
        1,
      );
    });

    _scrollToStart();
  }

  void _scrollToSelectedDay() {
    if (!_daysScrollController.hasClients) {
      return;
    }

    final dayIndex = selectedDate.day - 1;

    const double itemWidth = 72;

    final targetOffset = dayIndex * itemWidth;

    final maxScroll =
        _daysScrollController.position.maxScrollExtent;

    _daysScrollController.animateTo(
      targetOffset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _scrollToStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_daysScrollController.hasClients) {
        return;
      }

      _daysScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // =========================================================
  // FIRESTORE - NORMAL CLASSES
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _classesStream() {
    final user = FirebaseAuth.instance.currentUser;

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

  Stream<QuerySnapshot<Map<String, dynamic>>> _studentsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .orderBy('name')
        .snapshots();
  }

  // =========================================================
  // CHECK NORMAL CLASS DATE
  // =========================================================

  bool _classBelongsToSelectedDate(
    Map<String, dynamic> data,
  ) {
    final selectedDateKey =
        _formatDateKey(selectedDate);

    final selectedDay =
        _getFirestoreDayName(selectedDate);

    final savedDateKey =
        data['dateKey']?.toString().trim();

    final savedDay =
        data['day']?.toString().trim();

    final dateMatches =
        savedDateKey != null &&
        savedDateKey.isNotEmpty &&
        savedDateKey == selectedDateKey;

    final dayMatches =
        savedDay != null &&
        savedDay.isNotEmpty &&
        savedDay == selectedDay;

    return dateMatches || dayMatches;
  }

  // =========================================================
  // STUDENT SCHEDULE HELPERS
  // =========================================================

  List<Map<String, dynamic>> _getStudentSchedules(
    Map<String, dynamic> data,
  ) {
    final List<Map<String, dynamic>> schedules = [];

    final rawSchedules = data['schedules'];

    if (rawSchedules is List) {
      for (final item in rawSchedules) {
        if (item is Map) {
          schedules.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    // -------------------------------------------------------
    // BACKWARD COMPATIBILITY
    // -------------------------------------------------------

    if (schedules.isEmpty) {
      final oldDay =
          data['day']?.toString().trim() ?? '';

      final oldStart =
          data['startTime']?.toString().trim() ?? '';

      final oldEnd =
          data['endTime']?.toString().trim() ?? '';

      if (oldDay.isNotEmpty &&
          oldStart.isNotEmpty &&
          oldEnd.isNotEmpty) {
        schedules.add({
          'day': oldDay,
          'startTime': oldStart,
          'endTime': oldEnd,
        });
      }
    }

    return schedules;
  }

  List<Map<String, dynamic>> _getStudentClassesForSelectedDate(
    String studentId,
    Map<String, dynamic> studentData,
  ) {
    final selectedDay =
        _getFirestoreDayName(selectedDate);

    final schedules =
        _getStudentSchedules(studentData);

    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < schedules.length; i++) {
      final schedule = schedules[i];

      final day =
          schedule['day']?.toString().trim() ?? '';

      if (day != selectedDay) {
        continue;
      }

      final startTime =
          schedule['startTime']?.toString().trim() ?? '';

      final endTime =
          schedule['endTime']?.toString().trim() ?? '';

      if (startTime.isEmpty ||
          endTime.isEmpty) {
        continue;
      }

      result.add({
        'studentId': studentId,
        'studentName':
            studentData['name']?.toString() ?? '',
        'subject':
            studentData['subject']?.toString() ?? '',
        'grade':
            studentData['grade']?.toString() ?? '',
        'startTime': startTime,
        'endTime': endTime,
        'day': day,
        'scheduleIndex': i,
      });
    }

    return result;
  }

  // =========================================================
  // TIME SORTING
  // =========================================================

  int _timeToMinutes(String value) {
    if (value.trim().isEmpty) {
      return 0;
    }

    try {
      final parts = value.trim().split(' ');

      final timePart = parts.first;
      final period =
          parts.length > 1
              ? parts[1].toUpperCase()
              : '';

      final timeParts =
          timePart.split(':');

      if (timeParts.length < 2) {
        return 0;
      }

      int hour =
          int.tryParse(timeParts[0]) ?? 0;

      final minute =
          int.tryParse(timeParts[1]) ?? 0;

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return (hour * 60) + minute;
    } catch (_) {
      return 0;
    }
  }

  // =========================================================
  // ADD CLASS
  // =========================================================

  Future<void> _openAddClass() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClassScreen(
          selectedDate: selectedDate,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // EDIT CLASS
  // =========================================================

  Future<void> _openEditClass({
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddClassScreen(
          classId: documentId,
          classData: data,
          selectedDate: selectedDate,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // DELETE CLASS
  // =========================================================

  Future<void> _deleteClass(
    String documentId,
  ) async {
    try {
      await NotificationService.instance.cancelReminder(
        _notificationId(documentId),
      );

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(documentId)
          .delete();

      if (!mounted) return;

      _showMessage(
        l10n.deletedSuccessfully,
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        l10n.somethingWentWrong,
      );
    }
  }

  void _showDeleteDialog(
    String documentId,
    String subject,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.deleteClass,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${l10n.areYouSureLogout} $subject?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: greyText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                _deleteClass(documentId);
              },
              child: Text(
                l10n.delete,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = true,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : primaryGreen,
      ),
    );
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
      body: Column(
        children: [
          _buildHeader(),
          _buildDaysSelector(),
          Expanded(
            child: _buildScheduleContent(),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 14,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              TeachlyNavigation.of(context)
                  .onTabChanged(0);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.mySchedule,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _openAddClass,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // MONTH + DAYS SELECTOR
  // =========================================================

  Widget _buildDaysSelector() {
    final numberOfDays =
        _daysInMonth(displayedMonth);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        10,
        12,
        10,
        12,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _goToPreviousMonth,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 40,
                  height: 38,
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: primaryGreen,
                    size: 27,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_getMonthName(displayedMonth.month)} ${displayedMonth.year}',
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _goToNextMonth,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 40,
                  height: 38,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: primaryGreen,
                    size: 27,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 72,
            child: SingleChildScrollView(
              controller:
                  _daysScrollController,
              scrollDirection: Axis.horizontal,
              physics:
                  const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(
                  numberOfDays,
                  (index) {
                    final date = DateTime(
                      displayedMonth.year,
                      displayedMonth.month,
                      index + 1,
                    );

                    final isSelected =
                        _isSameDate(
                      date,
                      selectedDate,
                    );

                    final isToday =
                        _isSameDate(
                      date,
                      DateTime.now(),
                    );

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                      child: AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds: 180,
                        ),
                        width: 64,
                        margin:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color: isSelected
                              ? primaryGreen
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          border:
                              isToday &&
                                      !isSelected
                                  ? Border.all(
                                      color:
                                          primaryGreen,
                                      width: 1,
                                    )
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDayShortName(
                                date,
                              ),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : greyText,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : textColor,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Center(
                  child: Text(
                    '${_getDayShortName(selectedDate)}, '
                    '${selectedDate.day} '
                    '${_getMonthName(selectedDate.month)} '
                    '${selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SCHEDULE CONTENT
  // =========================================================

  Widget _buildScheduleContent() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _classesStream(),
      builder: (context, classSnapshot) {
        if (classSnapshot.connectionState ==
                ConnectionState.waiting &&
            !classSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryGreen,
            ),
          );
        }

        if (classSnapshot.hasError) {
          return _buildEmptyState(
            icon:
                Icons.error_outline_rounded,
            title:
                l10n.somethingWentWrong,
            subtitle:
                l10n.somethingWentWrong,
          );
        }

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _studentsStream(),
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !studentSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryGreen,
                ),
              );
            }

            if (studentSnapshot.hasError) {
              return _buildEmptyState(
                icon:
                    Icons.error_outline_rounded,
                title:
                    l10n.somethingWentWrong,
                subtitle:
                    l10n.somethingWentWrong,
              );
            }

            // =================================================
            // NORMAL CLASSES
            // =================================================

            final normalClasses =
                classSnapshot.data?.docs
                        .where((doc) {
                      final data =
                          doc.data();

                      return _classBelongsToSelectedDate(
                        data,
                      );
                    })
                        .toList() ??
                    [];

            // =================================================
            // STUDENT CLASSES
            // =================================================

            final List<Map<String, dynamic>>
                studentClasses = [];

            final studentDocs =
                studentSnapshot.data?.docs ??
                    [];

            for (final studentDoc
                in studentDocs) {
              final studentData =
                  studentDoc.data();

              final classesForDate =
                  _getStudentClassesForSelectedDate(
                studentDoc.id,
                studentData,
              );

              studentClasses.addAll(
                classesForDate,
              );
            }

            // =================================================
            // EMPTY
            // =================================================

            if (normalClasses.isEmpty &&
                studentClasses.isEmpty) {
              return _buildEmptyState(
                icon:
                    Icons.event_available_outlined,
                title:
                    l10n.noClassesToday,
                subtitle:
                    '${l10n.noClasses} '
                    '${_getLocalizedFullDayName(selectedDate)}.',
              );
            }

            // =================================================
            // SORT NORMAL CLASSES
            // =================================================

            normalClasses.sort((a, b) {
              final aMinutes =
                  (a.data()['startMinutes']
                          as num?)
                      ?.toInt() ??
                      _timeToMinutes(
                        a.data()['startTime']
                                ?.toString() ??
                            '',
                      );

              final bMinutes =
                  (b.data()['startMinutes']
                          as num?)
                      ?.toInt() ??
                      _timeToMinutes(
                        b.data()['startTime']
                                ?.toString() ??
                            '',
                      );

              return aMinutes.compareTo(
                bMinutes,
              );
            });

            // =================================================
            // SORT STUDENT CLASSES
            // =================================================

            studentClasses.sort((a, b) {
              return _timeToMinutes(
                a['startTime']?.toString() ?? '',
              ).compareTo(
                _timeToMinutes(
                  b['startTime']?.toString() ?? '',
                ),
              );
            });

            // =================================================
            // COMBINED TIMELINE
            // =================================================

            final List<_ScheduleItem>
                scheduleItems = [];

            for (final doc in normalClasses) {
              scheduleItems.add(
                _ScheduleItem.normal(
                  documentId: doc.id,
                  data: doc.data(),
                ),
              );
            }

            for (final studentClass
                in studentClasses) {
              scheduleItems.add(
                _ScheduleItem.student(
                  data: studentClass,
                ),
              );
            }

            scheduleItems.sort((a, b) {
              return _timeToMinutes(
                a.startTime,
              ).compareTo(
                _timeToMinutes(
                  b.startTime,
                ),
              );
            });

            // =================================================
            // UI
            // =================================================

            return SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                13,
                10,
                18,
              ),
              child: Column(
                children: [
                  for (int i = 0;
                      i < scheduleItems.length;
                      i++) ...[
                    if (scheduleItems[i]
                        .isStudent)
                      _buildStudentClassCard(
                        data:
                            scheduleItems[i]
                                .data,
                      )
                    else
                      _buildClassCard(
                        documentId:
                            scheduleItems[i]
                                .documentId!,
                        data:
                            scheduleItems[i]
                                .data,
                      ),
                    if (i !=
                        scheduleItems.length - 1)
                      const SizedBox(
                        height: 10,
                      ),
                  ],
                  const SizedBox(
                    height: 12,
                  ),
                  _buildAddClassButton(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // NORMAL CLASS CARD
  // =========================================================

  Widget _buildClassCard({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final subject =
        data['subject']?.toString() ??
            l10n.subject;

    final grade =
        data['grade']?.toString() ?? '';

    final room =
        data['room']?.toString() ?? '';

    final startTime =
        data['startTime']?.toString() ?? '';

    final endTime =
        data['endTime']?.toString() ?? '';

    final note =
        data['note']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        9,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.035,
            ),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _extractTime(startTime),
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  _extractPeriod(startTime),
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 1,
            height: 62,
            color:
                const Color(0xFFE8E8E8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    if (room.isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: softGreen,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            6,
                          ),
                        ),
                        child: Text(
                          room.startsWith(
                            'Room',
                          )
                              ? room
                              : '${l10n.room} $room',
                          style:
                              const TextStyle(
                            color:
                                primaryGreen,
                            fontSize: 8,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  grade,
                  style:
                      const TextStyle(
                    color: greyText,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons
                          .access_time_outlined,
                      color: greyText,
                      size: 12,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Text(
                        '$startTime - $endTime',
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color: greyText,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .notes_outlined,
                        color: greyText,
                        size: 11,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: Text(
                          note,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                greyText,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 5),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.more_vert_rounded,
              color: greyText,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _openEditClass(
                  documentId:
                      documentId,
                  data: data,
                );
              }

              if (value == 'delete') {
                _showDeleteDialog(
                  documentId,
                  subject,
                );
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .edit_outlined,
                        color:
                            primaryGreen,
                        size: 19,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(l10n.edit),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .delete_outline_rounded,
                        color:
                            Colors.red,
                        size: 19,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(l10n.delete),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // STUDENT CLASS CARD
  // =========================================================

  Widget _buildStudentClassCard({
    required Map<String, dynamic> data,
  }) {
    final studentName =
        data['studentName']?.toString() ?? '';

    final subject =
        data['subject']?.toString() ?? '';

    final grade =
        data['grade']?.toString() ?? '';

    final startTime =
        data['startTime']?.toString() ?? '';

    final endTime =
        data['endTime']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              primaryGreen.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(
              0.035,
            ),
            blurRadius: 5,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          // -------------------------------------------------
          // TIME
          // -------------------------------------------------

          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _extractTime(startTime),
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 1,
                ),
                Text(
                  _extractPeriod(startTime),
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          Container(
            width: 1,
            height: 70,
            color:
                const Color(0xFFE8E8E8),
          ),

          const SizedBox(width: 12),

          // -------------------------------------------------
          // STUDENT INFO
          // -------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration:
                          BoxDecoration(
                        color: softGreen,
                        borderRadius:
                            BorderRadius
                                .circular(
                          9,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color:
                            primaryGreen,
                        size: 17,
                      ),
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    Expanded(
                      child: Text(
                        studentName.isEmpty
                            ? 'Student'
                            : studentName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: softGreen,
                        borderRadius:
                            BorderRadius
                                .circular(
                          6,
                        ),
                      ),
                      child: const Text(
                        'Student',
                        style:
                            TextStyle(
                          color:
                              primaryGreen,
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    if (subject.isNotEmpty)
                      Expanded(
                        child: Text(
                          subject,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                greyText,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ),
                    if (grade.isNotEmpty)
                      Expanded(
                        child: Text(
                          grade,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          textAlign:
                              TextAlign.end,
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

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons
                          .access_time_outlined,
                      color: greyText,
                      size: 12,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(
                      child: Text(
                        '$startTime - $endTime',
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color: greyText,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TIME HELPERS
  // =========================================================

  String _extractTime(String value) {
    if (value.isEmpty) {
      return '--:--';
    }

    final parts = value.split(' ');

    return parts.first;
  }

  String _extractPeriod(String value) {
    if (value.isEmpty) {
      return '';
    }

    final parts = value.split(' ');

    if (parts.length > 1) {
      return parts[1];
    }

    return '';
  }

  // =========================================================
  // ADD CLASS BUTTON
  // =========================================================

  Widget _buildAddClassButton() {
    return GestureDetector(
      onTap: _openAddClass,
      child: Container(
        width: double.infinity,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(11),
          border: Border.all(
            color: primaryGreen,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add,
              color: primaryGreen,
              size: 18,
            ),
            const SizedBox(width: 5),
            Text(
              l10n.addClass,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 11,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration:
                  BoxDecoration(
                color: softGreen,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Icon(
                icon,
                color: primaryGreen,
                size: 30,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              subtitle,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: greyText,
                fontSize: 11,
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            GestureDetector(
              onTap: _openAddClass,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration:
                    BoxDecoration(
                  color: primaryGreen,
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
                child: Text(
                  l10n.addClass,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// SCHEDULE ITEM
// ===========================================================

class _ScheduleItem {
  final bool isStudent;
  final String? documentId;
  final Map<String, dynamic> data;

  _ScheduleItem.normal({
    required String documentId,
    required this.data,
  })  : isStudent = false,
        documentId = documentId;

  _ScheduleItem.student({
    required this.data,
  })  : isStudent = true,
        documentId = null;

  String get startTime {
    return data['startTime']?.toString() ?? '';
  }
}