import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> filters)? onApply;
  final VoidCallback? onClear;
  const FilterScreen({super.key, this.onApply, this.onClear});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final List<String> sports = ['Cầu lông', 'Tennis', 'Bóng đá', 'Bóng rổ'];
  final List<String> priceRanges = ['Dưới 150K', '150K - 300K', 'Trên 300K'];
  Set<String> selectedSports = {};
  String? selectedLocation;
  String? selectedPrice;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ lọc'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc theo bộ môn',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    sports
                        .map(
                          (sport) => FilterChip(
                            label: Text(sport),
                            selected: selectedSports.contains(sport),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedSports.add(sport);
                                } else {
                                  selectedSports.remove(sport);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lọc theo ngày, giờ đang trống sân',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      Text(
                        selectedDate != null
                            ? "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"
                            : "Chọn ngày",
                        style: TextStyle(
                          color:
                              selectedDate != null ? Colors.black : Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const Text(
                'Lọc theo địa điểm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLocation,
                    hint: const Text('Tất cả'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 1',
                        child: Text('Quận 1'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 2',
                        child: Text('Quận 2'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 3',
                        child: Text('Quận 3'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 4',
                        child: Text('Quận 4'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 5',
                        child: Text('Quận 5'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 6',
                        child: Text('Quận 6'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 7',
                        child: Text('Quận 7'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 8',
                        child: Text('Quận 8'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 9',
                        child: Text('Quận 9'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 10',
                        child: Text('Quận 10'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 11',
                        child: Text('Quận 11'),
                      ),
                      const DropdownMenuItem(
                        value: 'Quận 12',
                        child: Text('Quận 12'),
                      ),
                      const DropdownMenuItem(
                        value: 'Bình Thạnh',
                        child: Text('Bình Thạnh'),
                      ),
                      const DropdownMenuItem(
                        value: 'Gò Vấp',
                        child: Text('Gò Vấp'),
                      ),
                      const DropdownMenuItem(
                        value: 'Tân Bình',
                        child: Text('Tân Bình'),
                      ),
                      const DropdownMenuItem(
                        value: 'Tân Phú',
                        child: Text('Tân Phú'),
                      ),
                      const DropdownMenuItem(
                        value: 'Phú Nhuận',
                        child: Text('Phú Nhuận'),
                      ),
                      const DropdownMenuItem(
                        value: 'Bình Tân',
                        child: Text('Bình Tân'),
                      ),
                      const DropdownMenuItem(
                        value: 'Thủ Đức',
                        child: Text('Thủ Đức'),
                      ),
                      const DropdownMenuItem(
                        value: 'Nhà Bè',
                        child: Text('Nhà Bè'),
                      ),
                      const DropdownMenuItem(
                        value: 'Cần Giờ',
                        child: Text('Cần Giờ'),
                      ),
                      const DropdownMenuItem(
                        value: 'Hóc Môn',
                        child: Text('Hóc Môn'),
                      ),
                      const DropdownMenuItem(
                        value: 'Bình Chánh',
                        child: Text('Bình Chánh'),
                      ),
                    ],
                    onChanged:
                        (value) => setState(() => selectedLocation = value),
                  ),
                ),
              ),
              const Text(
                'Lọc theo mức giá',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    priceRanges
                        .map(
                          (price) => ChoiceChip(
                            label: Text(price),
                            selected: selectedPrice == price,
                            onSelected:
                                (_) => setState(() => selectedPrice = price),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          selectedSports.clear();
                          selectedLocation = null;
                          selectedPrice = null;
                          selectedDate = null;
                        });
                        widget.onClear?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE84C88),
                        side: const BorderSide(color: Color(0xFFE84C88)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Xóa bộ lọc'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final filters = {
                          'sports': selectedSports.toList(),
                          'date': selectedDate,
                          'location': selectedLocation,
                          'price': selectedPrice,
                        };
                        if (widget.onApply != null) {
                          widget.onApply!(filters);
                        }
                        Navigator.pop(context, filters);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE84C88),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Áp Dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}