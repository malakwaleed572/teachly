import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teachly/core/localization/app_localization.dart';

import 'add_student_screen.dart';
import 'main_navigation_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

// =============================================================
// STUDENT STATS CONTROLLER
// =============================================================

class _StudentStatsController extends ChangeNotifier {
  int present = 0;
  int absent = 0;
  int paid = 0;
  int notPaid = 0;

  int studentsCount = 0;

  bool loading = true;

  int _loadVersion = 0;

  Future<void> loadStats({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
    required Future<Map<String, dynamic>> Function(String studentId)
        getAttendanceData,
  }) async {
    final currentVersion = ++_loadVersion;

    studentsCount = students.length;

    if (students.isEmpty) {
      present = 0;
      absent = 0;
      paid = 0;
      notPaid = 0;
      loading = false;

      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    int newPresent = 0;
    int newAbsent = 0;
    int newPaid = 0;
    int newNotPaid = 0;

    for (final student in students) {
      final data = await getAttendanceData(student.id);

      if (currentVersion != _loadVersion) {
        return;
      }

      final attendance = data['attendance']?.toString();

      final isPaid = data['paid'] == true;

      if (attendance == 'Present') {
        newPresent++;
      } else if (attendance == 'Absent') {
        newAbsent++;
      }

      if (isPaid) {
        newPaid++;
      } else {
        newNotPaid++;
      }
    }

    if (currentVersion != _loadVersion) {
      return;
    }

    present = newPresent;
    absent = newAbsent;
    paid = newPaid;
    notPaid = newNotPaid;
    loading = false;

    notifyListeners();
  }

  void updateAttendance({
    required String oldStatus,
    required String newStatus,
  }) {
    if (oldStatus == newStatus) {
      return;
    }

    if (oldStatus == 'Present') {
      present = present > 0 ? present - 1 : 0;
    } else if (oldStatus == 'Absent') {
      absent = absent > 0 ? absent - 1 : 0;
    }

    if (newStatus == 'Present') {
      present++;
    } else if (newStatus == 'Absent') {
      absent++;
    }

    notifyListeners();
  }

  void updatePayment({
    required bool oldPaid,
    required bool newPaid,
  }) {
    if (oldPaid == newPaid) {
      return;
    }

    if (oldPaid) {
      paid = paid > 0 ? paid - 1 : 0;
    } else {
      notPaid = notPaid > 0 ? notPaid - 1 : 0;
    }

    if (newPaid) {
      paid++;
    } else {
      notPaid++;
    }

    notifyListeners();
  }

  void rollbackAttendance({
    required String oldStatus,
    required String newStatus,
  }) {
    updateAttendance(
      oldStatus: newStatus,
      newStatus: oldStatus,
    );
  }

  void rollbackPayment({
    required bool oldPaid,
    required bool newPaid,
  }) {
    updatePayment(
      oldPaid: newPaid,
      newPaid: oldPaid,
    );
  }
}

// =============================================================
// STUDENT LIST SCREEN
// =============================================================

class _StudentListScreenState extends State<StudentListScreen> {
  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyColor = Color(0xFF777777);

  String? selectedGroup;
  DateTime selectedDate = DateTime.now();

  final _StudentStatsController _statsController =
      _StudentStatsController();

  final List<String> days = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  String _dayName(DateTime date) {
    const dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return dayNames[date.weekday - 1];
  }

  String _localizedDayName(DateTime date) {
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

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _monthKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$year-$month';
  }

