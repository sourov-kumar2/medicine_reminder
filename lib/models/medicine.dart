import 'package:isar/isar.dart';

part 'medicine.g.dart';

@collection
class Medicine {
  Id id = Isar.autoIncrement;

  late String name;

  // Frequency: 'daily', 'alternate', 'custom'
  late String frequency;

  // Times as list of "HH:mm" strings e.g. ["08:00", "14:00", "22:00"]
  late List<String> times;

  // Duration type: 'date', 'forever', 'days'
  late String durationType;

  // Used when durationType == 'date'
  DateTime? endDate;

  // Used when durationType == 'days'
  int? durationDays;

  // Special instructions e.g. "খাওয়ার আগে"
  String? instructions;

  // When reminder started
  late DateTime startDate;

  bool isActive = true;
}