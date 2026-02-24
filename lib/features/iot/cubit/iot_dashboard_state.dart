part of 'iot_dashboard_cubit.dart';

class IotDashboardState extends Equatable {
  final bool isLightOn;
  final bool isACOn;
  final bool isTVOn;
  final bool isCameraOn;
  final bool isThermostatOn;
  final bool isPlugOn;

  const IotDashboardState({
    this.isLightOn = true,
    this.isACOn = true,
    this.isTVOn = false,
    this.isCameraOn = true,
    this.isThermostatOn = true,
    this.isPlugOn = false,
  });

  IotDashboardState copyWith({
    bool? isLightOn,
    bool? isACOn,
    bool? isTVOn,
    bool? isCameraOn,
    bool? isThermostatOn,
    bool? isPlugOn,
  }) {
    return IotDashboardState(
      isLightOn: isLightOn ?? this.isLightOn,
      isACOn: isACOn ?? this.isACOn,
      isTVOn: isTVOn ?? this.isTVOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      isThermostatOn: isThermostatOn ?? this.isThermostatOn,
      isPlugOn: isPlugOn ?? this.isPlugOn,
    );
  }

  @override
  List<Object> get props => [
        isLightOn,
        isACOn,
        isTVOn,
        isCameraOn,
        isThermostatOn,
        isPlugOn,
      ];
}
