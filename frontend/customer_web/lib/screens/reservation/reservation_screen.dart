import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/api_client.dart';
import '../../providers.dart';

const _primaryColor = Color(0xFFE53935);
const _gradient = LinearGradient(
  colors: [Color(0xFFE53935), Color(0xFFC62828)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({super.key});

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  DateTime? _reservedAt;
  int _partySize = 2;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedContact();
  }

  Future<void> _loadSavedContact() async {
    final saved = await SavedContact.load();
    if (!mounted) return;
    if (saved.name.isNotEmpty && _nameCtrl.text.isEmpty) {
      _nameCtrl.text = saved.name;
    }
    if (saved.phone.isNotEmpty && _phoneCtrl.text.isEmpty) {
      _phoneCtrl.text = saved.phone;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reservedAt ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _reservedAt ?? now.add(const Duration(hours: 1)),
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _reservedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatDateTime(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$hh:$mm — $dd/$mo/${dt.year}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reservedAt == null) {
      _showError('Vui lòng chọn ngày giờ đặt bàn');
      return;
    }
    if (_reservedAt!.isBefore(DateTime.now())) {
      _showError('Thời gian đặt bàn phải ở tương lai');
      return;
    }

    setState(() => _submitting = true);

    final preOrderItems = ref.read(preOrderProvider);
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    try {
      final response = await ApiClient().dio.post(
        '/reservations',
        data: {
          'customer_name': name,
          'phone': phone,
          'reserved_at': _reservedAt!.toUtc().toIso8601String(),
          'party_size': _partySize,
          if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
          'pre_order_items': preOrderItems.map((p) => p.toApiJson()).toList(),
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data is Map ? response.data['data'] as Map? : null;
        final id = data?['id']?.toString() ?? '';
        await SavedContact.save(name: name, phone: phone);
        ref.read(preOrderProvider.notifier).clear();
        if (!mounted) return;
        context.go(
          '/reservation/success',
          extra: {
            'id': id,
            'customer_name': name,
            'phone': phone,
            'reserved_at': _reservedAt!,
            'party_size': _partySize,
          },
        );
      } else {
        final msg = response.data is Map
            ? (response.data['message']?.toString() ?? 'Đặt bàn thất bại')
            : 'Đặt bàn thất bại';
        _showError(msg);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        _showError('Mất kết nối, thử lại');
      } else {
        _showError('Không thể đặt bàn. Vui lòng thử lại.');
      }
    } catch (e) {
      if (mounted) _showError('Không thể kết nối máy chủ. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Đặt bàn trước', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: _gradient)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final maxWidth = c.maxWidth > 600 ? 560.0 : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _SectionLabel('Họ tên', required: true),
                        _buildTextField(
                          controller: _nameCtrl,
                          hint: 'Nguyễn Văn A',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập họ tên' : null,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel('Số điện thoại', required: true),
                        _buildTextField(
                          controller: _phoneCtrl,
                          hint: '0901234567',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Vui lòng nhập số điện thoại';
                            if (t.length < 9) return 'Số điện thoại không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel('Thời gian đến', required: true),
                        _buildDateTimeField(),
                        const SizedBox(height: 20),
                        _SectionLabel('Số khách', required: true),
                        _buildPartySize(),
                        const SizedBox(height: 20),
                        _SectionLabel('Đặt món trước'),
                        _buildPreOrderSection(),
                        const SizedBox(height: 20),
                        _SectionLabel('Ghi chú'),
                        _buildTextField(
                          controller: _noteCtrl,
                          hint: 'VD: Bàn cạnh cửa sổ, có trẻ em...',
                          icon: Icons.notes_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: _gradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Giữ chỗ trước cho bạn',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 2),
                Text('Điền thông tin, chúng tôi sẽ xác nhận qua điện thoại',
                    style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),
    );
  }

  Widget _buildPreOrderSection() {
    final preOrder = ref.watch(preOrderProvider);
    final totalAmount = ref.read(preOrderProvider.notifier).totalAmount;

    if (preOrder.isEmpty) {
      return InkWell(
        onTap: () => context.push('/reservation/pre-order'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu, color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đặt món trước (tuỳ chọn)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Khi đến nơi là có món ngay, không phải chờ',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ...List.generate(preOrder.length, (i) {
            final p = preOrder[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.menuItem.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        if (p.variant != null)
                          Text(p.variant!.name,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('x${p.qty}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(width: 8),
                  Text('${p.totalPrice.toStringAsFixed(0)} ₫',
                      style: const TextStyle(
                          color: _primaryColor, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            );
          }),
          Container(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Text('Tạm tính: ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text('${totalAmount.toStringAsFixed(0)} ₫',
                    style: const TextStyle(
                        color: _primaryColor, fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/reservation/pre-order'),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField() {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _reservedAt == null ? 'Chọn ngày và giờ' : _formatDateTime(_reservedAt!),
                style: TextStyle(
                  color: _reservedAt == null ? Colors.grey.shade400 : Colors.black87,
                  fontWeight: _reservedAt == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPartySize() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.group_outlined, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$_partySize khách',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _RoundButton(
            icon: Icons.remove,
            onTap: _partySize > 1 ? () => setState(() => _partySize--) : null,
          ),
          const SizedBox(width: 8),
          _RoundButton(
            icon: Icons.add,
            onTap: _partySize < 50 ? () => setState(() => _partySize++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: _submitting ? null : _gradient,
        color: _submitting ? Colors.grey.shade400 : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _submitting
            ? null
            : [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Xác nhận đặt bàn',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool required;
  const _SectionLabel(this.label, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
          if (required) ...[
            const SizedBox(width: 4),
            Text('*', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: disabled ? Colors.grey.shade100 : _primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              size: 18, color: disabled ? Colors.grey.shade400 : _primaryColor),
        ),
      ),
    );
  }
}
