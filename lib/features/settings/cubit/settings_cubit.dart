import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  void toggleDarkMode(bool value) {
    emit(state.copyWith(isDarkMode: value));
  }

  void toggleNotifications(bool value) {
    emit(state.copyWith(pushNotifications: value));
  }
}
