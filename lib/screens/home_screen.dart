import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/medicine_provider.dart';
import '../models/medicine.dart';
import '../theme/app_theme.dart';
import '../widgets/medicine_card.dart';
import '../services/notification_service.dart';
import 'add_medicine_screen.dart';
import 'edit_medicine_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'শুভ সকাল';
    if (hour < 17) return 'শুভ দুপুর';
    if (hour < 20) return 'শুভ বিকেল';
    return 'শুভ সন্ধ্যা';
  }

  String _todayBengali() {
    final now = DateTime.now();
    final bengaliMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল',
      'মে', 'জুন', 'জুলাই', 'আগস্ট',
      'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final bengaliDays = [
      'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার',
      'শুক্রবার', 'শনিবার', 'রবিবার'
    ];
    return '${bengaliDays[now.weekday - 1]}, ${now.day} ${bengaliMonths[now.month - 1]}';
  }

  int _todayDoseCount(List<Medicine> medicines) {
    int count = 0;
    for (final m in medicines) {
      count += m.times.length;
    }
    return count;
  }

  String? _nextDose(List<Medicine> medicines) {
    if (medicines.isEmpty) return null;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    int? earliest;
    String? medicineName;

    for (final m in medicines) {
      for (final t in m.times) {
        final parts = t.split(':');
        final h = int.parse(parts[0]);
        final min = int.parse(parts[1]);
        final totalMin = h * 60 + min;
        if (totalMin > nowMinutes) {
          if (earliest == null || totalMin < earliest) {
            earliest = totalMin;
            final period = h < 12 ? 'AM' : 'PM';
            final dh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
            medicineName =
            '${m.name} — $dh:${min.toString().padLeft(2, '0')} $period';
          }
        }
      }
    }
    return medicineName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicineNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: medicinesAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('সমস্যা হয়েছে: $e')),
        data: (medicines) {
          return CustomScrollView(
            slivers: [
              // ── Hero Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: _HeroHeader(
                  greeting: _greeting(),
                  today: _todayBengali(),
                  totalMedicines: medicines.length,
                  todayDoses: _todayDoseCount(medicines),
                  nextDose: _nextDose(medicines),
                  onTest: () =>
                      NotificationService.testImmediateNotification(),
                ),
              ),

              // ── Section Title ─────────────────────────────────
              if (medicines.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'সকল ওষুধ',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${medicines.length}টি',
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Medicine List ─────────────────────────────────
              if (medicines.isEmpty)
                SliverToBoxAdapter(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final medicine = medicines[index];
                        return MedicineCard(
                          medicine: medicine,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditMedicineScreen(medicine: medicine),
                            ),
                          ),
                          onDelete: () => ref
                              .read(medicineNotifierProvider.notifier)
                              .deleteMedicine(medicine),
                        );
                      },
                      childCount: medicines.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),

      // ── FAB ───────────────────────────────────────────────────
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
          ),
          backgroundColor: AppTheme.primary,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: AppTheme.textDark, size: 26),
          label: Text(
            'নতুন ওষুধ যোগ করুন',
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ── Hero Header Widget ──────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String greeting;
  final String today;
  final int totalMedicines;
  final int todayDoses;
  final String? nextDose;
  final VoidCallback onTest;

  const _HeroHeader({
    required this.greeting,
    required this.today,
    required this.totalMedicines,
    required this.todayDoses,
    required this.nextDose,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF5C842), Color(0xFFFFE082)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7A6000),
                        ),
                      ),
                      Text(
                        'বাবা ',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  // Test bell + date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onTest,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF7A6000),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        today,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          color: const Color(0xFF7A6000),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _StatCard(
                    icon: '💊',
                    value: '$totalMedicines',
                    label: 'মোট ওষুধ',
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: '⏰',
                    value: '$todayDoses',
                    label: 'আজকের ডোজ',
                  ),
                ],
              ),

              // Next dose
              if (nextDose != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('🔔', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'পরবর্তী ডোজ',
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 12,
                                color: const Color(0xFF7A6000),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              nextDose!,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (nextDose == null && totalMedicines > 0) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(
                        'আজকের সব ডোজ শেষ! শুভ রাত্রি।',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 12,
                    color: const Color(0xFF7A6000),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('💊', style: TextStyle(fontSize: 54)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'কোনো ওষুধ যোগ করা হয়নি',
            style: GoogleFonts.hindSiliguri(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'নিচের বোতামে চাপ দিয়ে\nপ্রথম ওষুধটি যোগ করুন',
            style: GoogleFonts.hindSiliguri(
              fontSize: 15,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Arrow pointing down
          Icon(
            Icons.arrow_downward_rounded,
            size: 36,
            color: AppTheme.primary.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}