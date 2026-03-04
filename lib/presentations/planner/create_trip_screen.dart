import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vivu_tet/di.dart';
import 'package:vivu_tet/presentations/shared/theme/app_theme.dart';
import 'package:vivu_tet/viewmodel/planner/create_trip_viewmodel.dart';

class CreateTripScreen extends StatelessWidget {
  const CreateTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => buildCreateTrip(),
      child: const _CreateTripBody(),
    );
  }
}

class _CreateTripBody extends StatelessWidget {
  const _CreateTripBody();

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _selectDate(BuildContext context, CreateTripViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.brownDeep,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) vm.setDate(picked);
  }

  void _showAddDialog(BuildContext context, CreateTripViewModel vm) {
    TimeOfDay selectedTime = TimeOfDay.now();
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Thêm lịch trình',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Thời gian: ${selectedTime.format(ctx)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (t != null) setS(() => selectedTime = t);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Tên hoạt động (VD: Lễ chùa)',
                    filled: true,
                    fillColor: AppColors.warmCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: InputDecoration(
                    hintText: 'Địa điểm (VD: Trấn Quốc)',
                    filled: true,
                    fillColor: AppColors.warmCream,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  vm.addActivity(
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                    title: titleCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text(
                'THÊM',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context, CreateTripViewModel vm) async {
    final ok = await vm.createTrip();
    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khởi tạo thành công! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // ← trả true để MainScreen reload
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateTripViewModel>();

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        centerTitle: true,
        title: Text(
          'Tạo Kế Hoạch 1 Ngày',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên kế hoạch
            Text(
              'Tên kế hoạch',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: vm.titleController,
              decoration: InputDecoration(
                hintText: 'VD: Du xuân Mùng 1',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.mode_edit_outline_rounded,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chọn ngày
            Text(
              'Ngày đi',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.brownDeep,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context, vm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${vm.selectedDate.day}/${vm.selectedDate.month}/${vm.selectedDate.year}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Lịch trình
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch trình chi tiết',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.brownDeep,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddDialog(context, vm),
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            if (vm.activities.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Chưa có hoạt động nào.\nHãy bấm Thêm để lên lịch!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vm.activities.length,
                itemBuilder: (_, index) {
                  final act = vm.activities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: const Border(
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _fmt(act.hour, act.minute),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        act.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: act.location.isNotEmpty
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  act.location,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => vm.removeActivity(index),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: vm.isLoading ? null : () => _submit(context, vm),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
            ),
            child: vm.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'KHỞI TẠO CHUYẾN ĐI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
