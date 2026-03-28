import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine.dart';
import '../theme/app_theme.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  String _frequencyText() {
    switch (medicine.frequency) {
      case 'daily':
        return 'প্রতিদিন';
      case 'alternate':
        return 'একদিন পর পর';
      default:
        return 'কাস্টম';
    }
  }

  String _timesText() {
    return medicine.times.map((t) => _formatTime(t)).join(', ');
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _nextDoseText() {
    if (medicine.times.isEmpty) return '';
    final now = TimeOfDay.now();
    for (final t in medicine.times) {
      final parts = t.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      if (hour > now.hour || (hour == now.hour && minute > now.minute)) {
        return 'পরবর্তী ডোজ: আজ ${_formatTime(t)}';
      }
    }
    return 'পরবর্তী ডোজ: কাল ${_formatTime(medicine.times.first)}';
  }

  String _durationText() {
    switch (medicine.durationType) {
      case 'forever':
        return 'চিরকাল';
      case 'days':
        return '${medicine.durationDays} দিন';
      case 'date':
        if (medicine.endDate != null) {
          return '${medicine.endDate!.day}/${medicine.endDate!.month}/${medicine.endDate!.year} পর্যন্ত';
        }
        return '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top colored bar
          Container(
            height: 5,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine name row
                Row(
                  children: [
                    const Text('💊', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        medicine.name,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    // Frequency chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _frequencyText(),
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Times
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'দিনে ${medicine.times.length} বার: ${_timesText()}',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Next dose
                Row(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      _nextDoseText(),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),

                // Instructions
                if (medicine.instructions != null &&
                    medicine.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppTheme.textGrey),
                      const SizedBox(width: 6),
                      Text(
                        medicine.instructions!,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],

                // Duration
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      _durationText(),
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                const SizedBox(height: 10),

                // Edit / Delete buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: AppTheme.textDark),
                        label: Text(
                          'সম্পাদনা',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFDDDDDD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.white),
                        label: Text(
                          'মুছুন',
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deleteRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ওষুধ মুছুন',
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${medicine.name}" মুছে ফেলতে চান?',
          style: GoogleFonts.hindSiliguri(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'বাতিল',
              style: GoogleFonts.hindSiliguri(color: AppTheme.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deleteRed,
            ),
            child: Text(
              'মুছুন',
              style: GoogleFonts.hindSiliguri(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}