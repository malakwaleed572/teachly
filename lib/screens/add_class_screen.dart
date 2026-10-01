
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teachly/core/notifications/notification_service.dart';

class AddClassScreen extends StatefulWidget {
  final String? classId;
  final Map<String, dynamic>? classData;
  final DateTime? selectedDate;

  const AddClassScreen({
    super.key,
    this.classId,
    this.classData,
    this.selectedDate,
  });

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);

  final TextEditingController roomController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String? selectedSubject;
  String? selectedGrade;
  String? selectedDay;

  DateTime? selectedDate;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool isSaving = false;

  final List<String> subjects = [
    'English',
    'Math',
    'Science',
    'Arabic',
  ];

  final List<String> grades = [
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  final List<String> days = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  bool get isEditMode => widget.classId != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode && widget.classData != null) {
      _loadClassData();
    } else {
      selectedDate = widget.selectedDate;

      if (selectedDate != null) {
        selectedDay = _getDayName(selectedDate!);
      }
    }
  }

  // =========================================================
  // DATE HELPERS
  // =========================================================

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
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

  // =========================================================
  // LOAD CLASS FOR EDIT
  // =========================================================

  void _loadClassData() {
    final data = widget.classData!;

    selectedSubject = data['subject'];
    selectedGrade = data['grade'];
    selectedDay = data['day'];

    final savedDate = data['dateKey'];

    if (savedDate != null) {
      final parts = savedDate.toString().split('-');

      if (parts.length == 3) {
        selectedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } else {
      selectedDate = widget.selectedDate;
    }

    roomController.text = data['room'] ?? '';
    noteController.text = data['note'] ?? '';

    startTime = _parseTime(data['startTime']);
    endTime = _parseTime(data['endTime']);
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;

    final String time = value.toString().trim();

    try {
      final parts = time.split(' ');
      final timePart = parts[0];

      final period =
          parts.length > 1 ? parts[1].toUpperCase() : 'AM';

      final timeParts = timePart.split(':');

      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    roomController.dispose();
    noteController.dispose();
    super.dispose();
  }

  // =========================================================
  // TIME
  // =========================================================

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? startTime ?? TimeOfDay.now()
          : endTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      if (isStartTime) {
        startTime = pickedTime;
      } else {
        endTime = pickedTime;
      }
    });
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    final hour =
        time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // =========================================================
  // NOTIFICATION ID
  // =========================================================

  int _notificationId(String classId) {
    return classId.hashCode & 0x7fffffff;
  }

  // =========================================================
  // CLASS NOTIFICATION
  // =========================================================

  Future<void> _scheduleClassNotification({
    required String classId,
    required String subject,
    required String grade,
    required String day,
    required TimeOfDay startTime,
    String? room,
  }) async {
    final String formattedStartTime =
        _formatTime(startTime);

    final String roomText =
        room != null && room.trim().isNotEmpty
            ? ' • Room ${room.trim()}'
            : '';

    await NotificationService.instance
        .scheduleClassNotification(
      notificationId: _notificationId(classId),
      subject: '$subject • $grade$roomText',
      day: day,
      startTime: formattedStartTime,
    );
  }

  // =========================================================
  // SAVE CLASS
  // =========================================================

  Future<void> _saveClass() async {
  if (selectedSubject == null ||
      selectedGrade == null ||
      selectedDay == null ||
      startTime == null ||
      endTime == null) {
    _showMessage(
      'Please complete all required fields.',
    );
    return;
  }

  if (_timeToMinutes(endTime!) <=
      _timeToMinutes(startTime!)) {
    _showMessage(
      'End time must be after start time.',
    );
    return;
  }

  final User? user =
      FirebaseAuth.instance.currentUser;

  if (user == null) {
    _showMessage('Please login first.');
    return;
  }

  setState(() {
    isSaving = true;
  });

  try {
    final classData = {
      'userId': user.uid,
      'subject': selectedSubject,
      'grade': selectedGrade,
      'day': selectedDay,
      if (selectedDate != null)
        'dateKey': _formatDateKey(selectedDate!),
      'startTime': _formatTime(startTime),
      'endTime': _formatTime(endTime),
      'startMinutes': _timeToMinutes(startTime!),
      'endMinutes': _timeToMinutes(endTime!),
      'room': roomController.text.trim(),
      'note': noteController.text.trim(),
    };

    String classId;

    // =====================================================
    // EDIT CLASS
    // =====================================================

    if (isEditMode) {
      classId = widget.classId!;

      try {
        await NotificationService.instance.cancelReminder(
          _notificationId(classId),
        );
      } catch (e) {
        debugPrint(
          'Teachly: Could not cancel old class notification: $e',
        );
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update(classData);
    }

    // =====================================================
    // ADD CLASS
    // =====================================================

    else {
      final DocumentReference<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection('classes')
              .add({
        ...classData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      classId = doc.id;
    }

    // =====================================================
    // SCHEDULE NOTIFICATION
    // =====================================================

    try {
      await _scheduleClassNotification(
        classId: classId,
        subject: selectedSubject!,
        grade: selectedGrade!,
        day: selectedDay!,
        startTime: startTime!,
        room: roomController.text.trim(),
      );
    } catch (e, stackTrace) {
      debugPrint(
        '==========================================',
      );
      debugPrint(
        'Teachly: CLASS NOTIFICATION ERROR',
      );
      debugPrint(
        'Error: $e',
      );
      debugPrint(
        'StackTrace: $stackTrace',
      );
      debugPrint(
        '==========================================',
      );
    }

    if (!mounted) return;

    _showMessage(
      isEditMode
          ? 'Class updated successfully!'
          : 'Class saved successfully!',
      isError: false,
    );

    Navigator.pop(context, true);
  } on FirebaseException catch (e) {
    if (!mounted) return;

    debugPrint(
      'Teachly Firebase ERROR: ${e.code} - ${e.message}',
    );

    _showMessage(
      e.message ??
          'Something went wrong while saving the class.',
    );
  } catch (e, stackTrace) {
    debugPrint(
      '==========================================',
    );
    debugPrint(
      'Teachly SAVE CLASS ERROR',
    );
    debugPrint(
      'Error: $e',
    );
    debugPrint(
      'StackTrace: $stackTrace',
    );
    debugPrint(
      '==========================================',
    );

    if (!mounted) return;

    _showMessage(
      'Something went wrong while saving the class.',
    );
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }
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
    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEditMode
              ? 'Edit Class'
              : 'Add Class',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode
                  ? 'Edit Class Information'
                  : 'Class Information',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _buildLabel('Subject'),
            const SizedBox(height: 7),

            _buildDropdown(
              value: selectedSubject,
              hint: 'Select subject',
              items: subjects,
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
            ),

            const SizedBox(height: 18),

            _buildLabel('Grade'),
            const SizedBox(height: 7),

            _buildDropdown(
              value: selectedGrade,
              hint: 'Select grade',
              items: grades,
              onChanged: (value) {
                setState(() {
                  selectedGrade = value;
                });
              },
            ),

            const SizedBox(height: 18),

            _buildLabel('Day'),
            const SizedBox(height: 7),

            _buildDropdown(
              value: selectedDay,
              hint: 'Select day',
              items: days,
              onChanged: (value) {
                setState(() {
                  selectedDay = value;
                });
              },
            ),

            const SizedBox(height: 18),

            _buildLabel('Time'),
            const SizedBox(height: 7),

            Row(
              children: [
                Expanded(
                  child: _buildTimeField(
                    title: 'Start Time',
                    value: _formatTime(startTime),
                    onTap: () =>
                        _selectTime(true),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildTimeField(
                    title: 'End Time',
                    value: _formatTime(endTime),
                    onTap: () =>
                        _selectTime(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildLabel('Room'),
            const SizedBox(height: 7),

            _buildTextField(
              controller: roomController,
              hint: 'Enter room number',
              icon: Icons.meeting_room_outlined,
            ),

            const SizedBox(height: 18),

            _buildLabel('Note'),
            const SizedBox(height: 7),

            _buildTextField(
              controller: noteController,
              hint: 'Add a note...',
              icon: Icons.notes_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    isSaving ? null : _saveClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      primaryGreen.withValues(
                    alpha: 0.6,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditMode
                            ? 'Update Class'
                            : 'Save Class',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LABEL
  // =========================================================

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // =========================================================
  // DROPDOWN
  // =========================================================

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E2E2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // =========================================================
  // TIME FIELD
  // =========================================================

  Widget _buildTimeField({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E2E2),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: primaryGreen,
                  size: 18,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: primaryGreen,
          size: 21,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE2E2E2),
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE2E2E2),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

