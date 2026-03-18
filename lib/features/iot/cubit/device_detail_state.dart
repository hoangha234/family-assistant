part of 'device_detail_cubit.dart';

class DeviceDetailState extends Equatable {
  final bool isPowerOn;
  final double brightness;
  final Color selectedColor;
  final int selectedPresetIndex;
  final bool ledStatus;
  final bool fanStatus;

  const DeviceDetailState({
    this.isPowerOn = true,
    this.brightness = 85.0,
    this.selectedColor = const Color(0xFF2B7CEE),
    this.selectedPresetIndex = 0,
    this.ledStatus = false,
    this.fanStatus = false,
  });

  DeviceDetailState copyWith({
    bool? isPowerOn,
    double? brightness,
    Color? selectedColor,
    int? selectedPresetIndex,
    bool? ledStatus,
    bool? fanStatus,
  }) {
    return DeviceDetailState(
      isPowerOn: isPowerOn ?? this.isPowerOn,
      brightness: brightness ?? this.brightness,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedPresetIndex: selectedPresetIndex ?? this.selectedPresetIndex,
      ledStatus: ledStatus ?? this.ledStatus,
      fanStatus: fanStatus ?? this.fanStatus,
    );
  }

  @override
  List<Object> get props => [
    isPowerOn,
    brightness,
    selectedColor,
    selectedPresetIndex,
    ledStatus,
    fanStatus,
  ];
}
