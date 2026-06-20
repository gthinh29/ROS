import 'package:flutter/material.dart';
import '../menu_screen.dart';

class HeaderNavigation extends StatelessWidget {
  final bool isScrolled;

  const HeaderNavigation({Key? key, required this.isScrolled}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isScrolled ? Colors.white : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Góc trái: Logo
          Text(
            'ROS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: isScrolled ? Colors.black : Colors.white,
            ),
          ),
          // Góc phải: Menu điều hướng
          Row(
            children: [
              _navItem('Trang chủ', isScrolled),
              _navItem(
                'Thực đơn',
                isScrolled,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuScreen()));
                },
              ),
              _navItem('Giới thiệu', isScrolled),
              _navItem('Liên hệ', isScrolled),
            ],
          )
        ],
      ),
    );
  }

  Widget _navItem(String title, bool isScrolled, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: InkWell(
        onTap: onTap ?? () {},
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isScrolled ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}