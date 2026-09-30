import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:teachly/core/localization/app_localization.dart';
import 'add_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const Color primaryGreen = Color(0xFF2F8F57);
  static const Color lightGreen = Color(0xFFF1FFF3);
  static const Color softGreen = Color(0xFFE7F5E9);
  static const Color textColor = Color(0xFF202020);
  static const Color greyText = Color(0xFF777777);

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>
      _notesCollection() {
    final user = _currentUser;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('notes');
  }

  // =========================================================
  // ADD NOTE
  // =========================================================

  Future<void> _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddNoteScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // EDIT NOTE
  // =========================================================

  Future<void> _editNote(
    String noteId,
    Map<String, dynamic> data,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNoteScreen(
          noteId: noteId,
          noteData: data,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  // =========================================================
  // DELETE NOTE
  // =========================================================

  Future<void> _deleteNote(
    String noteId,
    String title,
  ) async {
    final l10n =
        AppLocalizations.of(context);

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
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
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
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
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text(
                l10n.delete,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _notesCollection()
          .doc(noteId)
          .delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.deletedSuccessfully,
          ),
          backgroundColor:
              primaryGreen,
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.somethingWentWrong,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(
    dynamic value,
    AppLocalizations l10n,
  ) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return '';
    }

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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context);

    final user = _currentUser;

    return Scaffold(
      backgroundColor: lightGreen,

      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,

        title: Text(
          l10n.notes,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        actions: [
          IconButton(
            onPressed: _addNote,
            icon: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: _addNote,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),

      body: user == null
          ? _buildEmptyState(
              icon: Icons.person_outline,
              message: l10n.noStudents,
            )
          : StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
              stream: _notesCollection()
                  .orderBy(
                    'updatedAt',
                    descending: true,
                  )
                  .snapshots(),

              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color: primaryGreen,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyState(
                    icon:
                        Icons.error_outline,
                    message:
                        l10n.somethingWentWrong,
                  );
                }

                final notes =
                    snapshot.data?.docs ??
                        [];

                if (notes.isEmpty) {
                  return _buildEmptyState(
                    icon:
                        Icons.note_alt_outlined,
                    message:
                        'No notes yet',
                  );
                }

                return ListView.separated(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    90,
                  ),
                  physics:
                      const BouncingScrollPhysics(),

                  itemCount: notes.length,

                  separatorBuilder:
                      (context, index) =>
                          const SizedBox(
                    height: 12,
                  ),

                  itemBuilder:
                      (context, index) {
                    final doc =
                        notes[index];

                    final data =
                        doc.data();

                    return _buildNoteCard(
                      doc.id,
                      data,
                      l10n,
                    );
                  },
                );
              },
            ),
    );
  }

  // =========================================================
  // NOTE CARD
  // =========================================================

  Widget _buildNoteCard(
    String noteId,
    Map<String, dynamic> data,
    AppLocalizations l10n,
  ) {
    final title =
        data['title']?.toString() ?? '';

    final content =
        data['content']?.toString() ?? '';

    final updatedAt =
        data['updatedAt'];

    final date =
        _formatDate(
      updatedAt,
      l10n,
    );

    return GestureDetector(
      onTap: () {
        _editNote(
          noteId,
          data,
        );
      },

      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.035,
              ),
              blurRadius: 6,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Container(
                  width: 42,
                  height: 42,

                  decoration:
                      BoxDecoration(
                    color: softGreen,
                    borderRadius:
                        BorderRadius.circular(
                      11,
                    ),
                  ),

                  child: const Icon(
                    Icons
                        .sticky_note_2_outlined,
                    color: primaryGreen,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty
                            ? l10n.note
                            : title,

                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            const TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      if (date.isNotEmpty) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          date,
                          style:
                              const TextStyle(
                            color: greyText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  color: Colors.white,

                  icon: const Icon(
                    Icons
                        .more_vert_rounded,
                    color: greyText,
                  ),

                  onSelected: (value) {
                    if (value == 'edit') {
                      _editNote(
                        noteId,
                        data,
                      );
                    }

                    if (value == 'delete') {
                      _deleteNote(
                        noteId,
                        title,
                      );
                    }
                  },

                  itemBuilder:
                      (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 19,
                            color:
                                primaryGreen,
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Text(
                            l10n.edit,
                          ),
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
                            size: 19,
                            color: Colors.red,
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Text(
                            l10n.delete,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (content.isNotEmpty) ...[
              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),

                decoration:
                    BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child: Text(
                  content,
                  maxLines: 4,
                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color: greyText,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
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
    required String message,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 76,
              height: 76,

              decoration:
                  BoxDecoration(
                color: softGreen,
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: primaryGreen,
                size: 38,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              message,
              textAlign: TextAlign.center,

              style:
                  const TextStyle(
                color: greyText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _addNote,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryGreen,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              icon: const Icon(
                Icons.add_rounded,
                size: 20,
              ),

              label: Text(
                l10nSafe(context).add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppLocalizations l10nSafe(
    BuildContext context,
  ) {
    return AppLocalizations.of(context);
  }
}