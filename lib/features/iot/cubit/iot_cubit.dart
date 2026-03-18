import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../services/mqtt_service.dart';

part 'iot_state.dart';

class IotCubit extends Cubit<IotState> {
  IotCubit({MqttService? mqttService})
    : _mqttService = mqttService ?? MqttService(),
      super(const IotState()) {
    initialize();
  }

  final MqttService _mqttService;
  StreamSubscription<MqttIncomingMessage>? _messagesSubscription;

  Future<void> initialize() async {
    final bool connected = await _mqttService.connect();
    emit(
      state.copyWith(
        isConnected: connected,
        clearError: connected,
        errorMessage: connected ? null : 'Unable to connect to MQTT broker.',
      ),
    );

    await _messagesSubscription?.cancel();
    _messagesSubscription = _mqttService.messages.listen(
      _onIncomingMessage,
      onError: (_) {
        emit(
          state.copyWith(
            errorMessage: 'Error while listening to MQTT messages.',
          ),
        );
      },
    );
  }

  void setLedStatus(bool isOn) {
    emit(state.copyWith(ledStatus: isOn));
  }

  void setFanStatus(bool isOn) {
    emit(state.copyWith(fanStatus: isOn));
  }

  Future<void> toggleLed(bool isOn) async {
    await _mqttService.publishLed(isOn);
    emit(state.copyWith(ledStatus: isOn, clearError: true));
  }

  Future<void> toggleFan(bool isOn) async {
    await _mqttService.publishFan(isOn);
    emit(state.copyWith(fanStatus: isOn, clearError: true));
  }

  void _onIncomingMessage(MqttIncomingMessage message) {
    if (message.topic != MqttService.sensorTopic) {
      return;
    }

    try {
      final dynamic decoded = jsonDecode(message.payload);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final double? temperature = (decoded['temperature'] as num?)?.toDouble();
      final double? humidity = (decoded['humidity'] as num?)?.toDouble();

      if (temperature == null || humidity == null) {
        return;
      }

      emit(
        state.copyWith(
          temperature: temperature,
          humidity: humidity,
          clearError: true,
        ),
      );
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Invalid sensor payload received.'));
    }
  }

  @override
  Future<void> close() async {
    await _messagesSubscription?.cancel();
    return super.close();
  }
}
