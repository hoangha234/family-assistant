import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../services/mqtt_service.dart';

part 'device_detail_state.dart';

class DeviceDetailCubit extends Cubit<DeviceDetailState> {
  DeviceDetailCubit({MqttService? mqttService})
    : _mqttService = mqttService ?? MqttService(),
      super(const DeviceDetailState()) {
    _initialize();
  }

  final MqttService _mqttService;

  Future<void> _initialize() async {
    await _mqttService.connect();
  }

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

  Future<void> toggleLed(bool value) async {
    await _mqttService.publishLed(value);
    emit(state.copyWith(ledStatus: value, isPowerOn: value));
  }

  Future<void> toggleFan(bool value) async {
    await _mqttService.publishFan(value);
    emit(state.copyWith(fanStatus: value));
  }
}
