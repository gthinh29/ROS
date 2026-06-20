import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared/models/table.dart';
import '../../providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TableModel? _selectedTable;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _partySizeController = TextEditingController(text: '2');
  final _noteController = TextEditingController();

  bool _isSearching = false;
  bool _isSubmitting = false;

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _formattedTime => '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

  void _searchTables() {
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (selectedDateTime.isBefore(now.add(const Duration(minutes: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian đặt bàn ít nhất 30 phút kể từ hiện tại.')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedTable = null;
    });
    ref.read(availableTablesProvider.notifier).fetchTables(_formattedDate, _formattedTime);
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate() || _selectedTable == null) return;
    
    setState(() => _isSubmitting = true);

    // Reserved at in ISO 8601
    final dt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute
    );

    final payload = {
      'table_id': _selectedTable!.id,
      'customer_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'party_size': int.parse(_partySizeController.text.trim()),
      'reserved_at': dt.toIso8601String(),
      'note': _noteController.text.trim(),
      'pre_order_items': [],
    };

    final service = ref.read(reservationServiceProvider);
    final resId = await service.createReservation(payload);

    setState(() => _isSubmitting = false);

    if (resId != null) {
      if (mounted) {
        context.go('/otp?id=$resId&email=${Uri.encodeComponent(_emailController.text.trim())}');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi đặt bàn. Vui lòng thử lại.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(availableTablesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Banner
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=2070&auto=format&fit=crop'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5)),
                child: Center(
                  child: Text(
                    'ROS RESTAURANT',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 8),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form 1: Search
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1. Tìm bàn trống', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                                        if (date != null) setState(() => _selectedDate = date);
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(labelText: 'Ngày', border: OutlineInputBorder()),
                                        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final time = await showTimePicker(context: context, initialTime: _selectedTime);
                                        if (time != null) setState(() => _selectedTime = time);
                                      },
                                      child: InputDecorator(
                                        decoration: const InputDecoration(labelText: 'Giờ', border: OutlineInputBorder()),
                                        child: Text(_selectedTime.format(context)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _searchTables,
                                    child: const Text('Tìm bàn'),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Form 2: Tables Result
                      if (_isSearching)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('2. Chọn bàn', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                if (tablesState.isLoading)
                                  const Center(child: CircularProgressIndicator())
                                else if (tablesState.error != null)
                                  Center(child: Text(tablesState.error!, style: const TextStyle(color: Colors.red)))
                                else if (tablesState.tables.isEmpty)
                                  const Center(child: Text('Không có bàn trống trong khoảng thời gian này.'))
                                else
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: tablesState.tables.map((t) {
                                      final isAvailable = t.status == TableStatus.empty;
                                      final isSelected = _selectedTable?.id == t.id;
                                      return InkWell(
                                        onTap: isAvailable ? () => setState(() => _selectedTable = t) : null,
                                        child: Opacity(
                                          opacity: isAvailable ? 1.0 : 0.5,
                                          child: Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFFE53935) : (isAvailable ? Colors.grey[200] : Colors.grey[400]),
                                              borderRadius: BorderRadius.circular(12),
                                              border: isSelected ? Border.all(color: Colors.red[900]!, width: 2) : null,
                                            ),
                                            child: Center(
                                              child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.table_restaurant, color: isSelected ? Colors.white : Colors.black54),
                                                const SizedBox(height: 8),
                                                Text('${t.zone}-${t.number}', style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Form 3: Customer Info
                      if (_selectedTable != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('3. Thông tin người đặt', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(labelText: 'Họ và Tên', border: OutlineInputBorder()),
                                          validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Vui lòng nhập SĐT';
                                            if (int.tryParse(v) == null) return 'SĐT chỉ được chứa chữ số';
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: _emailController,
                                          decoration: const InputDecoration(labelText: 'Email (Nhận mã OTP)', border: OutlineInputBorder()),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Vui lòng nhập Email';
                                            if (!v.contains('@')) return 'Email không hợp lệ';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          controller: _partySizeController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(labelText: 'Số người', border: OutlineInputBorder()),
                                          validator: (v) => v!.isEmpty ? 'Nhập số lượng' : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _noteController,
                                    decoration: const InputDecoration(labelText: 'Ghi chú (Không bắt buộc)', border: OutlineInputBorder()),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isSubmitting ? null : _submitReservation,
                                      child: _isSubmitting 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Xác nhận Đặt bàn'),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
