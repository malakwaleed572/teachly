import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/screens/student_detail_screen.dart';

class StudentGroupScreen extends StatefulWidget {
  final String subject;
  final String grade;
  final String day;
  final String startTime;
  final String endTime;

  const StudentGroupScreen({
    super.key,
    required this.subject,
    required this.grade,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<StudentGroupScreen> createState() =>
      _StudentGroupScreenState();
}

class _StudentGroupScreenState
    extends State<StudentGroupScreen> {
  static const Color primaryGreen =
      Color(0xFF2F8F57);

  static const Color lightGreen =
      Color(0xFFF1FFF3);

  static const Color softGreen =
      Color(0xFFE7F5E9);

  static const Color textColor =
      Color(0xFF202020);

  static const Color greyColor =
      Color(0xFF777777);

  // =========================
  // NORMALIZE
  // =========================

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  // =========================
  // SCHEDULES
  // =========================

  List<Map<String, dynamic>> _getStudentSchedules(
    Map<String, dynamic> data,
  ) {
    final schedulesValue = data['schedules'];

    if (schedulesValue is List &&
        schedulesValue.isNotEmpty) {
      return schedulesValue
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    }

    // Legacy support
    final day =
        data['day']?.toString() ?? '';

    final startTime =
        data['startTime']?.toString() ?? '';

    final endTime =
        data['endTime']?.toString() ?? '';

    if (day.isEmpty &&
        startTime.isEmpty &&
        endTime.isEmpty) {
      return [];
    }

    return [
      {
        'day': day,
        'startTime': startTime,
        'endTime': endTime,
      }
    ];
  }

  // =========================
  // CHECK GROUP
  // =========================

  bool _studentBelongsToGroup(
    Map<String, dynamic> data,
  ) {
    final studentSubject =
        data['subject']?.toString() ?? '';

    final studentGrade =
        data['grade']?.toString() ?? '';

    if (_normalize(studentSubject) !=
        _normalize(widget.subject)) {
      return false;
    }

    if (_normalize(studentGrade) !=
        _normalize(widget.grade)) {
      return false;
    }

    final schedules =
        _getStudentSchedules(data);

    for (final schedule in schedules) {
      final day =
          schedule['day']?.toString() ?? '';

      final startTime =
          schedule['startTime']?.toString() ?? '';

      final endTime =
          schedule['endTime']?.toString() ?? '';

      if (_normalize(day) ==
              _normalize(widget.day) &&
          _normalize(startTime) ==
              _normalize(widget.startTime) &&
          _normalize(endTime) ==
              _normalize(widget.endTime)) {
        return true;
      }
    }

    return false;
  }

  // =========================
  // LOCALIZATION
  // =========================

  String _localizedGrade(
    String grade,
    AppLocalizations l10n,
  ) {
    switch (grade) {
      case 'Grade 1':
        return l10n.grade1;
      case 'Grade 2':
        return l10n.grade2;
      case 'Grade 3':
        return l10n.grade3;
      case 'Grade 4':
        return l10n.grade4;
      case 'Grade 5':
        return l10n.grade5;
      case 'Grade 6':
        return l10n.grade6;
      case 'Grade 7':
        return l10n.grade7;
      case 'Grade 8':
        return l10n.grade8;
      case 'Grade 9':
        return l10n.grade9;
      case 'Grade 10':
        return l10n.grade10;
      case 'Grade 11':
        return l10n.grade11;
      case 'Grade 12':
        return l10n.grade12;
      default:
        return grade;
    }
  }

  String _localizedSubject(
    String subject,
    AppLocalizations l10n,
  ) {
    switch (subject) {
      case 'English':
        return l10n.englishSubject;
      case 'Math':
        return l10n.math;
      case 'Science':
        return l10n.science;
      case 'Arabic':
        return l10n.arabicSubject;
      default:
        return subject;
    }
  }

  String _localizedDay(
    String day,
    AppLocalizations l10n,
  ) {
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

  // =========================
  // ATTENDANCE
  // =========================

  Future<void> _updateAttendance({
    required String studentId,
    required String status,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final now = DateTime.now();

    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final studentReference =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('students')
            .doc(studentId);

    await studentReference
        .collection('attendance')
        .doc(dateKey)
        .set(
      {
        'attendance': status,
        'status': status,
        'dateKey': dateKey,
        'date': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================
  // PAYMENT
  // =========================

  Future<void> _updatePayment({
    required String studentId,
    required bool paid,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final now = DateTime.now();

    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final studentReference =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('students')
            .doc(studentId);

    await studentReference
        .collection('payments')
        .doc(dateKey)
        .set(
      {
        'paid': paid,
        'payment': paid,
        'dateKey': dateKey,
        'date': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================
  // STATUS STREAM
  // =========================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _attendanceStream(String studentId) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    final now = DateTime.now();

    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .collection('attendance')
        .doc(dateKey)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      _paymentStream(String studentId) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    final now = DateTime.now();

    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .doc(studentId)
        .collection('payments')
        .doc(dateKey)
        .snapshots();
  }

  // =========================
  // STUDENT CARD
  // =========================

  Widget _buildStudentCard({
    required BuildContext context,
    required String studentId,
    required Map<String, dynamic> data,
    required AppLocalizations l10n,
  }) {
    final name =
        data['name']?.toString() ??
            l10n.student;

    final phone =
        data['phone']?.toString() ?? '';

    final grade =
        data['grade']?.toString() ?? '';

    final subject =
        data['subject']?.toString() ?? '';

    final displayGrade =
        _localizedGrade(grade, l10n);

    final displaySubject =
        _localizedSubject(subject, l10n);

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _attendanceStream(studentId),
      builder: (
        context,
        attendanceSnapshot,
      ) {
        String attendance = 'Not Marked';

        if (attendanceSnapshot.hasData &&
            attendanceSnapshot.data!.exists) {
          final attendanceData =
              attendanceSnapshot.data!.data();

          attendance =
              (attendanceData?['attendance'] ??
                      attendanceData?['status'] ??
                      'Not Marked')
                  .toString();
        }

        return StreamBuilder<
            DocumentSnapshot<
                Map<String, dynamic>>>(
          stream: _paymentStream(studentId),
          builder: (
            context,
            paymentSnapshot,
          ) {
            bool paid = false;

            if (paymentSnapshot.hasData &&
                paymentSnapshot.data!.exists) {
              final paymentData =
                  paymentSnapshot.data!.data();

              final paidValue =
                  paymentData?['paid'] ??
                      paymentData?['payment'];

              paid = paidValue == true ||
                  paidValue
                          ?.toString()
                          .toLowerCase() ==
                      'true';
            }

            final isPresent =
                attendance == 'Present';

            final isAbsent =
                attendance == 'Absent';

            return Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color:
                      const Color(0xFFE0EDE2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.035),
                    blurRadius: 8,
                    offset:
                        const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // =========================
                  // TOP
                  // =========================

                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color: softGreen,
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color:
                              primaryGreen,
                          size: 29,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    textColor,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                                height: 4),

                            Text(
                              '$displayGrade • $displaySubject',
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    greyColor,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),

                            if (phone.isNotEmpty) ...[
                              const SizedBox(
                                  height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .phone_outlined,
                                    color:
                                        primaryGreen,
                                    size: 14,
                                  ),
                                  const SizedBox(
                                      width: 4),
                                  Expanded(
                                    child: Text(
                                      phone,
                                      style:
                                          const TextStyle(
                                        color:
                                            greyColor,
                                        fontSize:
                                            11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailScreen(
                                studentId:
                                    studentId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons
                              .arrow_forward_ios_rounded,
                          color:
                              primaryGreen,
                          size: 19,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 13),

                  // =========================
                  // CLASS INFO
                  // =========================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration:
                        BoxDecoration(
                      color: lightGreen,
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .calendar_month_outlined,
                          color:
                              primaryGreen,
                          size: 17,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '${_localizedDay(widget.day, l10n)} • ${widget.startTime} - ${widget.endTime}',
                            style:
                                const TextStyle(
                              color:
                                  textColor,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 13),

                  // =========================
                  // ATTENDANCE
                  // =========================

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      l10n.attendance,
                      style:
                          const TextStyle(
                        color: textColor,
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
                          icon: Icons
                              .check_circle_outline,
                          selected:
                              isPresent,
                          color:
                              primaryGreen,
                          onTap: () async {
                            await _updateAttendance(
                              studentId:
                                  studentId,
                              status:
                                  'Present',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusButton(
                          text: l10n.absent,
                          icon: Icons
                              .cancel_outlined,
                          selected:
                              isAbsent,
                          color: Colors.red,
                          onTap: () async {
                            await _updateAttendance(
                              studentId:
                                  studentId,
                              status:
                                  'Absent',
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // =========================
                  // PAYMENT
                  // =========================

                  Align(
                    alignment:
                        Alignment.centerLeft,
                    child: Text(
                      l10n.payment,
                      style:
                          const TextStyle(
                        color: textColor,
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
                          icon: Icons
                              .check_circle_outline,
                          selected: paid,
                          color:
                              primaryGreen,
                          onTap: () async {
                            await _updatePayment(
                              studentId:
                                  studentId,
                              paid: true,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusButton(
                          text: l10n.notPaid,
                          icon: Icons
                              .payments_outlined,
                          selected: !paid,
                          color: Colors.orange,
                          onTap: () async {
                            await _updatePayment(
                              studentId:
                                  studentId,
                              paid: false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================
  // STATUS BUTTON
  // =========================

  Widget _buildStatusButton({
    required String text,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(
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
            Icon(
              icon,
              size: 17,
              color: selected
                  ? color
                  : greyColor,
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
                      : greyColor,
                  fontSize: 11,
                  fontWeight:
                      selected
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

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context);

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.login),
        ),
      );
    }

    final studentsReference =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('students');

    final displaySubject =
        _localizedSubject(
      widget.subject,
      l10n,
    );

    final displayGrade =
        _localizedGrade(
      widget.grade,
      l10n,
    );

    final displayDay =
        _localizedDay(
      widget.day,
      l10n,
    );

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: const Text(
          'Student Group',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: studentsReference
            .orderBy('name')
            .snapshots(),
        builder: (
          context,
          snapshot,
        ) {
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
                padding:
                    const EdgeInsets.all(20),
                child: Text(
                  '${l10n.somethingWentWrong}\n\n${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final allDocs =
              snapshot.data?.docs ?? [];

          final groupStudents =
              allDocs.where((doc) {
            return _studentBelongsToGroup(
              doc.data(),
            );
          }).toList();

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              30,
            ),
            children: [
              // =========================
              // GROUP HEADER
              // =========================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        const Color(0xFFE0EDE2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.035),
                      blurRadius: 8,
                      offset:
                          const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration:
                          BoxDecoration(
                        color: softGreen,
                        borderRadius:
                            BorderRadius.circular(
                          17,
                        ),
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color:
                            primaryGreen,
                        size: 31,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      displaySubject,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      displayGrade,
                      style:
                          const TextStyle(
                        color: primaryGreen,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color: lightGreen,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons
                                .calendar_month_outlined,
                            color:
                                primaryGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$displayDay • ${widget.startTime} - ${widget.endTime}',
                            style:
                                const TextStyle(
                              color:
                                  primaryGreen,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // =========================
              // STUDENT COUNT
              // =========================

              Row(
                children: [
                  const Icon(
                    Icons.groups_outlined,
                    color: primaryGreen,
                    size: 19,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    groupStudents.length == 1
                        ? '1 Student'
                        : '${groupStudents.length} Students',
                    style:
                        const TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =========================
              // STUDENTS
              // =========================

              if (groupStudents.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color:
                          const Color(
                        0xFFE0EDE2,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons
                            .person_off_outlined,
                        color: greyColor,
                        size: 35,
                      ),
                      const SizedBox(
                          height: 10),
                      Text(
                        l10n.noStudentsFound,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              greyColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...groupStudents.map(
                  (doc) => _buildStudentCard(
                    context: context,
                    studentId: doc.id,
                    data: doc.data(),
                    l10n: l10n,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}