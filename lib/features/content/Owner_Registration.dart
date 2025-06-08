import 'package:flutter/material.dart';

class OwnerRegistrationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ĐĂNG KÝ TÀI KHOẢN'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '(DÀNH CHO CHỦ SẢN)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Booking Sports triển khai gửi OTP qua Zalo, vui lòng sử dụng SDT có Zalo để nhận OTP',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            Divider(thickness: 1),
            SizedBox(height: 20),
            Text(
              'Nguyễn Thiện Nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            TextFormField(
              decoration: InputDecoration(
                labelText: '+84 Điện thoại',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle continue
                },
                child: Text('TIẾP TỤC'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}