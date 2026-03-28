import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

// Stream provider for real-time UI updates
final medicineStreamProvider = StreamProvider<List<Medicine>>((ref) {
  return DatabaseService.watchMedicines();
});

class MedicineNotifier extends AsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() async {
    return DatabaseService.getAllMedicines();
  }

  Future<void> addMedicine(Medicine medicine) async {
    final key = await DatabaseService.addMedicine(medicine);
    await NotificationService.scheduleMedicineNotifications(medicine, key);
    state = AsyncData(DatabaseService.getAllMedicines());
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await DatabaseService.updateMedicine(medicine);
    await NotificationService.scheduleMedicineNotifications(
        medicine, medicine.key as int);
    state = AsyncData(DatabaseService.getAllMedicines());
  }

  Future<void> deleteMedicine(Medicine medicine) async {
    await NotificationService.cancelMedicineNotifications(
        medicine.key as int);
    await DatabaseService.deleteMedicine(medicine.key as int);
    state = AsyncData(DatabaseService.getAllMedicines());
  }
}

final medicineNotifierProvider =
AsyncNotifierProvider<MedicineNotifier, List<Medicine>>(
    MedicineNotifier.new);