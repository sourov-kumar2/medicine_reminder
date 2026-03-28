import 'package:hive/hive.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late String frequency; // 'daily', 'alternate', 'custom'

  @HiveField(2)
  late List<String> times; // ["08:00", "14:00", "22:00"]

  @HiveField(3)
  late String durationType; // 'date', 'forever', 'days'

  @HiveField(4)
  DateTime? endDate;

  @HiveField(5)
  int? durationDays;

  @HiveField(6)
  String? instructions;

  @HiveField(7)
  late DateTime startDate;

  @HiveField(8)
  bool isActive = true;
}