part of 'iot_cubit.dart';

class IotState extends Equatable {
  final double temperature;
  final double humidity;
  final bool ledStatus;
  final bool fanStatus;
  final bool isConnected;
  final String? errorMessage;

  const IotState({
    this.temperature = 0,
    this.humidity = 0,
    this.ledStatus = false,
    this.fanStatus = false,
    this.isConnected = false,
    this.errorMessage,
  });

  IotState copyWith({
    double? temperature,
    double? humidity,
    bool? ledStatus,
    bool? fanStatus,
    bool? isConnected,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IotState(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      ledStatus: ledStatus ?? this.ledStatus,
      fanStatus: fanStatus ?? this.fanStatus,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    temperature,
    humidity,
    ledStatus,
    fanStatus,
    isConnected,
    errorMessage,
  ];
}
