import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/iot_cubit.dart';

class IotDashboardScreen extends StatelessWidget {
  const IotDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IotCubit>(
      create: (_) => IotCubit(),
      child: const IotDashboardView(),
    );
  }
}

class IotDashboardView extends StatelessWidget {
  const IotDashboardView({super.key});

  static const Color primaryColor = Color(0xFF2B7CEE);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color bgDark = Color(0xFF101822);
  static const Color textDark = Color(0xFF111418);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDarkMode ? bgDark : bgLight;
    final Color textColor = isDarkMode ? Colors.white : textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(textColor, isDarkMode),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSceneSelector(isDarkMode, textColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: BlocBuilder<IotCubit, IotState>(
                        builder: (context, iotState) {
                          return _buildDeviceGrid(
                            context,
                            iotState,
                            isDarkMode,
                            textColor,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNeuIconBtn(Icons.arrow_back_ios_new, primaryColor, isDarkMode),
          Text(
            'Smart Home',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          _buildNeuIconBtn(Icons.add, primaryColor, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildNeuIconBtn(IconData icon, Color iconColor, bool isDarkMode) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildSceneSelector(bool isDarkMode, Color textColor) {
    // Preserve spacing so the cards do not sit directly under the header.
    return const SizedBox(height: 70);
  }

  Widget _buildDeviceGrid(
    BuildContext context,
    IotState iotState,
    bool isDarkMode,
    Color textColor,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.84,
      children: [
        _ControlCard(
          title: 'Light',
          icon: Icons.lightbulb,
          isOn: iotState.ledStatus,
          primaryColor: primaryColor,
          isDarkMode: isDarkMode,
          textColor: textColor,
          onToggle: (value) => context.read<IotCubit>().toggleLed(value),
        ),
        _ControlCard(
          title: 'Fan',
          icon: Icons.toys,
          isOn: iotState.fanStatus,
          primaryColor: primaryColor,
          isDarkMode: isDarkMode,
          textColor: textColor,
          onToggle: (value) => context.read<IotCubit>().toggleFan(value),
        ),
        _SensorCard(
          title: 'Temperature',
          icon: Icons.thermostat,
          value: '${iotState.temperature.toStringAsFixed(1)} °C',
          primaryColor: primaryColor,
          isDarkMode: isDarkMode,
          textColor: textColor,
        ),
        _SensorCard(
          title: 'Humidity',
          icon: Icons.water_drop,
          value: '${iotState.humidity.toStringAsFixed(1)} %',
          primaryColor: primaryColor,
          isDarkMode: isDarkMode,
          textColor: textColor,
        ),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.title,
    required this.icon,
    required this.isOn,
    required this.onToggle,
    required this.primaryColor,
    required this.isDarkMode,
    required this.textColor,
  });

  final String title;
  final IconData icon;
  final bool isOn;
  final ValueChanged<bool> onToggle;
  final Color primaryColor;
  final bool isDarkMode;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> shadows = isDarkMode
        ? [
            const BoxShadow(
              color: Color(0xFF0A0F15),
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
            const BoxShadow(
              color: Color(0xFF1A2737),
              offset: Offset(-2, -2),
              blurRadius: 10,
            ),
          ]
        : [
            const BoxShadow(
              color: Color(0xFFE2E3E4),
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF101822) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          ...shadows,
          if (isOn)
            BoxShadow(
              color: primaryColor.withOpacity(0.28),
              blurRadius: 14,
              spreadRadius: 1,
            ),
        ],
        border: Border.all(
          color: isOn
              ? primaryColor.withOpacity(0.35)
              : (isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.65)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOn
                  ? primaryColor.withOpacity(0.12)
                  : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isOn ? primaryColor : Colors.grey.shade400,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.scale(
              scale: 0.95,
              child: Switch(
                value: isOn,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: primaryColor,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.primaryColor,
    required this.isDarkMode,
    required this.textColor,
  });

  final String title;
  final IconData icon;
  final String value;
  final Color primaryColor;
  final bool isDarkMode;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> shadows = isDarkMode
        ? [
            const BoxShadow(
              color: Color(0xFF0A0F15),
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
            const BoxShadow(
              color: Color(0xFF1A2737),
              offset: Offset(-2, -2),
              blurRadius: 10,
            ),
          ]
        : [
            const BoxShadow(
              color: Color(0xFFE2E3E4),
              offset: Offset(6, 6),
              blurRadius: 12,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-6, -6),
              blurRadius: 12,
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF101822) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: shadows,
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
