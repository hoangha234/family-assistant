import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:family_assistant/main.dart'; // For AuthWrapper

class IMateSplashScreen extends StatefulWidget {
  const IMateSplashScreen({super.key});

  @override
  State<IMateSplashScreen> createState() => _IMateSplashScreenState();
}

class _IMateSplashScreenState extends State<IMateSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  // Animation cho Robot (Phase 1)
  late Animation<double> _robotScaleAnim;
  late Animation<double> _robotOpacityAnim;
  
  // Animation cho tính năng Glow/Vẫy tay (Phase 3)
  late Animation<double> _robotGlowAnim;

  final double _radius = 140.0; // Khoảng cách từ robot đến các icon

  // Danh sách cấu hình các icon tính năng kèm góc bắn ra (tính bằng Radian)
  final List<FeatureConfig> _features = [
    FeatureConfig(icon: Icons.monitor_heart, angle: math.pi, label: 'Health'), // Trái
    FeatureConfig(icon: Icons.account_balance_wallet, angle: -math.pi * 3 / 4, label: 'Finance'), // Trên trái
    FeatureConfig(icon: Icons.shopping_cart, angle: -math.pi / 4, label: 'Shopping'), // Trên phải
    FeatureConfig(icon: Icons.restaurant, angle: math.pi / 12, label: 'Meal'), // Phải (hơi chúi xuống)
    FeatureConfig(icon: Icons.smart_toy, angle: math.pi / 2, label: 'IoT'), // Dưới
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Phase 1: Robot ScaleUp & FadeIn (0.0 -> 0.3)
    _robotScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack)),
    );
    _robotOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    // Phase 3: Robot Glow Effect (0.8 -> 1.0)
    _robotGlowAnim = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeInOut)),
    );

    _playAnimationSequence();
  }

  void _playAnimationSequence() async {
    // Chạy Phase 1, 2, 3 (Bay ra)
    await _controller.forward();
    
    // Dừng lại 1.5s để user ngắm sự cute hột me này
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Phase 4: Thu về hội tụ tại Robot
    await _controller.reverse();
    
    // Check if widget is still mounted
    if (!mounted) return;

    // Chuyển sang màn AuthWrapper thay vì navigate trực tiếp HomeScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF9F4), // Màu xanh mint nhạt
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background Gradient toả tròn mờ mờ
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFFD1F2E6), Color(0xFFEAF9F4)],
                radius: 0.8,
              ),
            ),
          ),
          
          // Vẽ các icon và đường kết nối bay ra xung quanh
          ...List.generate(_features.length, (index) {
            // Staggered Animation cho từng icon bay ra tuần tự
            final start = 0.3 + (index * 0.1);
            final end = start + 0.2;
            final flyAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Interval(start, end > 1.0 ? 1.0 : end, curve: Curves.easeOutBack),
              ),
            );

            return AnimatedBuilder(
              animation: flyAnim,
              builder: (context, child) {
                final currentRadius = _radius * flyAnim.value;
                final dx = currentRadius * math.cos(_features[index].angle);
                final dy = currentRadius * math.sin(_features[index].angle);

                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Opacity(
                    opacity: flyAnim.value.clamp(0.0, 1.0),
                    child: _buildFeatureIcon(_features[index].icon),
                  ),
                );
              },
            );
          }),

          // Trung tâm: Chú Robot
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _robotScaleAnim.value,
                child: Opacity(
                  opacity: _robotOpacityAnim.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF70E0BB).withOpacity(0.6),
                          blurRadius: _robotGlowAnim.value,
                          spreadRadius: _robotGlowAnim.value / 2,
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/robot.png'),
                      radius: 75,
                    ),
                  ),
                ),
              );
            },
          ),

          // Branding dưới cùng
          Positioned(
            bottom: 60,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _robotOpacityAnim.value,
                  child: const Column(
                    children: [
                      Text(
                        'iMate',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF45B08C),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your Personal Assistant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF70E0BB).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF45B08C), size: 32),
    );
  }
}

class FeatureConfig {
  final IconData icon;
  final double angle;
  final String label;

  FeatureConfig({required this.icon, required this.angle, required this.label});
}
