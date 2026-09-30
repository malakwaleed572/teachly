import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:teachly/core/localization/app_localization.dart';

class AddStudentScreen extends StatefulWidget {
  final String? studentId;
  final Map<String, dynamic>? studentData;

  const AddStudentScreen({
    super.key,
    this.studentId,
    this.studentData,
  });

  bool get isEditing => studentId != null;

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _ClassSchedule {
  String? day;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  _ClassSchedule({
    this.day,
    this.startTime,
    this.endTime,
  });
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _parentNameController =
      TextEditingController();

  final TextEditingController _parentPhoneController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String? selectedGrade;
  String? selectedSubject;

  int numberOfClasses = 1;

  bool isLoading = false;

  final List<_ClassSchedule> schedules = [
    _ClassSchedule(),
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

  final List<String> subjects = [
    'English',
    'Math',
    'Science',
    'Arabic',
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

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.studentData != null) {
      _loadStudentData();
    }
  }

  // =========================================================
  // LOAD EXISTING STUDENT
  // =========================================================

  void _loadStudentData() {
    final data = widget.studentData!;

    _nameController.text =
        data['name']?.toString() ?? '';

    _phoneController.text =
        data['phone']?.toString() ?? '';

    _parentNameController.text =
        data['parentName']?.toString() ?? '';

    _parentPhoneController.text =
        data['parentPhone']?.toString() ?? '';

    _notesController.text =
        data['notes']?.toString() ?? '';

    selectedGrade =
        data['grade']?.toString();

    selectedSubject =
        data['subject']?.toString();

    // -------------------------------------------------------
    // NEW FORMAT
    // -------------------------------------------------------

    final savedSchedules = data['schedules'];

    if (savedSchedules is List &&
        savedSchedules.isNotEmpty) {
      schedules.clear();

      for (final item in savedSchedules) {
        if (item is Map) {
          schedules.add(
            _ClassSchedule(
              day: item['day']?.toString(),
              startTime: item['startTime'] != null
                  ? _parseTime(
                      item['startTime'].toString(),
                    )
                  : null,
              endTime: item['endTime'] != null
                  ? _parseTime(
                      item['endTime'].toString(),
                    )
                  : null,
            ),
          );
        }
      }

      numberOfClasses = schedules.length.clamp(1, 2);
    }

    // -------------------------------------------------------
    // OLD FORMAT
    // -------------------------------------------------------

    else {
      final oldDay =
          data['day']?.toString();

      final oldStart =
          data['startTime']?.toString();

      final oldEnd =
          data['endTime']?.toString();

      schedules.clear();

      schedules.add(
        _ClassSchedule(
          day: oldDay,
          startTime:
              oldStart != null
                  ? _parseTime(oldStart)
                  : null,
          endTime:
              oldEnd != null
                  ? _parseTime(oldEnd)
                  : null,
        ),
      );

      numberOfClasses = 1;
    }
  }

  // =========================================================
  // TIME HELPERS
  // =========================================================

  TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');

      if (parts.length < 2) {
        return null;
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$hour:$minute $period';
  }

  String _saveTime(TimeOfDay time) {
    final hour =
        time.hour.toString().padLeft(2, '0');

    final minute =
        time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // =========================================================
  // LOCALIZATION
  // =========================================================

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

  // =========================================================
  // CLASS COUNT
  // =========================================================

  void _changeNumberOfClasses(int value) {
    setState(() {
      numberOfClasses = value;

      if (value == 1) {
        if (schedules.isEmpty) {
          schedules.add(_ClassSchedule());
        }

        schedules.removeRange(
          1,
          schedules.length,
        );
      } else {
        while (schedules.length < 2) {
          schedules.add(_ClassSchedule());
        }
      }
    });
  }

  // =========================================================
  // TIME PICKERS
  // =========================================================

  Future<void> _selectStartTime(
    int index,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          schedules[index].startTime ??
              TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        schedules[index].startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(
    int index,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          schedules[index].endTime ??
              schedules[index].startTime ??
              TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        schedules[index].endTime = picked;
      });
    }
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _saveStudent() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedGrade == null) {
      _showMessage(l10n.selectGrade);
      return;
    }

