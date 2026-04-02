import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../../home/screens/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginView();
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isPasswordVisible = false;

  // TextEditingControllers for email and password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Bảng màu từ Tailwind Config
  final Color primary = const Color(0xFF43618E);
  final Color primaryDark = const Color(0xFF0F2C59);
  final Color primaryLight = const Color(0xFF4DA8DA);
  final Color backgroundLight = const Color(0xFFFAF9F6);
  final Color accentSage = const Color(0xFF8DA399);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Handle authenticated - navigate to HomeScreen
        if (state.isAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        // Handle error - show SnackBar
        if (state.hasError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<AuthCubit>().clearError();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundLight,
        body: Column(
          children: [
            // Header spans full width
            _buildHeader(size),
            // Form container is constrained
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 448,
                  ),
                  child: _buildFormContainer(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PHẦN HEADER (Gradient & Hình vẽ) ---
  Widget _buildHeader(Size size) {
    return Container(
      width: double.infinity, // 1. Thêm dòng này để dải gradient trải rộng full màn hình
      height: size.height * 0.38 < 300 ? 300 : size.height * 0.38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDark, primary, primaryLight],
          stops: const [0.0, 0.6, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          // Hiệu ứng bong bóng blur (trên trái)
          Positioned(
            top: -50,
            left: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
          ),
          // Hiệu ứng bong bóng blur (dưới phải)
          Positioned(
            bottom: -40,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 192,
                height: 192,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryLight.withOpacity(0.3),
                ),
              ),
            ),
          ),

          // Nội dung chính của Header
          SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity, // 2. Thêm dòng này để căn giữa trục ngang cho Column
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Illustration vẽ bằng CustomPainter
                  SizedBox(
                    width: 192,
                    height: 120,
                    child: CustomPaint(
                      painter: FamilyIllustrationPainter(), // Giữ nguyên CustomPainter đã tạo
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Text Title
                  const Text(
                    'Family Assistant',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart living for modern families',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70, // Đổi một chút sang white70 cho thanh thoát
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PHẦN FORM & NÚT BẤM ---
  Widget _buildFormContainer() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'name@example.com',
                icon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                isPassword: true,
              ),
              const SizedBox(height: 12),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    // TODO: Navigate to forgot password screen
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          context.read<AuthCubit>().login(
                                _emailController.text,
                                _passwordController.text,
                              );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 24),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 32),
              _buildDivider(),
              const SizedBox(height: 32),

              // Social Login Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      label: 'Google',
                      logo: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      onTap: state.isLoading
                          ? null
                          : () {
                              context.read<AuthCubit>().loginWithGoogle();
                            },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSocialButton(
                      label: 'Apple',
                      logo:
                          const Icon(Icons.apple, size: 24, color: Colors.black),
                      onTap: () {
                        // TODO: Implement Apple Sign In
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 14, color: slate500),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET INPUT TEXT ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: slate500,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            style: TextStyle(color: slate800, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(icon, color: const Color(0xFF94A3B8)),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    BorderSide(color: accentSage.withOpacity(0.5), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET DIVIDER ---
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Or continue with',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: slate500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey.shade300, thickness: 1),
        ),
      ],
    );
  }

  // --- WIDGET NÚT SOCIAL ---
  Widget _buildSocialButton({
    required String label,
    required Widget logo,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            logo,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: slate800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// CUSTOM PAINTER: Vẽ chính xác lại mã SVG illustration
// ======================================================================
class FamilyIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // ViewBox gốc của SVG là 200 x 120
    final double scaleX = size.width / 200;
    final double scaleY = size.height / 120;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 1. Mái nhà
    final roofPath = Path()
      ..moveTo(40, 60)
      ..lineTo(100, 20)
      ..lineTo(160, 60);

    canvas.drawShadow(roofPath, Colors.black.withOpacity(0.5), 2, false);
    canvas.drawPath(roofPath, paint);

    // 2. Hình tròn gia đình (Trái)
    canvas.drawCircle(const Offset(85, 80), 15, paint);

    // 3. Hình tròn gia đình (Phải)
    canvas.drawCircle(const Offset(115, 80), 15, paint);

    // 4. Đường nối nụ cười
    final smilePath = Path()
      ..moveTo(85, 95)
      ..quadraticBezierTo(100, 105, 115, 95);
    canvas.drawPath(smilePath, paint);

    // 5. Trái tim nổi lơ lửng
    final heartPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final heartPath = Path()
      ..moveTo(100, 45)
      ..cubicTo(100, 45, 95, 40, 92, 40)
      ..cubicTo(88, 40, 86, 43, 86, 46)
      ..cubicTo(86, 52, 100, 60, 100, 60)
      ..cubicTo(100, 60, 114, 52, 114, 46)
      ..cubicTo(114, 43, 112, 40, 108, 40)
      ..cubicTo(105, 40, 100, 45, 100, 45)
      ..close();
    canvas.drawPath(heartPath, heartPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

