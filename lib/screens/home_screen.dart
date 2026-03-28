import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/medicine_card.dart';
import 'add_medicine_screen.dart';
import 'edit_medicine_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicineNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              'ওষুধ রিমাইন্ডার',
              style: GoogleFonts.hindSiliguri(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('কিছু একটা সমস্যা হয়েছে: $e')),
        data: (medicines) {
          if (medicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💊', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'কোনো ওষুধ যোগ করা হয়নি',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'নিচের + বোতামে চাপ দিয়ে ওষুধ যোগ করুন',
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return MedicineCard(
                medicine: medicine,
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditMedicineScreen(medicine: medicine),
                    ),
                  );
                },
                onDelete: () {
                  ref
                      .read(medicineNotifierProvider.notifier)
                      .deleteMedicine(medicine);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: AppTheme.textDark),
        label: Text(
          'নতুন যোগ করুন',
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}