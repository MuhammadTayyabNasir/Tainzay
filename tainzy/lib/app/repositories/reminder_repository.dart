// lib/app/repositories/reminder_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(FirebaseFirestore.instance);
});

class ReminderRepository {
  final FirebaseFirestore _db;
  ReminderRepository(this._db);

  CollectionReference<Reminder> get _remindersRef =>
      _db.collection('reminders').withConverter<Reminder>(
        fromFirestore: (snapshot, _) => Reminder.fromFirestore(snapshot),
        toFirestore: (reminder, _) => reminder.toFirestore(),
      );

  Stream<List<Reminder>> getReminders() {
    return _remindersRef
        .orderBy('nextDueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addReminder(Reminder reminder) async {
    await _remindersRef.add(reminder);
  }

  Future<void> updateReminderStatus(String id, ReminderStatus status) async {
    await _remindersRef.doc(id).update({'status': status.name});
  }

  Future<void> deleteReminder(String id) async {
    await _remindersRef.doc(id).delete();
  }
}