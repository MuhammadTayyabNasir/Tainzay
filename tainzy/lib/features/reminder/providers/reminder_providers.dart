// lib/features/reminder/providers/reminder_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/models/models.dart';
import '../../../app/repositories/reminder_repository.dart';
import '../../../app/repositories/repositories.dart';

final remindersStreamProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderRepositoryProvider).getReminders();
});