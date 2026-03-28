import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine.dart';

class DatabaseService {
  static const String _boxName = 'medicines';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicineAdapter());
    await Hive.openBox<Medicine>(_boxName);
  }

  static Box<Medicine> get _box => Hive.box<Medicine>(_boxName);

  // Add medicine
  static Future<int> addMedicine(Medicine medicine) async {
    return await _box.add(medicine);
  }

  // Get all medicines
  static List<Medicine> getAllMedicines() {
    return _box.values.toList();
  }

  // Update medicine
  static Future<void> updateMedicine(Medicine medicine) async {
    await medicine.save();
  }

  // Delete medicine
  static Future<void> deleteMedicine(int key) async {
    await _box.delete(key);
  }

  // Watch medicines box (real-time stream)
  static Stream<List<Medicine>> watchMedicines() {
    return _box.watch().map((_) => _box.values.toList());
  }
}