    if (selectedSubject == null) {
      _showMessage(l10n.selectSubject);
      return;
    }

    // -------------------------------------------------------
    // VALIDATE SCHEDULES
    // -------------------------------------------------------

    for (int i = 0; i < numberOfClasses; i++) {
      final schedule = schedules[i];

      if (schedule.day == null) {
        _showMessage(
          'Please select the day for Class ${i + 1}',
        );
        return;
      }

      if (schedule.startTime == null) {
        _showMessage(
          'Please select the start time for Class ${i + 1}',
        );
        return;
      }

      if (schedule.endTime == null) {
        _showMessage(
          'Please select the end time for Class ${i + 1}',
        );
        return;
      }
    }

    // -------------------------------------------------------
    // PREVENT SAME DAY
    // -------------------------------------------------------

    if (numberOfClasses == 2) {
      final firstDay = schedules[0].day;
      final secondDay = schedules[1].day;

      if (firstDay == secondDay) {
        _showMessage(
          'Please select two different days',
        );
        return;
      }
    }

    final user = _auth.currentUser;

    if (user == null) {
      _showMessage(l10n.login);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // -----------------------------------------------------
      // BUILD SCHEDULES
      // -----------------------------------------------------

      final List<Map<String, dynamic>>
          savedSchedules = [];

      for (int i = 0;
          i < numberOfClasses;
          i++) {
        final schedule = schedules[i];

        savedSchedules.add({
          'day': schedule.day,
          'startTime':
              _saveTime(schedule.startTime!),
          'endTime':
              _saveTime(schedule.endTime!),
        });
      }

      // -----------------------------------------------------
      // LEGACY FIELDS
      //
      // We keep these so old parts of the app don't break.
      // They represent the FIRST class.
      // -----------------------------------------------------

      final firstSchedule =
          savedSchedules.first;

      final studentData = {
        'name':
            _nameController.text.trim(),

        'phone':
            _phoneController.text.trim(),

        'grade':
            selectedGrade,

        'subject':
            selectedSubject,

        'schedules':
            savedSchedules,

        // Legacy fields
        'day':
            firstSchedule['day'],

        'startTime':
            firstSchedule['startTime'],

        'endTime':
            firstSchedule['endTime'],

        'parentName':
            _parentNameController.text.trim(),

        'parentPhone':
            _parentPhoneController.text.trim(),

        'notes':
            _notesController.text.trim(),

        'numberOfClasses':
            numberOfClasses,
      };

      final studentsCollection =
          _firestore
              .collection('users')
              .doc(user.uid)
              .collection('students');

      if (widget.isEditing) {
        await studentsCollection
            .doc(widget.studentId)
            .update(studentData);
      } else {
        await studentsCollection.add({
          ...studentData,
          'attendance': 'Not Marked',
          'payment': 'Not Paid',
          'createdAt':
              FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.savedSuccessfully,
          ),
          backgroundColor:
              const Color(0xFF2F8F57),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        '${l10n.somethingWentWrong}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2F8F57);
    const background = Color(0xFFF1FFF3);

    final l10n =
        AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          widget.isEditing
              ? l10n.editStudent
              : l10n.addStudent,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding:
              const EdgeInsets.all(20),

          children: [
            _buildSectionTitle(
              l10n.studentDetails,
            ),

            const SizedBox(height: 12),

            _buildTextField(
              controller:
                  _nameController,
              label:
                  l10n.studentName,
              hint:
                  l10n.enterName,
              icon:
                  Icons.person_outline,
              required: true,
            ),

            const SizedBox(height: 14),

            _buildTextField(
              controller:
                  _phoneController,
              label:
                  l10n.phone,
              hint:
                  l10n.enterPhone,
              icon:
                  Icons.phone_outlined,
              keyboardType:
                  TextInputType.phone,
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label:
                        l10n.grade,
                    hint:
                        l10n.selectGrade,
                    value:
                        selectedGrade,
                    items:
                        grades,
                    icon:
                        Icons.school_outlined,
                    onChanged:
                        (value) {
                      setState(() {
                        selectedGrade =
                            value;
                      });
                    },
                    itemLabel:
                        (item) =>
                            _localizedGrade(
                      item,
                      l10n,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: _buildDropdown(
                    label:
                        l10n.subject,
                    hint:
                        l10n.selectSubject,
                    value:
                        selectedSubject,
                    items:
                        subjects,
                    icon:
                        Icons.menu_book_outlined,
                    onChanged:
                        (value) {
                      setState(() {
                        selectedSubject =
                            value;
                      });
                    },
                    itemLabel:
                        (item) =>
                            _localizedSubject(
                      item,
                      l10n,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 26,
            ),

            _buildSectionTitle(
              l10n.mySchedule,
            ),

            const SizedBox(
              height: 12,
            ),

            // =================================================
            // NUMBER OF CLASSES
            // =================================================

            _buildClassCountSelector(),

            const SizedBox(
              height: 18,
            ),

            // =================================================
            // CLASS SCHEDULES
            // =================================================

            ...List.generate(
              numberOfClasses,
              (index) {
                return _buildClassSchedule(
                  index,
                  l10n,
                );
              },
            ),

            const SizedBox(
              height: 26,
            ),

            _buildSectionTitle(
              l10n.parentName,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildTextField(
              controller:
                  _parentNameController,
              label:
                  l10n.parentName,
              hint:
                  l10n.enterName,
              icon:
                  Icons.person_outline,
            ),

            const SizedBox(
              height: 14,
            ),

            _buildTextField(
              controller:
                  _parentPhoneController,
              label:
                  l10n.parentPhone,
              hint:
                  l10n.enterPhone,
              icon:
                  Icons.phone_outlined,
              keyboardType:
                  TextInputType.phone,
            ),

            const SizedBox(
              height: 26,
            ),

            _buildSectionTitle(
              l10n.notes,
            ),

            const SizedBox(
              height: 12,
            ),

            _buildTextField(
              controller:
                  _notesController,
              label:
                  l10n.notes,
              hint:
                  l10n.notes,
              icon:
                  Icons.notes_outlined,
              maxLines: 4,
            ),

            const SizedBox(
              height: 30,
            ),

            SizedBox(
              height: 52,

              child: ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : _saveStudent,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      green,
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      green.withOpacity(
                    0.6,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  elevation: 0,
                ),

                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          color:
                              Colors.white,
                          strokeWidth:
                              2.5,
                        ),
                      )
                    : Text(
                        widget.isEditing
                            ? l10n.updateStudent
                            : l10n.saveStudent,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CLASS COUNT SELECTOR
  // =========================================================

  Widget _buildClassCountSelector() {
    const green = Color(0xFF2F8F57);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Classes per week',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF202020),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        Container(
          height: 55,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color:
                  Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_repeat_outlined,
                color: green,
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Text(
                  'Number of classes',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF202020),
                  ),
                ),
              ),

              DropdownButtonHideUnderline(
                child:
                    DropdownButton<int>(
                  value:
                      numberOfClasses,
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Text(
                        '1 class',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(
                        '2 classes',
                      ),
                    ),
                  ],
                  onChanged:
                      (value) {
                    if (value != null) {
                      _changeNumberOfClasses(
                        value,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // CLASS SCHEDULE CARD
  // =========================================================

  Widget _buildClassSchedule(
    int index,
    AppLocalizations l10n,
  ) {
    const green = Color(0xFF2F8F57);

    final schedule =
        schedules[index];

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFDDEBDD),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFE7F5E9),
                  shape:
                      BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style:
                        const TextStyle(
                      color: green,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Text(
                'Class ${index + 1}',
                style:
                    const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF202020),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          _buildDropdown(
            label: 'Day',
            hint: 'Select day',
            value:
                schedule.day,
            items: days,
            icon:
                Icons.calendar_today_outlined,
            onChanged:
                (value) {
              setState(() {
                schedule.day =
                    value;
              });
            },
            itemLabel:
                (item) =>
                    _localizedDay(
              item,
              l10n,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildTimeSelector(
                  label:
                      'Start Time',
                  value:
                      schedule.startTime,
                  icon:
                      Icons.access_time_outlined,
                  onTap:
                      () =>
                          _selectStartTime(
                    index,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _buildTimeSelector(
                  label:
                      'End Time',
                  value:
                      schedule.endTime,
                  icon:
                      Icons.access_time_filled_outlined,
                  onTap:
                      () =>
                          _selectEndTime(
                    index,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TIME SELECTOR
  // =========================================================

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const green = Color(0xFF2F8F57);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF202020),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          child: Container(
            height: 50,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: green,
                  size: 19,
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    value == null
                        ? 'Select'
                        : _formatTime(
                            value,
                          ),
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        TextStyle(
                      fontSize: 12,
                      color: value ==
                              null
                          ? Colors
                              .grey
                              .shade500
                          : const Color(
                              0xFF202020,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style:
          const TextStyle(
        color:
            Color(0xFF2F6F45),
        fontSize: 15,
        fontWeight:
            FontWeight.bold,
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    final l10n =
        AppLocalizations.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF202020),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        TextFormField(
          controller: controller,
          keyboardType:
              keyboardType,
          maxLines:
              maxLines,

          validator: required
              ? (value) {
                  if (value ==
                          null ||
                      value
                          .trim()
                          .isEmpty) {
                    return l10n
                        .pleaseEnterName;
                  }

                  return null;
                }
              : null,

          decoration:
              InputDecoration(
            hintText: hint,

            hintStyle:
                TextStyle(
              color:
                  Colors.grey.shade500,
              fontSize: 13,
            ),

            prefixIcon:
                Icon(
              icon,
              color:
                  const Color(
                0xFF2F8F57,
              ),
            ),

            filled: true,
            fillColor:
                Colors.white,

            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
              vertical: 14,
            ),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  BorderSide(
                color:
                    Colors.grey.shade300,
              ),
            ),

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  BorderSide(
                color:
                    Colors.grey.shade300,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFF2F8F57),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // DROPDOWN
  // =========================================================

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    required String Function(String) itemLabel,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w600,
            color:
                Color(0xFF202020),
          ),
        ),

        const SizedBox(
          height: 7,
        ),

        DropdownButtonFormField<
            String>(
          value:
              items.contains(value)
                  ? value
                  : null,

          isExpanded:
              true,

          icon:
              const Icon(
            Icons
                .keyboard_arrow_down,
          ),

          decoration:
              InputDecoration(
            hintText: hint,

            hintStyle:
                TextStyle(
              color:
                  Colors.grey.shade500,
              fontSize: 12,
            ),

            prefixIcon:
                Icon(
              icon,
              color:
                  const Color(
                0xFF2F8F57,
              ),
              size: 20,
            ),

            filled: true,
            fillColor:
                Colors.white,

            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 10,
              vertical: 12,
            ),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  BorderSide(
                color:
                    Colors.grey.shade300,
              ),
            ),

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  BorderSide(
                color:
                    Colors.grey.shade300,
              ),
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              borderSide:
                  const BorderSide(
                color:
                    Color(0xFF2F8F57),
                width: 1.5,
              ),
            ),
          ),

          items:
              items.map(
            (item) {
              return DropdownMenuItem<
                  String>(
                value: item,
                child: Text(
                  itemLabel(item),
                  style:
                      const TextStyle(
                    fontSize: 12,
                  ),
                ),
              );
            },
          ).toList(),

          onChanged:
              onChanged,
        ),
      ],
    );
  }
}