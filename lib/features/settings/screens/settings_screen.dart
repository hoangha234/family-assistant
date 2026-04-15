import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../cubit/settings_cubit.dart';
import '../../home/cubit/home_cubit.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/screens/login_screen.dart';
import '../../iot/screens/iot_dashboard_screen.dart';
import '../../health/screens/health_report_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => AuthCubit()..initialize())],
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  final Color primaryColor = const Color(0xFF2B7CEE);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color bgDark = const Color(0xFF101822);
  final Color textDark = const Color(0xFF111418);
  final Color textGrey = const Color(0xFF617289);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? bgDark : bgLight;
    final cardColor = isDarkMode ? const Color(0xFF1A2737) : Colors.white;
    final textColor = isDarkMode ? Colors.white : textDark;
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.grey[200]!;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context, textColor, borderColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        _buildProfileHeader(textColor, borderColor),
                        _buildSectionHeader("Account & Health"),
                        _buildSectionContainer(
                          cardColor,
                          borderColor,
                          children: [
                            _buildSettingsTile(
                              icon: Icons.favorite,
                              title: "Health Data",
                              textColor: textColor,
                              showBorder: true,
                              borderColor: borderColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HealthReportScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildSettingsTile(
                              icon: Icons.person,
                              title: "Profile Details",
                              subtitle: "Update your personal info",
                              textColor: textColor,
                              showBorder: false,
                              borderColor: borderColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<AuthCubit>(),
                                      child: const EditProfileScreen(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        _buildSectionHeader("Appearance"),
                        _buildSectionContainer(
                          cardColor,
                          borderColor,
                          children: [
                            _buildSwitchTile(
                              icon: Icons.dark_mode,
                              title: "Dark Mode",
                              value: state.isDarkMode,
                              onChanged: (val) => context
                                  .read<SettingsCubit>()
                                  .toggleDarkMode(val),
                              textColor: textColor,
                            ),
                          ],
                        ),
                        _buildSectionHeader("Connectivity"),
                        _buildSectionContainer(
                          cardColor,
                          borderColor,
                          children: [
                            _buildSettingsTile(
                              icon: Icons.hub,
                              title: "IoT Device Management",
                              textColor: textColor,
                              showBorder: false,
                              borderColor: borderColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const IotDashboardScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        _buildSectionHeader("Notifications"),
                        _buildSectionContainer(
                          cardColor,
                          borderColor,
                          children: [
                            _buildSwitchTile(
                              icon: Icons.notifications,
                              title: "Push Notifications",
                              value: state.pushNotifications,
                              onChanged: (val) => context
                                  .read<SettingsCubit>()
                                  .toggleNotifications(val),
                              textColor: textColor,
                              showBorder: false,
                              borderColor: borderColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () async {
                                // Show confirmation dialog
                                final shouldSignOut = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      'Sign Out',
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to sign out?',
                                      style: GoogleFonts.manrope(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.manrope(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(
                                          'Sign Out',
                                          style: GoogleFonts.manrope(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldSignOut == true && context.mounted) {
                                  // Sign out using AuthCubit
                                  await context.read<AuthCubit>().signOut();

                                  // Navigate to LoginScreen and clear all routes
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Colors.red.withOpacity(0.2)
                                    : const Color(0xFFFEF2F2),
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? Colors.red.withOpacity(0.3)
                                        : const Color(0xFFFEE2E2),
                                  ),
                                ),
                              ),
                              child: Text(
                                "Sign Out",
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "iMate v1.0.0",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: textGrey,
                          ),
                        ),
                        const SizedBox(height: 24),
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

  Widget _buildAppBar(
    BuildContext context,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.read<HomeCubit>().setTab(0),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios, size: 20, color: textColor),
                    const SizedBox(width: 8),
                    Text(
                      "Settings",
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Color textColor, Color borderColor) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String name = "Guest";
        String email = "No email";
        String photoUrl = "https://i.pravatar.cc/150?img=12";

        if (state.status == AuthStatus.authenticated && state.user != null) {
          name = state.user!.displayName ?? name;
          email = state.user!.email ?? email;
          photoUrl = state.user!.photoUrl ?? photoUrl;
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AuthCubit>(),
                        child: const EditProfileScreen(),
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 4),
                        color: Colors.grey[200],
                        image: photoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: photoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B7CEE),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                email,
                style: GoogleFonts.manrope(fontSize: 14, color: textGrey),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textGrey,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(
    Color cardColor,
    Color borderColor, {
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color textColor,
    required bool showBorder,
    required Color borderColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: showBorder
              ? Border(bottom: BorderSide(color: borderColor))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(fontSize: 12, color: textGrey),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    bool showBorder = false,
    Color borderColor = Colors.transparent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: borderColor))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }
}
