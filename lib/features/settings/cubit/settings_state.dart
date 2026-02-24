part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final bool pushNotifications;

  const SettingsState({
    this.isDarkMode = true,
    this.pushNotifications = true,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? pushNotifications,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }

  @override
  List<Object> get props => [isDarkMode, pushNotifications];
}
