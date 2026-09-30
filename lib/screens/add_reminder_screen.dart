import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/core/notifications/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  final String? reminderId;
  final Map<String, dynamic>? reminderData;

  const AddReminderScreen({
    super.key,
    this.reminderId,
    this.reminderData,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyText = Color(0xFF777777);

  bool get isEditing => widget.reminderId != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.reminderData?['title']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.reminderData?['description']?.toString() ?? '',
    );

    final reminderTimestamp = widget.reminderData?['reminderDate'];

    if (reminderTimestamp is Timestamp) {
      final date = reminderTimestamp.toDate();

      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      _selectedTime = TimeOfDay(
        hour: date.hour,
        minute: date.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _remindersCollection() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('reminders');
  }

  // Convert Firestore document ID to a stable notification ID.
  int _notificationIdFromString(String value) {
    int hash = 0;

    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }

    if (hash == 0) {
      return 1;
    }

    return hash;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 5,
        12,
        31,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  DateTime? _getReminderDateTime() {
    if (_selectedDate == null || _selectedTime == null) {
      return null;
    }

    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).selectReminderDateTime,
          ),
        ),
      );

      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final reminderDateTime = _getReminderDateTime();

      if (reminderDateTime == null) {
        return;
      }

      final title = _titleController.text.trim();

      final description = _descriptionController.text.trim();

      late String reminderId;

      if (isEditing) {
        reminderId = widget.reminderId!;

        final notificationId =
            _notificationIdFromString(reminderId);

        // Cancel the old scheduled notification first.
        await NotificationService.instance.cancelReminder(
          notificationId,
        );

        await _remindersCollection()
            .doc(reminderId)
            .update({
          'title': title,
          'description': description,
          'reminderDate': Timestamp.fromDate(
            reminderDateTime,
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final reminderDoc = await _remindersCollection().add({
          'title': title,
          'description': description,
          'reminderDate': Timestamp.fromDate(
            reminderDateTime,
          ),
          'isCompleted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        reminderId = reminderDoc.id;
      }

      // Schedule the notification.
      final notificationId =
          _notificationIdFromString(reminderId);

      await NotificationService.instance.scheduleReminder(
        notificationId: notificationId,
        title: title,
        description: description.isEmpty ? null : description,
        dateTime: reminderDateTime,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context).somethingWentWrong}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate() {
    if (_selectedDate == null) {
      return '';
    }

    final date = _selectedDate!;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime() {
    if (_selectedTime == null) {
      return '';
    }

    return _selectedTime!.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEditing ? l10n.editReminder : l10n.addReminder,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reminderTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l10n.enterReminderTitle,
                    hintStyle: const TextStyle(
                      color: greyText,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.notifications_none_rounded,
                      color: primaryGreen,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterReminderTitle;
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.reminderDescription,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 7,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: l10n.enterReminderDescription,
                    hintStyle: const TextStyle(
                      color: greyText,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(
                        bottom: 65,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: primaryGreen,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryGreen,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  l10n.reminderDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPickerCard(
                  icon: Icons.calendar_today_outlined,
                  text: _selectedDate == null
                      ? l10n.selectReminderDate
                      : _formatDate(),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.reminderTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPickerCard(
                  icon: Icons.access_time_rounded,
                  text: _selectedTime == null
                      ? l10n.selectReminderTime
                      : _formatTime(),
                  onTap: _selectTime,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      disabledBackgroundColor:
                          primaryGreen.withOpacity(0.5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEditing
                                    ? Icons.save_rounded
                                    : Icons.add_rounded,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isEditing
                                    ? l10n.update
                                    : l10n.save,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerCard({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final isEmpty = text.isEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: softGreen,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: primaryGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: isEmpty ? greyText : textColor,
                  fontWeight: isEmpty
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: greyText,
            ),
          ],
        ),
      ),
    );
  }
}