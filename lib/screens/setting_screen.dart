import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:teachly/core/localization/app_localization.dart';
import 'package:teachly/core/localization/language_controller.dart';
import 'package:teachly/core/notifications/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final LanguageController languageController;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
    required this.languageController,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyColor = Color(0xFF777777);

  bool classReminders = true;
  bool generalNotifications = true;
  String selectedLanguage = 'English';
  bool isLoadingSettings = true;
  bool isDeletingAccount = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String get userName {
    final name = currentUser?.displayName;

    if (name != null && name.trim().isNotEmpty) {
      return name;
    }

    return 'User';
  }

  String get userEmail {
    final email = currentUser?.email;

    if (email != null && email.trim().isNotEmpty) {
      return email;
    }

    return 'No email';
  }

  DocumentReference<Map<String, dynamic>> get settingsReference {
    final uid = currentUser?.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('app_settings');
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoadingSettings = false;
        });
      }
      return;
    }

    try {
      final snapshot = await settingsReference.get();

      if (snapshot.exists) {
        final data = snapshot.data();

        if (mounted) {
          setState(() {
            classReminders =
                data?['classReminders'] ?? true;

            generalNotifications =
                data?['generalNotifications'] ?? true;

            selectedLanguage =
                data?['language'] ?? 'English';

            isLoadingSettings = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingSettings = false;
          });
        }
      }
    } catch (e) {
      debugPrint(
        'Error loading settings: $e',
      );

      if (mounted) {
        setState(() {
          isLoadingSettings = false;
        });
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    try {
      await settingsReference.set(
        {
          'classReminders': classReminders,
          'generalNotifications': generalNotifications,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint(
        'Error saving notification settings: $e',
      );
    }
  }

  Future<void> _showPersonalInformationDialog() async {
    final l10n = AppLocalizations.of(context);

    String newName = userName;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.personalInformation,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: userName,
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  newName = value;
                },
                decoration: InputDecoration(
                  labelText: l10n.name,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: primaryGreen,
                  ),
                  filled: true,
                  fillColor: lightGreen,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                initialValue: userEmail,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: primaryGreen,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: greyColor,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final name = newName.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.pleaseEnterName,
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await currentUser
                      ?.updateDisplayName(name);

                  final uid = currentUser?.uid;

                  if (uid != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .set(
                      {
                        'name': name,
                        'email': userEmail,
                      },
                      SetOptions(merge: true),
                    );
                  }

                  if (!mounted) return;

                  setState(() {});

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.personalInfoSaved,
                      ),
                    ),
                  );
                } catch (e) {
                  debugPrint(
                    'Error updating personal information: $e',
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.somethingWentWrong,
                      ),
                    ),
                  );
                }
              },
              child: Text(
                l10n.save,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final l10n = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.changePassword,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Text(
            '${l10n.passwordResetEmail}\n\n'
            '$userEmail\n\n'
            '${l10n.passwordResetInstructions}',
            style: const TextStyle(
              color: greyColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: greyColor,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final email = currentUser?.email;

                if (email == null ||
                    email.trim().isEmpty) {
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.noEmail,
                      ),
                    ),
                  );

                  return;
                }

                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(
                    email: email,
                  );

                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.passwordResetSent,
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  String message =
                      l10n.somethingWentWrong;

                  if (e.code == 'user-not-found') {
                    message = l10n.noAccount;
                  } else if (e.code == 'invalid-email') {
                    message = l10n.invalidEmail;
                  }

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.somethingWentWrong,
                      ),
                    ),
                  );
                }
              },
              child: Text(
                l10n.sendEmail,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLanguageDialog() async {
    String tempLanguage = selectedLanguage;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogBuildContext,
            setDialogState,
          ) {
            final l10n =
                AppLocalizations.of(dialogBuildContext);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
              title: Text(
                l10n.language,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'English',
                    groupValue: tempLanguage,
                    activeColor: primaryGreen,
                    title: Text(
                      l10n.english,
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempLanguage = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    value: 'Arabic',
                    groupValue: tempLanguage,
                    activeColor: primaryGreen,
                    title: Text(
                      l10n.arabic,
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempLanguage = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      color: greyColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await widget.languageController
                          .changeLanguage(
                        tempLanguage,
                      );

                      if (!mounted) return;

                      setState(() {
                        selectedLanguage =
                            tempLanguage;
                      });

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            l10n.languageSaved,
                          ),
                        ),
                      );
                    } catch (e) {
                      debugPrint(
                        'Error changing language: $e',
                      );
                    }
                  },
                  child: Text(
                    l10n.save,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showNotificationPreferencesDialog() async {
    bool tempClassReminders = classReminders;
    bool tempGeneralNotifications =
        generalNotifications;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            dialogBuildContext,
            setDialogState,
          ) {
            final l10n =
                AppLocalizations.of(dialogBuildContext);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                l10n.notificationPreferences,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: primaryGreen,
                    title: Text(
                      l10n.classReminders,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      l10n.classReminderDescription,
                    ),
                    value: tempClassReminders,
                    onChanged: (value) {
                      setDialogState(() {
                        tempClassReminders = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: primaryGreen,
                    title: Text(
                      l10n.generalNotifications,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      l10n.generalNotificationDescription,
                    ),
                    value: tempGeneralNotifications,
                    onChanged: (value) {
                      setDialogState(() {
                        tempGeneralNotifications =
                            value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      color: greyColor,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      classReminders =
                          tempClassReminders;

                      generalNotifications =
                          tempGeneralNotifications;
                    });

                    await _saveNotificationSettings();

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.notificationsSaved,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    l10n.save,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // DELETE ACCOUNT
  // =========================================================

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteStudentData(
    String uid,
  ) async {
    final studentsCollection = FirebaseFirestore
        .instance
        .collection('users')
        .doc(uid)
        .collection('students');

    final studentsSnapshot =
        await studentsCollection.get();

    for (final studentDoc in studentsSnapshot.docs) {
      await _deleteCollection(
        studentDoc.reference.collection('attendance'),
      );

      await _deleteCollection(
        studentDoc.reference.collection('payments'),
      );

      await studentDoc.reference.delete();
    }
  }

  Future<void> _deleteUserFirestoreData(
    String uid,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // Delete classes belonging to this user.
    final classesSnapshot = await firestore
        .collection('classes')
        .where(
          'userId',
          isEqualTo: uid,
        )
        .get();

    for (final classDoc in classesSnapshot.docs) {
      await classDoc.reference.delete();
    }

    final userReference = firestore
        .collection('users')
        .doc(uid);

    // Delete students and their nested attendance/payments.
    await _deleteStudentData(uid);

    // Delete reminders.
    await _deleteCollection(
      userReference.collection('reminders'),
    );

    // Delete notes if they exist.
    await _deleteCollection(
      userReference.collection('notes'),
    );

    // Delete settings.
    await _deleteCollection(
      userReference.collection('settings'),
    );

    // Finally delete the user document itself.
    await userReference.delete();
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);

    final isArabic = selectedLanguage == 'Arabic';

    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isArabic
                ? 'حذف الحساب'
                : 'Delete Account',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            isArabic
                ? 'هل أنت متأكد أنك تريد حذف حسابك؟ سيتم حذف بياناتك والحصص والطلاب والتذكيرات والإشعارات المجدولة نهائيًا. لا يمكن التراجع عن هذا الإجراء.'
                : 'Are you sure you want to delete your account? All your data, classes, students, reminders, and scheduled notifications will be permanently deleted. This action cannot be undone.',
            style: const TextStyle(
              color: greyColor,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: greyColor,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                isArabic
                    ? 'حذف الحساب'
                    : 'Delete Account',
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

    setState(() {
      isDeletingAccount = true;
    });

    try {
      final uid = user.uid;

      // 1. Cancel every local notification first.
      await NotificationService.instance
          .cancelAllNotifications();

      // 2. Delete all Firestore data.
      await _deleteUserFirestoreData(uid);

      // 3. Delete Firebase Authentication account.
      await user.delete();

      if (!mounted) return;

      setState(() {
        isDeletingAccount = false;
      });

      // FirebaseAuth automatically signs the user out
      // after successful account deletion.
      widget.onLogout();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isDeletingAccount = false;
      });

      String message;

      if (e.code == 'requires-recent-login') {
        message = isArabic
            ? 'لأسباب أمنية، يجب تسجيل الدخول مرة أخرى قبل حذف الحساب.'
            : 'For security reasons, please log in again before deleting your account.';
      } else {
        message = isArabic
            ? 'حدث خطأ أثناء حذف الحساب.'
            : 'Something went wrong while deleting your account.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint(
        'Error deleting account: $e',
      );

      if (!mounted) return;

      setState(() {
        isDeletingAccount = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'حدث خطأ أثناء حذف الحساب.'
                : 'Something went wrong while deleting your account.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.logout,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          content: Text(
            l10n.areYouSureLogout,
            style: const TextStyle(
              color: greyColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: greyColor,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                l10n.logout,
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      widget.onLogout();
    } catch (e) {
      debugPrint(
        'Error logging out: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.somethingWentWrong,
          ),
        ),
      );
    }
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: greyColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 10,
          ),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: greyColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: lightGreen,
      body: Column(
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft:
                    Radius.circular(25),
                bottomRight:
                    Radius.circular(25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 20,
                top: 35,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      l10n.settings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoadingSettings
                ? const Center(
                    child:
                        CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  )
                : SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      20,
                      18,
                      100,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.all(
                            18,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(
                                  0.04,
                                ),
                                blurRadius: 10,
                                offset:
                                    const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration:
                                    const BoxDecoration(
                                  color: softGreen,
                                  shape:
                                      BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color:
                                      primaryGreen,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      userName,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        color:
                                            textColor,
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      userEmail,
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,
                                      style:
                                          const TextStyle(
                                        color:
                                            greyColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildSectionCard(
                          title:
                              l10n.personalInformation,
                          children: [
                            _buildSettingTile(
                              icon:
                                  Icons.person_outline,
                              title:
                                  l10n.personalInformation,
                              subtitle:
                                  l10n.emailCannotChange,
                              onTap:
                                  _showPersonalInformationDialog,
                            ),
                            const Divider(
                              height: 1,
                              indent: 74,
                              endIndent: 16,
                            ),
                            _buildSettingTile(
                              icon:
                                  Icons.lock_outline,
                              title:
                                  l10n.changePassword,
                              subtitle:
                                  l10n.passwordResetInstructions,
                              onTap:
                                  _showChangePasswordDialog,
                            ),
                            const Divider(
                              height: 1,
                              indent: 74,
                              endIndent: 16,
                            ),
                            _buildSettingTile(
                              icon:
                                  Icons
                                      .notifications_none_rounded,
                              title:
                                  l10n.notificationPreferences,
                              subtitle:
                                  l10n.notificationsSaved,
                              onTap:
                                  _showNotificationPreferencesDialog,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _buildSectionCard(
                          title:
                              l10n.appSettings,
                          children: [
                            _buildSettingTile(
                              icon:
                                  Icons.language_rounded,
                              title:
                                  l10n.language,
                              subtitle:
                                  selectedLanguage ==
                                          'Arabic'
                                      ? l10n.arabic
                                      : l10n.english,
                              onTap:
                                  _showLanguageDialog,
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ================================
                        // LOGOUT
                        // ================================
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                isDeletingAccount
                                    ? null
                                    : _logout,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white,
                              foregroundColor:
                                  Colors.red,
                              elevation: 0,
                              side:
                                  const BorderSide(
                                color: Colors.red,
                                width: 1,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                const Icon(
                                  Icons
                                      .logout_rounded,
                                  size: 21,
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  l10n.logout,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ================================
                        // DELETE ACCOUNT
                        // ================================
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed:
                                isDeletingAccount
                                    ? null
                                    : _deleteAccount,
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.red,
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              disabledBackgroundColor:
                                  Colors.red
                                      .withOpacity(0.6),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  16,
                                ),
                              ),
                            ),
                            child: isDeletingAccount
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      const Icon(
                                        Icons
                                            .delete_forever_rounded,
                                        size: 21,
                                      ),
                                      const SizedBox(
                                        width: 9,
                                      ),
                                      Text(
                                        selectedLanguage ==
                                                'Arabic'
                                            ? 'حذف الحساب'
                                            : 'Delete Account',
                                        style:
                                            const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
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
        ],
      ),
    );
  }
}