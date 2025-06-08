import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReferralScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giới thiệu ứng dụng'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Giới thiệu ứng dụng cho bạn bè, nhận quà không giới hạn!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Hãy chia sẻ đường dẫn giới thiệu cho bạn bè của bạn để nhận được những phần quà hấp dẫn từ Booking Sports!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'https://booking-sports.onelink.me/p3sR/zgoisd00',
                      style: TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.content_copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: 'https://booking-sports.onelink.me/p3sR/zgoisd00'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã sao chép liên kết')),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Handle share
              },
              child: Text('CHIA SẺ'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Danh sách người bạn đã chia sẻ ứng dụng (0)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Chưa có người bạn nào đăng ký',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}