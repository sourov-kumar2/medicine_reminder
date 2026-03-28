import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../theme/app_theme.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _daysController = TextEditingController();

  String _frequency = 'daily';
  String _durationType = 'forever';
  DateTime? _endDate;
  List<TimeOfDay> _times = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _times.add(picked));
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  String _formatTime(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _displayTime(TimeOfDay t) {
    final period = t.hour < 12 ? 'AM' : 'PM';
    final hour = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ওষুধের নাম লিখুন',
              style: GoogleFonts.hindSiliguri()),
          backgroundColor: AppTheme.deleteRed,
        ),
      );
      return;
    }
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('কমপক্ষে একটি সময় যোগ করুন',
              style: GoogleFonts.hindSiliguri()),
          backgroundColor: AppTheme.deleteRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final medicine = Medicine()
      ..name = _nameController.text.trim()
      ..frequency = _frequency
      ..times = _times.map(_formatTime).toList()
      ..durationType = _durationType
      ..endDate = _endDate
      ..durationDays = _daysController.text.isNotEmpty
          ? int.tryParse(_daysController.text)
          : null
      ..instructions = _instructionsController.text.trim()
      ..startDate = DateTime.now()
      ..isActive = true;

    await ref.read(medicineNotifierProvider.notifier).addMedicine(medicine);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'নতুন ওষুধ যোগ করুন',
          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('ওষুধের নাম:'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.hindSiliguri(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'যেমন: প্যারাসিটামল ৫০০ মিগ্রা',
              ),
            ),
            const SizedBox(height: 20),

            _label('কতবার খেতে হবে?'),
            const SizedBox(height: 8),
            _frequencyChips(),
            const SizedBox(height: 20),

            _label('কখন খেতে হবে? (একাধিক বাছুন)'),
            const SizedBox(height: 8),
            _timesList(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.add, color: AppTheme.textDark),
              label: Text('+ আরো সময়',
                  style: GoogleFonts.hindSiliguri(color: AppTheme.textDark)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primary, width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            _label('কতদিন মনে করাবে?'),
            const SizedBox(height: 8),
            _durationChips(),
            const SizedBox(height: 8),
            _durationExtra(),
            const SizedBox(height: 20),

            _label('বিশেষ নির্দেশনা:'),
            const SizedBox(height: 8),
            TextField(
              controller: _instructionsController,
              style: GoogleFonts.hindSiliguri(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'যেমন: খাওয়ার আগে',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('বাতিল',
                        style: GoogleFonts.hindSiliguri(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text('সংরক্ষণ করুন',
                        style: GoogleFonts.hindSiliguri(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.hindSiliguri(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _frequencyChips() {
    final options = [
      ('daily', 'প্রতিদিন'),
      ('alternate', 'একদিন পর পর'),
      ('custom', 'কাস্টম'),
    ];
    return Row(
      children: options.map((o) {
        final selected = _frequency == o.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _frequency = o.$1),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.chipUnselected,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                o.$2,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _timesList() {
    if (_times.isEmpty) {
      return Text(
        'এখনো কোনো সময় যোগ করা হয়নি',
        style: GoogleFonts.hindSiliguri(
            fontSize: 14, color: AppTheme.textGrey),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _times.asMap().entries.map((e) {
        return Chip(
          label: Text(
            _displayTime(e.value),
            style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primary.withOpacity(0.2),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () => setState(() => _times.removeAt(e.key)),
        );
      }).toList(),
    );
  }

  Widget _durationChips() {
    final options = [
      ('forever', 'চিরকাল'),
      ('date', 'নির্দিষ্ট তারিখ পর্যন্ত'),
      ('days', 'নির্দিষ্ট দিন'),
    ];
    return Wrap(
      spacing: 8,
      children: options.map((o) {
        final selected = _durationType == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _durationType = o.$1),
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : AppTheme.chipUnselected,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o.$2,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _durationExtra() {
    if (_durationType == 'date') {
      return GestureDetector(
        onTap: _pickEndDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppTheme.textGrey, size: 20),
              const SizedBox(width: 10),
              Text(
                _endDate != null
                    ? DateFormat('dd/MM/yyyy').format(_endDate!)
                    : 'তারিখ বাছুন',
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  color: _endDate != null
                      ? AppTheme.textDark
                      : AppTheme.textGrey,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_durationType == 'days') {
      return TextField(
        controller: _daysController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.hindSiliguri(fontSize: 15),
        decoration: const InputDecoration(hintText: 'কতদিন? যেমন: ৩০'),
      );
    }
    return const SizedBox.shrink();
  }
}