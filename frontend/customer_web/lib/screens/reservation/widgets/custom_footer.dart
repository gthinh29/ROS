import 'package:flutter/material.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(60.0),
            child: Wrap(
              spacing: 40,
              runSpacing: 40,
              alignment: WrapAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ROS', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                      SizedBox(height: 15),
                      Text('Thưởng thức tinh hoa, thăng hoa cảm xúc.', style: TextStyle(color: Colors.grey, height: 1.5)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Liên Hệ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 20),
                      Text('Địa chỉ: Quận 1, TPHCM', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 10),
                      Text('Hotline: 1900 0000', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 10),
                      Text('Email: ronaldo@gmail.com', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Giờ Mở Cửa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 20),
                      Text('Thứ 2 - Chủ Nhật', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 10),
                      Text('10:00 - 22:00', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Theo dõi chúng tôi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 20),
                      Row(
                        children: const [
                          Icon(Icons.facebook, color: Colors.grey),
                          SizedBox(width: 15),
                          Icon(Icons.camera_alt, color: Colors.grey), 
                          SizedBox(width: 15),
                          Icon(Icons.video_library, color: Colors.grey),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: const Text(
              '© 2026 ROS Restaurant. All rights reserved.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          )
        ],
      ),
    );
  }
}