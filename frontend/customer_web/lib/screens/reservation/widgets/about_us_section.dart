import 'package:flutter/material.dart';

class AboutUsSection extends StatelessWidget {
  const AboutUsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 800;
          List<Widget> children = [
            // Cột 1: Ảnh
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1600891964092-4316c288032e?q=80&w=2070&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  height: isDesktop ? 400 : 300,
                  width: double.infinity,
                ),
              ),
            ),
            if (isDesktop) const SizedBox(width: 60) else const SizedBox(height: 30),
            // Cột 2: Text
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Câu chuyện của ROS',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Khởi nguồn từ niềm đam mê mãnh liệt với nghệ thuật ẩm thực, ROS được sinh ra với sứ mệnh mang đến những trải nghiệm vị giác thăng hoa nhất. Chúng tôi tự hào kết hợp tinh hoa ẩm thực Á - Âu cùng nguồn nguyên liệu tươi sạch, được tuyển chọn khắt khe mỗi ngày. Tại ROS, mỗi món ăn không chỉ là một kiệt tác trên đĩa, mà còn là một câu chuyện được kể bằng sự tận tâm của những người đầu bếp tài hoa.',
                    style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ];

          return isDesktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: children)
              : Column(children: children);
        },
      ),
    );
  }
}