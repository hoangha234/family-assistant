import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'iot_dashboard_state.dart';

class IotDashboardCubit extends Cubit<IotDashboardState> {
  IotDashboardCubit() : super(const IotDashboardState());

  void toggleLight() {
    emit(state.copyWith(isLightOn: !state.isLightOn));
  }

  void toggleAC() {
    emit(state.copyWith(isACOn: !state.isACOn));
  }

  void toggleTV() {
    emit(state.copyWith(isTVOn: !state.isTVOn));
  }

  void toggleCamera() {
    emit(state.copyWith(isCameraOn: !state.isCameraOn));
  }

  void toggleThermostat() {
    emit(state.copyWith(isThermostatOn: !state.isThermostatOn));
  }

  void togglePlug() {
    emit(state.copyWith(isPlugOn: !state.isPlugOn));
  }
}
