import 'package:flutter/material.dart';

class QuickActionRow extends StatelessWidget {
  const QuickActionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildActionItem(context, Icons.add_task, 'Thêm việc'),
          const SizedBox(width: 12),
          _buildActionItem(context, Icons.shopping_cart_outlined, 'Mua sắm'),
          const SizedBox(width: 12),
          _buildActionItem(context, Icons.restaurant_menu, 'Bữa ăn'),
          const SizedBox(width: 12),
          _buildActionItem(context, Icons.attach_money, 'Chi tiêu'),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
