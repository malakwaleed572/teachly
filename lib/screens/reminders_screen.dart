
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/core/notifications/notification_service.dart';

import 'add_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyText = Color(0xFF777777);

  CollectionReference<Map<String, dynamic>> _remindersCollection() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('reminders');
  }

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

  Future<void> _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddReminderScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _editReminder(
    String reminderId,
    Map<String, dynamic> reminderData,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(
          reminderId: reminderId,
          reminderData: reminderData,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteReminder(
    String reminderId,
    String title,
  ) async {
    final l10n = AppLocalizations.of(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            l10n.delete,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$title"?',
            style: const TextStyle(
              color: greyText,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: greyText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      final notificationId =
          _notificationIdFromString(reminderId);

      // Cancel the local notification first.
      await NotificationService.instance.cancelReminder(
        notificationId,
      );

      // Then delete the reminder from Firestore.
      await _remindersCollection()
          .doc(reminderId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.deletedSuccessfully),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.somethingWentWrong}: $e',
          ),
        ),
      );
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final date = timestamp.toDate();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: lightGreen,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.classReminders,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: user == null
          ? Center(
              child: Text(
                l10n.somethingWentWrong,
                style: const TextStyle(
                  color: greyText,
                  fontSize: 16,
                ),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _remindersCollection()
                  .orderBy(
                    'reminderDate',
                    descending: false,
                  )
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
                        '${l10n.somethingWentWrong}\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: greyText,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }

                final documents = snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    90,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];

                    final data = doc.data();

                    return _buildReminderCard(
                      context,
                      doc.id,
                      data,
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 45,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noReminders,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addReminder,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    String reminderId,
    Map<String, dynamic> data,
  ) {
    final l10n = AppLocalizations.of(context);

    final title = data['title']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';

    final timestamp = data['reminderDate'] is Timestamp
        ? data['reminderDate'] as Timestamp
        : null;

    final isCompleted = data['isCompleted'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final newCompletedState = !isCompleted;

                final notificationId =
                    _notificationIdFromString(reminderId);

                try {
                  if (newCompletedState) {
                    // Completed → cancel notification.
                    await NotificationService.instance
                        .cancelReminder(
                      notificationId,
                    );
                  } else {
                    // Uncompleted → schedule notification again.
                    if (timestamp != null) {
                      final reminderDateTime =
                          timestamp.toDate();

                      await NotificationService.instance
                          .scheduleReminder(
                        notificationId: notificationId,
                        title: title,
                        description: description.isEmpty
                            ? null
                            : description,
                        dateTime: reminderDateTime,
                      );
                    }
                  }

                  await _remindersCollection()
                      .doc(reminderId)
                      .update({
                    'isCompleted': newCompletedState,
                    'updatedAt':
                        FieldValue.serverTimestamp(),
                  });
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        '${l10n.somethingWentWrong}: $e',
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? primaryGreen
                      : softGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : Icons.notifications_none_rounded,
                  color: isCompleted
                      ? Colors.white
                      : primaryGreen,
                  size: 23,
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: greyText,
                        height: 1.4,
                      ),
                    ),
                  ],

                  if (timestamp != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(timestamp),
                          style: const TextStyle(
                            fontSize: 13,
                            color: primaryGreen,
                            fontWeight: FontWeight.w600,
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
                Icons.more_vert,
                color: greyText,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _editReminder(
                    reminderId,
                    data,
                  );
                } else if (value == 'delete') {
                  _deleteReminder(
                    reminderId,
                    title,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      Text(l10nSafe(context).edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(l10nSafe(context).delete),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

AppLocalizations l10nSafe(BuildContext context) {
  return AppLocalizations.of(context);
}

