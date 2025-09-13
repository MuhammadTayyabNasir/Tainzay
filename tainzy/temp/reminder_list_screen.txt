import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tainzy/app/models/reminder.dart';
import 'package:tainzy/app/repositories/reminder_repository.dart';

// Provider to get all reminders
final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderRepositoryProvider).getReminders();
});

// Provider for the filter state
enum ReminderFilter { due, upcoming, completed }
final reminderFilterProvider = StateProvider<ReminderFilter>((ref) => ReminderFilter.due);

// Provider that filters the reminders based on the selected filter
final filteredRemindersProvider = Provider<List<Reminder>>((ref) {
  final filter = ref.watch(reminderFilterProvider);
  final reminders = ref.watch(remindersProvider).asData?.value ?? [];
  final now = DateTime.now();

  return reminders.where((r) {
    switch (filter) {
      case ReminderFilter.due:
      // Show if due date is in the past AND status is 'due'
        return r.status == ReminderStatus.due && r.nextDueDate.isBefore(now);
      case ReminderFilter.upcoming:
      // Show if due date is in the future AND status is 'due'
        return r.status == ReminderStatus.due && r.nextDueDate.isAfter(now);
      case ReminderFilter.completed:
        return r.status == ReminderStatus.completed;
    }
  }).toList();
});

class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredReminders = ref.watch(filteredRemindersProvider);
    final currentFilter = ref.watch(reminderFilterProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<ReminderFilter>(
              segments: const [
                ButtonSegment(value: ReminderFilter.due, label: Text('Due'), icon: Icon(Icons.notifications_active_outlined)),
                ButtonSegment(value: ReminderFilter.upcoming, label: Text('Upcoming'), icon: Icon(Icons.schedule_outlined)),
                ButtonSegment(value: ReminderFilter.completed, label: Text('Completed'), icon: Icon(Icons.check_circle_outline)),
              ],
              selected: {currentFilter},
              onSelectionChanged: (newSelection) {
                ref.read(reminderFilterProvider.notifier).state = newSelection.first;
              },
            ),
          ),
          Expanded(
            child: filteredReminders.isEmpty
                ? Center(child: Text('No reminders in this category.'))
                : ListView.builder(
              itemCount: filteredReminders.length,
              itemBuilder: (context, index) {
                final reminder = filteredReminders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(reminder.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product: ${reminder.productName}'),
                        Text('Next Dose: ${DateFormat.yMMMd().format(reminder.nextDueDate)}'),
                      ],
                    ),
                    trailing: reminder.status == ReminderStatus.due
                        ? ElevatedButton(
                      onPressed: () async {
                        // Logic to mark as completed
                        await ref.read(reminderRepositoryProvider).updateReminderStatus(reminder.id!, ReminderStatus.completed);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder marked as completed.')));
                      },
                      child: const Text('Done'),
                    )
                        : Icon(Icons.check, color: Colors.green),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}