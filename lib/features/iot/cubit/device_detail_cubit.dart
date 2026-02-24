import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'device_detail_state.dart';

class DeviceDetailCubit extends Cubit<DeviceDetailState> {
  DeviceDetailCubit() : super(const DeviceDetailState());

  void togglePower() {
    emit(state.copyWith(isPowerOn: !state.isPowerOn));
  }

  void updateBrightness(double value) {
    emit(state.copyWith(brightness: value));
  }

  void updateColor(Color color) {
    emit(state.copyWith(selectedColor: color));
  }

  void selectPreset(int index) {
    emit(state.copyWith(selectedPresetIndex: index));
  }
}
