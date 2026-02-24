import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../cubit/device_detail_cubit.dart';

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DeviceDetailCubit(),
      child: const DeviceDetailView(),
    );
  }
}

class DeviceDetailView extends StatelessWidget {
  const DeviceDetailView({super.key});

  final Color primaryColor = const Color(0xFF2B7CEE);
  final Color bgLight = const Color(0xFFF6F7F8);
  final Color bgDark = const Color(0xFF101822);
  final Color textDark = const Color(0xFF111418);

  final List<Map<String, dynamic>> _presets = const [
    {
      "title": "Reading",
      "icon": Icons.menu_book,
      "img": "https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=400&q=80"
    },
    {
      "title": "Movie",
      "icon": Icons.movie,
      "img": "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=400&q=80"
    },
    {
      "title": "Relax",
      "icon": Icons.bedtime,
      "img": "https://images.unsplash.com/photo-1511296265581-c2450046447d?auto=format&fit=crop&w=400&q=80"
    },
    {
      "title": "Party",
      "icon": Icons.celebration,
      "img": "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=400&q=80"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;

    return BlocBuilder<DeviceDetailCubit, DeviceDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, textColor, isDarkMode),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildPowerButton(context, state),
                        const SizedBox(height: 24),
                        _buildColorWheel(state, isDarkMode),
                        const SizedBox(height: 32),
                        _buildBrightnessSlider(context, state, isDarkMode, textColor),
                        const SizedBox(height: 24),
                        _buildPresetSection(textColor),
                        _buildPresetGrid(context, state),
                        const SizedBox(height: 24),
                        _buildFooterInfo(textColor),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(Icons.arrow_back_ios_new, textColor, isDarkMode, onTap: () => Navigator.pop(context)),
          Column(
            children: [
              Text(
                "Living Room Light",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "CONNECTED",
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          _buildCircleButton(Icons.more_vert, textColor, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, Color color, bool isDarkMode, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildPowerButton(BuildContext context, DeviceDetailState state) {
    return GestureDetector(
      onTap: () => context.read<DeviceDetailCubit>().togglePower(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: state.isPowerOn ? primaryColor : Colors.grey,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (state.isPowerOn ? primaryColor : Colors.grey).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.power_settings_new, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              state.isPowerOn ? "Power On" : "Power Off",
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorWheel(DeviceDetailState state, bool isDarkMode) {
    return Column(
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.white,
                    width: 4,
                  ),
                ),
                child: CustomPaint(
                  size: const Size(280, 280),
                  painter: ColorWheelPainter(),
                ),
              ),
              Positioned(
                right: 40,
                top: 80,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: state.selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[900]! : Colors.grey[50]!,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: state.selectedColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)]
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "COLOR SELECTION",
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBrightnessSlider(BuildContext context, DeviceDetailState state, bool isDarkMode, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.brightness_6, color: primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      "Brightness",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${state.brightness.toInt()}%",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primaryColor,
                inactiveTrackColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                trackHeight: 12,
                thumbColor: isDarkMode ? primaryColor : Colors.white,
                overlayColor: primaryColor.withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(
                value: state.brightness,
                min: 0,
                max: 100,
                onChanged: (value) => context.read<DeviceDetailCubit>().updateBrightness(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSection(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Preset Scenes",
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            "Edit",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetGrid(BuildContext context, DeviceDetailState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: _presets.length,
        itemBuilder: (context, index) {
          final preset = _presets[index];
          final isSelected = state.selectedPresetIndex == index;

          return GestureDetector(
            onTap: () => context.read<DeviceDetailCubit>().selectPreset(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: primaryColor, width: 3) : null,
                image: DecorationImage(
                  image: NetworkImage(preset['img']),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken
                  ),
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
                ]
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Row(
                      children: [
                        Icon(preset['icon'], color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          preset['title'],
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooterInfo(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Usage Status", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              Text("Active for 4h 12m", style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("8.4W", style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
              Text("Current Power", style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final sweepShader = const SweepGradient(
      colors: [
        Colors.red,
        Colors.yellow,
        Colors.green,
        Colors.cyan,
        Colors.blue,
        Colors.purple,
        Colors.red,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final paint = Paint()..shader = sweepShader;
    canvas.drawCircle(center, radius, paint);

    final radialShader = RadialGradient(
      colors: [
        Colors.white,
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.85],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final radialPaint = Paint()..shader = radialShader;
    canvas.drawCircle(center, radius, radialPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
