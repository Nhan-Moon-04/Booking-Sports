import 'package:flutter/material.dart';

class IntroductionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Sports'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Sports',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Booking Sports là giải pháp toàn diện dành cho cả người chơi và người quản lý sân thể thao.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            Text(
              'Chúng tôi cung cấp nền tảng giúp người chơi dễ dàng tìm, đặt sân trực tuyến, thanh toán nhanh chóng, đồng thời tìm kiếm đối tác chơi thể thao một cách dễ dàng, giao tiếp trò chuyện tiện lợi, hiệu quả.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            Text(
              'Booking Sports giúp người quản lý theo dõi lịch đặt sân, mua bán dịch vụ, quản lý thanh toán, và chăm sóc khách hàng hiệu quả.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            Text(
              'Với Booking Sports, việc quản lý và trải nghiệm thể thao trở nên đơn giản và tiện lợi hơn bao giờ hết. Hãy tham gia ngay để tận hưởng sự tiện ích từ cả hai phía - người chơi và người quản lý!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to next screen
                },
                child: Text('Bắt đầu ngay'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}