import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../cubit/iot_dashboard_cubit.dart';

class IotDashboardScreen extends StatelessWidget {
  const IotDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IotDashboardCubit(),
      child: const IotDashboardView(),
    );
  }
}

class IotDashboardView extends StatelessWidget {
  const IotDashboardView({super.key});

  final Color primaryColor = const Color(0xFF2B7CEE);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color bgDark = const Color(0xFF101822);
  final Color textDark = const Color(0xFF111418);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final textColor = isDarkMode ? Colors.white : textDark;

    return BlocBuilder<IotDashboardCubit, IotDashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              SafeArea(
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
                              child: Column(
                                children: [
                                  _buildDeviceGrid(context, state, isDarkMode, textColor),
                                  const SizedBox(height: 20),
                                  _buildCameraFeed(isDarkMode),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
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
            "Smart Home",
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
          )
        ],
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildSceneSelector(bool isDarkMode, Color textColor) {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.home, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text("Home",
                    style: GoogleFonts.manrope(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildSceneChip(Icons.flight_takeoff, "Away", isDarkMode, textColor),
          const SizedBox(width: 12),
          _buildSceneChip(Icons.bedtime, "Sleep", isDarkMode, textColor),
        ],
      ),
    );
  }

  Widget _buildSceneChip(IconData icon, String label, bool isDarkMode, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2737) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.manrope(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDeviceGrid(BuildContext context, IotDashboardState state, bool isDarkMode, Color textColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 20,
      crossAxisSpacing: 20,
      childAspectRatio: 0.85,
      children: [
        _buildDeviceCard(
          "Living Room", "On • 80%", Icons.lightbulb_circle, state.isLightOn, isDarkMode, textColor,
          onTap: () => context.read<IotDashboardCubit>().toggleLight(),
        ),
        _buildDeviceCard(
          "Air Conditioner", "22°C • Cooling", Icons.ac_unit, state.isACOn, isDarkMode, textColor,
          onTap: () => context.read<IotDashboardCubit>().toggleAC(),
        ),
        _buildDeviceCard(
          "Smart TV", "Off", Icons.tv, state.isTVOn, isDarkMode, textColor,
          onTap: () => context.read<IotDashboardCubit>().toggleTV(),
        ),
        _buildDeviceCard(
          "Front Door", "Monitoring", Icons.videocam, state.isCameraOn, isDarkMode, textColor,
          isLive: true,
          onTap: () => context.read<IotDashboardCubit>().toggleCamera(),
        ),
        _buildDeviceCard(
          "Thermostat", "Active", Icons.thermostat, state.isThermostatOn, isDarkMode, textColor,
          isPressedStyle: true,
          onTap: () => context.read<IotDashboardCubit>().toggleThermostat(),
        ),
        _buildDeviceCard(
          "Smart Plug", "Off", Icons.power, state.isPlugOn, isDarkMode, textColor,
          onTap: () => context.read<IotDashboardCubit>().togglePlug(),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(String title, String status, IconData icon, bool isOn,
      bool isDarkMode, Color textColor,
      {bool isLive = false, bool isPressedStyle = false, required VoidCallback onTap}) {
    List<BoxShadow> shadows;
    if (isDarkMode) {
      shadows = [
        const BoxShadow(color: Color(0xFF0A0F15), offset: Offset(6, 6), blurRadius: 12),
        const BoxShadow(color: Color(0xFF1A2737), offset: Offset(-2, -2), blurRadius: 10),
      ];
    } else {
      shadows = [
        const BoxShadow(color: Color(0xFFE2E3E4), offset: Offset(6, 6), blurRadius: 12),
        const BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 12),
      ];
    }

    if (isOn && !isPressedStyle) {
      shadows.add(BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 15,
        spreadRadius: 1,
      ));
    }

    BoxBorder? border;
    if (isPressedStyle) {
      shadows = [];
      border = Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1));
    } else if (isOn) {
      border = Border.all(color: Colors.white.withOpacity(0.2));
    } else {
      border = Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5));
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF101822) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          boxShadow: shadows,
          border: border,
        ),
        child: Opacity(
          opacity: isOn ? 1.0 : 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isOn ? primaryColor.withOpacity(0.1) : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isOn ? primaryColor : Colors.grey[400],
                      size: 28,
                    ),
                  ),
                  if (isLive)
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        const Text("LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    )
                  else
                    Container(
                      width: 40,
                      height: 20,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isOn ? primaryColor : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Align(
                        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.manrope(
                          fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(status,
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: isOn ? FontWeight.w600 : FontWeight.normal,
                          color: isOn ? primaryColor : const Color(0xFF617289))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFeed(bool isDarkMode) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF101822) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDarkMode
            ? [
                const BoxShadow(color: Color(0xFF0A0F15), offset: Offset(6, 6), blurRadius: 12),
                const BoxShadow(color: Color(0xFF1A2737), offset: Offset(-2, -2), blurRadius: 10),
              ]
            : [
                const BoxShadow(color: Color(0xFFE2E3E4), offset: Offset(6, 6), blurRadius: 12),
                const BoxShadow(color: Colors.white, offset: Offset(-6, -6), blurRadius: 12),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1558002038-1091a166111d?q=80&w=800&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 12,
              left: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      children: [
                        const Icon(Icons.sensors, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          "FRONT DOOR LIVE",
                          style: GoogleFonts.manrope(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




}