  String _formattedDate(DateTime date) {
    const monthNames = [
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

    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  // =========================================================
  // DATE ACTIONS
  // =========================================================

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        selectedGroup = null;
      });
    }
  }

  void _previousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(
        const Duration(days: 1),
      );
      selectedGroup = null;
    });
  }

  void _nextDay() {
    setState(() {
      selectedDate = selectedDate.add(
        const Duration(days: 1),
      );
      selectedGroup = null;
    });
  }

  // =========================================================
  // SCHEDULE HELPERS
  // =========================================================

  List<Map<String, dynamic>> _getStudentSchedules(
    Map<String, dynamic> data,
  ) {
    final schedulesValue = data['schedules'];

    if (schedulesValue is List && schedulesValue.isNotEmpty) {
      return schedulesValue
          .whereType<Map>()
          .map(
            (schedule) => Map<String, dynamic>.from(schedule),
          )
          .toList();
    }

    final oldDay = data['day']?.toString() ?? '';
    final oldStartTime = data['startTime']?.toString() ?? '';
    final oldEndTime = data['endTime']?.toString() ?? '';

    if (oldDay.isEmpty) {
      return [];
    }

    return [
      {
        'day': oldDay,
        'startTime': oldStartTime,
        'endTime': oldEndTime,
      },
    ];
  }

  Map<String, dynamic>? _getScheduleForSelectedDate(
    Map<String, dynamic> data,
  ) {
    final selectedDay = _dayName(selectedDate);

    final schedules = _getStudentSchedules(data);

    for (final schedule in schedules) {
      final scheduleDay = schedule['day']?.toString() ?? '';

      if (scheduleDay == selectedDay) {
        return schedule;
      }
    }

    return null;
  }

  bool _studentHasSelectedDay(Map<String, dynamic> data) {
    return _getScheduleForSelectedDate(data) != null;
  }

  bool _studentBelongsToGroup(
    Map<String, dynamic> data,
    String group,
  ) {
    final parts = group.split('|');

    if (parts.length < 2) {
      return false;
    }

    final selectedGroupDay = parts[0];
    final selectedGroupTime = parts[1];

    final schedules = _getStudentSchedules(data);

    for (final schedule in schedules) {
      final day = schedule['day']?.toString() ?? '';
      final startTime = schedule['startTime']?.toString() ?? '';

      if (day == selectedGroupDay &&
          startTime == selectedGroupTime) {
        return true;
      }
    }

    return false;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterStudents(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    return students.where((student) {
      final data = student.data();

      if (!_studentHasSelectedDay(data)) {
        return false;
      }

      if (selectedGroup != null) {
        return _studentBelongsToGroup(
          data,
          selectedGroup!,
        );
      }

      return true;
    }).toList();
  }

  // =========================================================
  // FIRESTORE REFERENCES
  // =========================================================

  DocumentReference<Map<String, dynamic>> _attendanceReference(
    String studentId,
  ) {
    final user = FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .collection('attendance')
        .doc(_dateKey(selectedDate));
  }

  DocumentReference<Map<String, dynamic>> _paymentDateReference(
    String studentId,
  ) {
    final user = FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .collection('payments')
        .doc(_dateKey(selectedDate));
  }

  DocumentReference<Map<String, dynamic>>
      _oldMonthlyPaymentReference(
    String studentId,
  ) {
    final user = FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .collection('payments')
        .doc(_monthKey(selectedDate));
  }

  // =========================================================
  // LOAD STATUS
  // =========================================================

  Future<Map<String, dynamic>> _getAttendanceData(
    String studentId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {
        'attendance': 'Not Marked',
        'paid': false,
      };
    }

    try {
      final attendanceDoc =
          await _attendanceReference(studentId).get();

      String attendance = 'Not Marked';

      if (attendanceDoc.exists) {
        final data = attendanceDoc.data() ?? {};

        attendance =
            data['attendance'] ??
            data['status'] ??
            'Not Marked';

        attendance = attendance.toString();
      }

      final paymentDoc =
          await _paymentDateReference(studentId).get();

      bool paid = false;

      if (paymentDoc.exists) {
        final data = paymentDoc.data() ?? {};

        final value =
            data['paid'] ??
            data['payment'];

        paid =
            value == true ||
            value?.toString().toLowerCase() == 'true';
      } else {
        final oldPaymentDoc =
            await _oldMonthlyPaymentReference(studentId).get();

        if (oldPaymentDoc.exists) {
          final data = oldPaymentDoc.data() ?? {};

          final value =
              data['paid'] ??
              data['payment'];

          paid =
              value == true ||
              value?.toString().toLowerCase() == 'true';
        }
      }

      return {
        'attendance': attendance,
        'paid': paid,
      };
    } catch (_) {
      return {
        'attendance': 'Not Marked',
        'paid': false,
      };
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  void _openStudentDetail(String studentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            StudentDetailScreen(studentId: studentId),
      ),
    );
  }

  Future<void> _editStudent(
    String studentId,
    Map<String, dynamic> studentData,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentScreen(
          studentId: studentId,
          studentData: studentData,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteStudent(
    String studentId,
    String studentName,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.deleteStudent,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '${l10n.areYouSureLogout} $studentName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: greyColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                l10n.delete,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .delete();
  }

  Future<void> _addStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddStudentScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // GROUPS
  // =========================================================

  List<String> _getGroups(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final selectedDay = _dayName(selectedDate);

    final groups = <String>{};

    for (final student in students) {
      final data = student.data();

      final schedules = _getStudentSchedules(data);

      for (final schedule in schedules) {
        final day = schedule['day']?.toString() ?? '';
        final startTime =
            schedule['startTime']?.toString() ?? '';

        if (day == selectedDay &&
            day.isNotEmpty &&
            startTime.isNotEmpty) {
          groups.add('$day|$startTime');
        }
      }
    }

    final result = groups.toList();

    result.sort((a, b) {
      final aParts = a.split('|');
      final bParts = b.split('|');

      final aTime =
          aParts.length > 1 ? aParts[1] : '';

      final bTime =
          bParts.length > 1 ? bParts[1] : '';

      return aTime.compareTo(bTime);
    });

    return result;
  }

  String _groupLabel(String group) {
    final parts = group.split('|');

    if (parts.length < 2) {
      return group;
    }

    return '${_localizedDayFromFirestore(parts[0])} • ${parts[1]}';
  }

  String _localizedDayFromFirestore(String day) {
    switch (day) {
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
        return day;
    }
  }

  // =========================================================
  // GROUP SELECTOR
  // =========================================================

  Widget _buildGroupSelector(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final groups = _getGroups(students);

    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDDEBDD),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedGroup,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryGreen,
          ),
          hint: const Text(
            'All Students',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Students',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
            ...groups.map((group) {
              return DropdownMenuItem<String?>(
                value: group,
                child: Text(
                  _groupLabel(group),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              selectedGroup = value;
            });
          },
        ),
      ),
    );
  }

  // =========================================================
  // DATE SELECTOR
  // =========================================================

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDDEBDD),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousDay,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: primaryGreen,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Column(
                children: [
                  Text(
                    _localizedDayName(selectedDate),
                    style: const TextStyle(
                      color: primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formattedDate(selectedDate),
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: primaryGreen,
              size: 21,
            ),
          ),
          IconButton(
            onPressed: _nextDay,
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.noAccount),
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            TeachlyNavigation.of(context).onTabChanged(0);
          },
        ),
        title: Text(
          l10n.studentList,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('students')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.somethingWentWrong,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final allStudents =
              snapshot.data?.docs ?? [];

          final filteredStudents =
              _filterStudents(allStudents);

          return Column(
            children: [
              // =================================================
              // STATS
              // =================================================
              _StudentStats(
                key: ValueKey(
                  '${_dateKey(selectedDate)}_$selectedGroup',
                ),
                controller: _statsController,
                students: filteredStudents,
                getAttendanceData: _getAttendanceData,
              ),

              _buildGroupSelector(allStudents),

              _buildDateSelector(),

              Expanded(
                child: filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 2,
                          bottom: 90,
                        ),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student =
                              filteredStudents[index];

                          return _buildStudentCard(student);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addStudent,
        backgroundColor: primaryGreen,
        elevation: 4,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      bottomNavigationBar:
          const TeachlyBottomNavigation(),
    );
  }

  Widget _buildStudentCard(
    QueryDocumentSnapshot<Map<String, dynamic>> student,
  ) {
    final data = student.data();

    final selectedSchedule =
        _getScheduleForSelectedDate(data);

    final day =
        selectedSchedule?['day']?.toString() ?? '';

    final startTime =
        selectedSchedule?['startTime']?.toString() ?? '';

    final endTime =
        selectedSchedule?['endTime']?.toString() ?? '';

    return _StudentCard(
      key: ValueKey(
        '${student.id}_${_dateKey(selectedDate)}',
      ),
      studentId: student.id,
      data: data,
      day: day,
      startTime: startTime,
      endTime: endTime,
      localizedCardDay:
          _localizedDayFromFirestore(day),
      selectedDate: selectedDate,
      statsController: _statsController,
      onOpenDetails: () {
        _openStudentDetail(student.id);
      },
      onEdit: () {
        _editStudent(student.id, data);
      },
      onDelete: () {
        _deleteStudent(
          student.id,
          data['name']?.toString() ?? l10n.student,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 45,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.noStudentsFound,
              style: const TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.noStudents} '
              '${_localizedDayName(selectedDate)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: greyColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _addStudent,
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: Text(
                l10n.addStudent,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// STUDENT STATS
// =============================================================

class _StudentStats extends StatefulWidget {
  final _StudentStatsController controller;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;

  final Future<Map<String, dynamic>> Function(String studentId)
      getAttendanceData;

  const _StudentStats({
    super.key,
    required this.controller,
    required this.students,
    required this.getAttendanceData,
  });

  @override
  State<_StudentStats> createState() =>
      _StudentStatsState();
}

class _StudentStatsState extends State<_StudentStats> {
  @override
  void initState() {
    super.initState();

    widget.controller.loadStats(
      students: widget.students,
      getAttendanceData: widget.getAttendanceData,
    );
  }

  @override
  void didUpdateWidget(
    covariant _StudentStats oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldStudentIds =
        oldWidget.students.map((e) => e.id).join(',');

    final newStudentIds =
        widget.students.map((e) => e.id).join(',');

    if (oldStudentIds != newStudentIds ||
        oldWidget.getAttendanceData !=
            widget.getAttendanceData) {
      widget.controller.loadStats(
        students: widget.students,
        getAttendanceData: widget.getAttendanceData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            10,
            18,
            10,
            20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF2F8F57),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  title: l10n.students,
                  value: widget.controller.studentsCount
                      .toString(),
                  icon: Icons.groups_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _StatItem(
                  title: l10n.present,
                  value: widget.controller.present
                      .toString(),
                  icon: Icons.check_circle_outline,
                ),
              ),
              _divider(),
              Expanded(
                child: _StatItem(
                  title: l10n.absent,
                  value: widget.controller.absent
                      .toString(),
                  icon: Icons.cancel_outlined,
                ),
              ),
              _divider(),
              Expanded(
                child: _StatItem(
                  title: l10n.paid,
                  value: widget.controller.paid
                      .toString(),
                  icon: Icons.payments_outlined,
                ),
              ),
              _divider(),
              Expanded(
                child: _StatItem(
                  title: l10n.notPaid,
                  value: widget.controller.notPaid
                      .toString(),
                  icon: Icons.money_off_outlined,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 45,
      color: Colors.white.withOpacity(0.25),
    );
  }
}

// =============================================================
// STUDENT CARD
// =============================================================

class _StudentCard extends StatefulWidget {
  final String studentId;
  final Map<String, dynamic> data;

  final String day;
  final String startTime;
  final String endTime;
  final String localizedCardDay;

  final DateTime selectedDate;

  final _StudentStatsController statsController;

  final VoidCallback onOpenDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StudentCard({
    super.key,
    required this.studentId,
    required this.data,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.localizedCardDay,
    required this.selectedDate,
    required this.statsController,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_StudentCard> createState() =>
      _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  String attendance = 'Not Marked';
  bool paid = false;

  bool isLoading = true;
  bool isUpdatingAttendance = false;
  bool isUpdatingPayment = false;

  AppLocalizations get l10n =>
      AppLocalizations.of(context);

  DocumentReference<Map<String, dynamic>>
      get attendanceReference {
    final user =
        FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(widget.studentId)
        .collection('attendance')
        .doc(_dateKey(widget.selectedDate));
  }

  DocumentReference<Map<String, dynamic>>
      get paymentReference {
    final user =
        FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(widget.studentId)
        .collection('payments')
        .doc(_dateKey(widget.selectedDate));
  }

  DocumentReference<Map<String, dynamic>>
      get oldMonthlyPaymentReference {
    final user =
        FirebaseAuth.instance.currentUser!;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(widget.studentId)
        .collection('payments')
        .doc(_monthKey(widget.selectedDate));
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  // =========================================================
  // LOAD STATUS
  // =========================================================

  Future<void> _loadStatus() async {
    try {
      final attendanceDoc =
          await attendanceReference.get();

      String newAttendance = 'Not Marked';

      if (attendanceDoc.exists) {
        final data =
            attendanceDoc.data() ?? {};

        newAttendance =
            data['attendance'] ??
            data['status'] ??
            'Not Marked';

        newAttendance =
            newAttendance.toString();
      }

      final paymentDoc =
          await paymentReference.get();

      bool newPaid = false;

      if (paymentDoc.exists) {
        final data =
            paymentDoc.data() ?? {};

        final value =
            data['paid'] ??
            data['payment'];

        newPaid =
            value == true ||
            value?.toString().toLowerCase() ==
                'true';
      } else {
        final oldPaymentDoc =
            await oldMonthlyPaymentReference.get();

        if (oldPaymentDoc.exists) {
          final data =
              oldPaymentDoc.data() ?? {};

          final value =
              data['paid'] ??
              data['payment'];

          newPaid =
              value == true ||
              value?.toString().toLowerCase() ==
                  'true';
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        attendance = newAttendance;
        paid = newPaid;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================================================
  // UPDATE ATTENDANCE
  // =========================================================

  Future<void> _updateAttendance(
    String newStatus,
  ) async {
    if (isUpdatingAttendance) {
      return;
    }

    final oldStatus = attendance;

    if (oldStatus == newStatus) {
      return;
    }

    // =======================================================
    // UPDATE CARD IMMEDIATELY
    // =======================================================

    setState(() {
      attendance = newStatus;
      isUpdatingAttendance = true;
    });

    // =======================================================
    // UPDATE STATS IMMEDIATELY
    // =======================================================

    widget.statsController.updateAttendance(
      oldStatus: oldStatus,
      newStatus: newStatus,
    );

    try {
      await attendanceReference.set(
        {
          'attendance': newStatus,
          'status': newStatus,
          'date': _dateKey(widget.selectedDate),
          'dateKey': _dateKey(widget.selectedDate),
          'day': widget.day,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      // =====================================================
      // ROLLBACK CARD
      // =====================================================

      setState(() {
        attendance = oldStatus;
      });

      // =====================================================
      // ROLLBACK STATS
      // =====================================================

      widget.statsController.rollbackAttendance(
        oldStatus: oldStatus,
        newStatus: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.somethingWentWrong,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingAttendance = false;
        });
      }
    }
  }

  // =========================================================
  // UPDATE PAYMENT
  // =========================================================

  Future<void> _updatePayment(
    bool newPaid,
  ) async {
    if (isUpdatingPayment) {
      return;
    }

    final oldPaid = paid;

    if (oldPaid == newPaid) {
      return;
    }

    // =======================================================
    // UPDATE CARD IMMEDIATELY
    // =======================================================

    setState(() {
      paid = newPaid;
      isUpdatingPayment = true;
    });

    // =======================================================
    // UPDATE STATS IMMEDIATELY
    // =======================================================

    widget.statsController.updatePayment(
      oldPaid: oldPaid,
      newPaid: newPaid,
    );

    try {
      await paymentReference.set(
        {
          'paid': newPaid,
          'payment': newPaid,
          'date': _dateKey(widget.selectedDate),
          'dateKey': _dateKey(widget.selectedDate),
          'day': widget.day,
          'year': widget.selectedDate.year,
          'monthNumber': widget.selectedDate.month,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      // =====================================================
      // ROLLBACK CARD
      // =====================================================

      setState(() {
        paid = oldPaid;
      });

      // =====================================================
      // ROLLBACK STATS
      // =====================================================

      widget.statsController.rollbackPayment(
        oldPaid: oldPaid,
        newPaid: newPaid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.somethingWentWrong,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingPayment = false;
        });
      }
    }
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  String _dateKey(DateTime date) {
    final year =
        date.year.toString().padLeft(4, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _monthKey(DateTime date) {
    final year =
        date.year.toString().padLeft(4, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$year-$month';
  }

  // =========================================================
  // STATUS BUTTON
  // =========================================================

  Widget _buildStatusButton({
    required String text,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    required bool loading,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.10)
              : Colors.white,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? color
                : const Color(0xFFE0EDE2),
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(
                width: 17,
                height: 17,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: selected
                      ? color
                      : const Color(0xFF777777),
                ),
              )
            else
              Icon(
                icon,
                size: 17,
                color: selected
                    ? color
                    : const Color(0xFF777777),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? color
                      : const Color(0xFF777777),
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD CARD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final name =
        widget.data['name']?.toString() ??
            l10n.student;

    final phone =
        widget.data['phone']?.toString() ?? '';

    final grade =
        widget.data['grade']?.toString() ?? '';

    final subject =
        widget.data['subject']?.toString() ?? '';

    final isPresent =
        attendance == 'Present';

    final isAbsent =
        attendance == 'Absent';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        6,
        16,
        8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0EDE2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // =================================================
          // STUDENT INFO
          // =================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE7F5E9),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color:
                      Color(0xFF2F8F57),
                  size: 28,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            Color(0xFF202020),
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        if (grade.isNotEmpty)
                          Flexible(
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFE7F5E9,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  8,
                                ),
                              ),
                              child: Text(
                                grade,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color:
                                      Color(
                                    0xFF2F8F57,
                                  ),
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                            ),
                          ),

                        if (grade.isNotEmpty &&
                            subject.isNotEmpty)
                          const SizedBox(
                            width: 6,
                          ),

                        if (subject.isNotEmpty)
                          Flexible(
                            child: Text(
                              subject,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF777777,
                                ),
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w500,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color:
                                Color(0xFF777777),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              phone,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF777777,
                                ),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color:
                      Color(0xFF777777),
                ),
                onSelected: (value) {
                  if (value == 'details') {
                    widget.onOpenDetails();
                  } else if (value == 'edit') {
                    widget.onEdit();
                  } else if (value == 'delete') {
                    widget.onDelete();
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .person_search_outlined,
                            size: 20,
                            color:
                                Color(0xFF2F8F57),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            l10n.studentDetails,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            l10n.delete,
                            style:
                                const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // SCHEDULE
          // =================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF1FFF3),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.schedule_outlined,
                    color:
                        Color(0xFF2F8F57),
                    size: 18,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.localizedCardDay} • '
                        '${widget.startTime} - '
                        '${widget.endTime}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Color(0xFF202020),
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      if (subject.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subject,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Color(0xFF777777),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          // =================================================
          // ATTENDANCE
          // =================================================

          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              l10n.attendance,
              style:
                  const TextStyle(
                color:
                    Color(0xFF202020),
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  text: l10n.present,
                  icon:
                      Icons.check_circle_outline,
                  selected: isPresent,
                  color:
                      const Color(0xFF2F8F57),
                  loading:
                      isUpdatingAttendance,
                  onTap: () {
                    _updateAttendance(
                      'Present',
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildStatusButton(
                  text: l10n.absent,
                  icon:
                      Icons.cancel_outlined,
                  selected: isAbsent,
                  color: Colors.red,
                  loading:
                      isUpdatingAttendance,
                  onTap: () {
                    _updateAttendance(
                      'Absent',
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =================================================
          // PAYMENT
          // =================================================

          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              l10n.payment,
              style:
                  const TextStyle(
                color:
                    Color(0xFF202020),
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            children: [
              Expanded(
                child: _buildStatusButton(
                  text: l10n.paid,
                  icon:
                      Icons.check_circle_outline,
                  selected: paid,
                  color:
                      const Color(0xFF2F8F57),
                  loading:
                      isUpdatingPayment,
                  onTap: () {
                    _updatePayment(true);
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _buildStatusButton(
                  text: l10n.notPaid,
                  icon:
                      Icons.payments_outlined,
                  selected: !paid,
                  color: Colors.orange,
                  loading:
                      isUpdatingPayment,
                  onTap: () {
                    _updatePayment(false);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =================================================
          // DETAILS
          // =================================================

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius:
                  BorderRadius.circular(10),
              onTap: widget.onOpenDetails,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 4,
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.studentDetails,
                      style:
                          const TextStyle(
                        color:
                            Color(0xFF2F8F57),
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      size: 12,
                      color:
                          Color(0xFF2F8F57),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// STAT ITEM
// =============================================================

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 19,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
                Colors.white.withOpacity(0.85),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}