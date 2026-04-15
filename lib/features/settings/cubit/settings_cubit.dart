import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../health/services/notification_service.dart';
import '../../health/services/hydration_service.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? true;
    final pushNotifications = prefs.getBool('pushNotifications') ?? true;
    emit(state.copyWith(
      isDarkMode: isDarkMode,
      pushNotifications: pushNotifications,
    ));
  }

  Future<void> toggleDarkMode(bool value) async {
    emit(state.copyWith(isDarkMode: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  Future<void> toggleNotifications(bool value) async {
    emit(state.copyWith(pushNotifications: value));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotifications', value);
    
    if (value) {
      try {
        final plan = await HydrationService().getOrCreateTodayPlan();
        await NotificationService.scheduleHydrationReminders(plan.sessions);
      } catch (e) {
        // Ignored if user not logged in
      }
    } else {
      await NotificationService.cancelAllHydrationReminders();
    }
  }
}
