
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:teachly/core/localization/app_localization.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;

  const StudentDetailScreen({
    super.key,
    required this.studentId,
  });

  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyColor = Color(0xFF777777);

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
  // DATE HELPERS
  // =========================

  DateTime? _getDateFromData(
    Map<String, dynamic> data,
  ) {
    final dateValue = data['date'];

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    if (dateValue is String && dateValue.isNotEmpty) {
      return DateTime.tryParse(dateValue);
    }

    final dateKey = data['dateKey'];

    if (dateKey is String && dateKey.isNotEmpty) {
      return DateTime.tryParse(dateKey);
    }

    return null;
  }

  String _formatDateTime(
    DateTime date,
    AppLocalizations l10n,
  ) {
    final months = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december,
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(
    dynamic value,
    AppLocalizations l10n,
  ) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String && value.isNotEmpty) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return '-';
    }

    return _formatDateTime(date, l10n);
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

    // Legacy student support
    final day = data['day']?.toString() ?? '';
    final startTime = data['startTime']?.toString() ?? '';
    final endTime = data['endTime']?.toString() ?? '';

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

  Widget _buildScheduleCard(
    Map<String, dynamic> schedule,
    AppLocalizations l10n,
  ) {
    final day = schedule['day']?.toString() ?? '';
    final startTime =
        schedule['startTime']?.toString() ?? '';
    final endTime =
        schedule['endTime']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDCEBDD),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedDay(day, l10n),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: primaryGreen,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      startTime.isNotEmpty &&
                              endTime.isNotEmpty
                          ? '$startTime - $endTime'
                          : startTime,
                      style: const TextStyle(
                        color: greyColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  // =========================
  // INFO CARD
  // =========================

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0EDE2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryGreen,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: greyColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // STAT CARD
  // =========================

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String title,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE0EDE2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: iconColor ?? primaryGreen,
              size: 23,
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: greyColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // PAYMENT HISTORY
  // =========================

  Widget _buildPaymentHistory(
    List<Map<String, dynamic>> payments,
    AppLocalizations l10n,
  ) {
    if (payments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.payments_outlined,
              color: greyColor,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noStudents,
              style: const TextStyle(
                color: greyColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: payments.map((payment) {
        final data =
            payment['data'] as Map<String, dynamic>;

        final paidValue = data['paid'];
        final paid =
            paidValue == true ||
            paidValue?.toString().toLowerCase() ==
                'true';

        final date = _getDateFromData(data);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: paid
                ? lightGreen
                : Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: paid
                      ? primaryGreen
                      : Colors.red.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  paid
                      ? Icons.check
                      : Icons.close_rounded,
                  color: paid
                      ? Colors.white
                      : Colors.red,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  date == null
                      ? '-'
                      : _formatDateTime(
                          date,
                          l10n,
                        ),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                paid ? l10n.paid : l10n.notPaid,
                style: TextStyle(
                  color:
                      paid ? primaryGreen : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // ATTENDANCE HISTORY
  // =========================

  Widget _buildAttendanceHistory(
    List<Map<String, dynamic>> attendanceRecords,
    AppLocalizations l10n,
  ) {
    if (attendanceRecords.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_note_outlined,
              color: greyColor,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noStudents,
              style: const TextStyle(
                color: greyColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: attendanceRecords.map((record) {
        final data =
            record['data'] as Map<String, dynamic>;

        final status =
            (data['attendance'] ??
                    data['status'] ??
                    'Not Marked')
                .toString();

        final isPresent = status == 'Present';
        final isAbsent = status == 'Absent';

        final statusColor = isPresent
            ? primaryGreen
            : isAbsent
                ? Colors.red
                : Colors.orange;

        final statusText = isPresent
            ? l10n.present
            : isAbsent
                ? l10n.absent
                : l10n.notMarked;

        final date = _getDateFromData(data);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: isPresent
                ? softGreen
                : isAbsent
                    ? Colors.red.withOpacity(0.06)
                    : Colors.orange.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  isPresent
                      ? Icons.check_circle_outline
                      : isAbsent
                          ? Icons.cancel_outlined
                          : Icons.help_outline,
                  color: statusColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  date == null
                      ? '-'
                      : _formatDateTime(
                          date,
                          l10n,
                        ),
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(l10n.login),
        ),
      );
    }

    final studentReference =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('students')
            .doc(studentId);

    final attendanceReference =
        studentReference.collection('attendance');

    final paymentReference =
        studentReference.collection('payments');

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
        title: Text(
          l10n.studentDetails,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: studentReference.snapshots(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          if (studentSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '${l10n.somethingWentWrong}\n\n${studentSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          if (!studentSnapshot.hasData ||
              !studentSnapshot.data!.exists) {
            return Center(
              child: Text(
                l10n.noStudentsFound,
                style: const TextStyle(
                  color: greyColor,
                  fontSize: 15,
                ),
              ),
            );
          }

          final studentData =
              studentSnapshot.data!.data() ?? {};

          final name =
              studentData['name']?.toString() ??
                  l10n.student;

          final phone =
              studentData['phone']?.toString() ?? '';

          final grade =
              studentData['grade']?.toString() ?? '';

          final subject =
              studentData['subject']?.toString() ?? '';

          final parentName =
              studentData['parentName']?.toString() ??
                  '';

          final parentPhone =
              studentData['parentPhone']?.toString() ??
                  '';

          final notes =
              studentData['notes']?.toString() ?? '';

          final createdAt =
              studentData['createdAt'];

          final schedules =
              _getStudentSchedules(studentData);

          final displayGrade =
              _localizedGrade(grade, l10n);

          final displaySubject =
              _localizedSubject(subject, l10n);

          return StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: attendanceReference.snapshots(),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: primaryGreen,
                  ),
                );
              }

              if (attendanceSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '${l10n.somethingWentWrong}\n\n${attendanceSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }

              return StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream: paymentReference.snapshots(),
                builder: (context, paymentSnapshot) {
                  if (paymentSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primaryGreen,
                      ),
                    );
                  }

                  if (paymentSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(20),
                        child: Text(
                          '${l10n.somethingWentWrong}\n\n${paymentSnapshot.error}',
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

                  final attendanceDocs =
                      attendanceSnapshot.data?.docs ??
                          [];

                  final paymentDocs =
                      paymentSnapshot.data?.docs ??
                          [];

                  int presentCount = 0;
                  int absentCount = 0;
                  int paidSessions = 0;

                  final List<
                          Map<String, dynamic>>
                      attendanceHistory = [];

                  final List<
                          Map<String, dynamic>>
                      paymentHistory = [];

                  // ==========================
                  // ATTENDANCE
                  // ==========================

                  for (final record
                      in attendanceDocs) {
                    final data = record.data();

                    final status =
                        (data['attendance'] ??
                                data['status'] ??
                                'Not Marked')
                            .toString();

                    if (status == 'Present') {
                      presentCount++;

                      attendanceHistory.add({
                        'data': data,
                        'id': record.id,
                      });
                    } else if (status == 'Absent') {
                      absentCount++;

                      attendanceHistory.add({
                        'data': data,
                        'id': record.id,
                      });
                    }
                  }

                  // ==========================
                  // PAYMENT
                  // ==========================

                  for (final record
                      in paymentDocs) {
                    final data = record.data();

                    final paidValue =
                        data['paid'] ??
                            data['payment'];

                    final paid =
                        paidValue == true ||
                        paidValue
                                ?.toString()
                                .toLowerCase() ==
                            'true';

                    if (paid) {
                      paidSessions++;

                      paymentHistory.add({
                        'data': data,
                        'id': record.id,
                      });
                    }
                  }

                  // ==========================
                  // SORT
                  // ==========================

                  attendanceHistory.sort(
                    (a, b) {
                      final dateA =
                          _getDateFromData(
                        a['data']
                            as Map<String, dynamic>,
                      );

                      final dateB =
                          _getDateFromData(
                        b['data']
                            as Map<String, dynamic>,
                      );

                      if (dateA == null &&
                          dateB == null) {
                        return 0;
                      }

                      if (dateA == null) {
                        return 1;
                      }

                      if (dateB == null) {
                        return -1;
                      }

                      return dateB.compareTo(dateA);
                    },
                  );

                  paymentHistory.sort(
                    (a, b) {
                      final dateA =
                          _getDateFromData(
                        a['data']
                            as Map<String, dynamic>,
                      );

                      final dateB =
                          _getDateFromData(
                        b['data']
                            as Map<String, dynamic>,
                      );

                      if (dateA == null &&
                          dateB == null) {
                        return 0;
                      }

                      if (dateA == null) {
                        return 1;
                      }

                      if (dateB == null) {
                        return -1;
                      }

                      return dateB.compareTo(dateA);
                    },
                  );

                  return ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      30,
                    ),
                    children: [
                      // ==========================
                      // STUDENT HEADER
                      // ==========================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(18),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            20,
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
                            Container(
                              width: 72,
                              height: 72,
                              decoration:
                                  BoxDecoration(
                                color: softGreen,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child:
                                  const Icon(
                                Icons
                                    .person_rounded,
                                color:
                                    primaryGreen,
                                size: 40,
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              name,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color:
                                    textColor,
                                fontSize: 22,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            if (subject
                                .isNotEmpty) ...[
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                displaySubject,
                                style:
                                    const TextStyle(
                                  color:
                                      primaryGreen,
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],

                            const SizedBox(
                              height: 12,
                            ),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    lightGreen,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                '${l10n.startTime}: ${_formatDate(createdAt, l10n)}',
                                style:
                                    const TextStyle(
                                  color:
                                      primaryGreen,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==========================
                      // STATS
                      // ==========================

                      Row(
                        children: [
                          _buildStatCard(
                            icon: Icons
                                .check_circle_outline,
                            value:
                                presentCount
                                    .toString(),
                            title:
                                l10n.present,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            icon: Icons
                                .cancel_outlined,
                            value:
                                absentCount
                                    .toString(),
                            title:
                                l10n.absent,
                            iconColor:
                                Colors.red,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            icon: Icons
                                .payments_outlined,
                            value:
                                paidSessions
                                    .toString(),
                            title:
                                l10n.paid,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // ==========================
                      // PAYMENT SUMMARY
                      // ==========================

                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(
                          13,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          border: Border.all(
                            color:
                                const Color(
                              0xFFE0EDE2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .receipt_long_outlined,
                              color:
                                  primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            Expanded(
                              child: Text(
                                l10n.paid,
                                style:
                                    const TextStyle(
                                  color:
                                      greyColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              paidSessions
                                  .toString(),
                              style:
                                  const TextStyle(
                                color:
                                    textColor,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ==========================
                      // STUDENT INFORMATION
                      // ==========================

                      _buildInfoCard(
                        title:
                            l10n.studentDetails,
                        children: [
                          _buildInfoRow(
                            icon:
                                Icons.phone_outlined,
                            title:
                                l10n.phone,
                            value:
                                phone,
                          ),
                          _buildInfoRow(
                            icon:
                                Icons.school_outlined,
                            title:
                                l10n.grade,
                            value:
                                displayGrade,
                          ),
                          _buildInfoRow(
                            icon:
                                Icons
                                    .menu_book_outlined,
                            title:
                                l10n.subject,
                            value:
                                displaySubject,
                          ),
                        ],
                      ),

                      // ==========================
                      // CLASS SCHEDULES
                      // ==========================

                      _buildInfoCard(
                        title: l10n.schedule,
                        children: [
                          if (schedules.isEmpty)
                            Text(
                              '-',
                              style:
                                  const TextStyle(
                                color:
                                    greyColor,
                                fontSize: 13,
                              ),
                            )
                          else
                            ...schedules.map(
                              (schedule) =>
                                  _buildScheduleCard(
                                schedule,
                                l10n,
                              ),
                            ),
                        ],
                      ),

                      // ==========================
                      // PARENT / GUARDIAN
                      // ==========================

                      _buildInfoCard(
                        title:
                            l10n.parentName,
                        children: [
                          _buildInfoRow(
                            icon:
                                Icons
                                    .person_outline,
                            title:
                                l10n.parentName,
                            value:
                                parentName,
                          ),
                          _buildInfoRow(
                            icon:
                                Icons.phone_outlined,
                            title:
                                l10n.parentPhone,
                            value:
                                parentPhone,
                          ),
                        ],
                      ),

                      // ==========================
                      // NOTES
                      // ==========================

                      if (notes.isNotEmpty)
                        _buildInfoCard(
                          title:
                              l10n.notes,
                          children: [
                            Container(
                              width:
                                  double.infinity,
                              padding:
                                  const EdgeInsets
                                      .all(12),
                              decoration:
                                  BoxDecoration(
                                color:
                                    lightGreen,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),
                              child: Text(
                                notes,
                                style:
                                    const TextStyle(
                                  color:
                                      textColor,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // ==========================
                      // PAYMENT HISTORY
                      // ==========================

                      _buildInfoCard(
                        title:
                            l10n.payment,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons
                                    .payments_outlined,
                                color:
                                    primaryGreen,
                                size: 18,
                              ),
                              const SizedBox(
                                width: 7,
                              ),
                              Text(
                                '$paidSessions ${l10n.paid}',
                                style:
                                    const TextStyle(
                                  color:
                                      primaryGreen,
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          _buildPaymentHistory(
                            paymentHistory,
                            l10n,
                          ),
                        ],
                      ),

                      // ==========================
                      // ATTENDANCE HISTORY
                      // ==========================

                      _buildInfoCard(
                        title:
                            l10n.attendance,
                        children: [
                          _buildAttendanceHistory(
                            attendanceHistory,
                            l10n,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

