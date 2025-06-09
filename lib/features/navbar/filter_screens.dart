import 'package:flutter/material.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  const FilterScreen({super.key, this.initialFilters});

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
  void initState() {
    super.initState();
    final filters = widget.initialFilters ?? {};
    selectedSports = Set<String>.from(filters['sports'] ?? []);
    selectedLocation = filters['location'];
    selectedPrice = filters['price'];
    selectedDate = filters['date'];
  }

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
                    sports.map((sport) {
                      return FilterChip(
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
                      );
                    }).toList(),
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
                      ...[
                        'Quận 1',
                        'Quận 2',
                        'Quận 3',
                        'Quận 4',
                        'Quận 5',
                        'Quận 6',
                        'Quận 7',
                        'Quận 8',
                        'Quận 9',
                        'Quận 10',
                        'Quận 11',
                        'Quận 12',
                        'Bình Thạnh',
                        'Gò Vấp',
                        'Tân Bình',
                        'Tân Phú',
                        'Phú Nhuận',
                        'Bình Tân',
                        'Thủ Đức',
                        'Nhà Bè',
                        'Cần Giờ',
                        'Hóc Môn',
                        'Bình Chánh',
                      ].map(
                        (district) => DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        ),
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
                    priceRanges.map((price) {
                      return ChoiceChip(
                        label: Text(price),
                        selected: selectedPrice == price,
                        onSelected:
                            (_) => setState(() => selectedPrice = price),
                      );
                    }).toList(),
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
