part of 'device_detail_cubit.dart';

class DeviceDetailState extends Equatable {
  final bool isPowerOn;
  final double brightness;
  final Color selectedColor;
  final int selectedPresetIndex;

  const DeviceDetailState({
    this.isPowerOn = true,
    this.brightness = 85.0,
    this.selectedColor = const Color(0xFF2B7CEE),
    this.selectedPresetIndex = 0,
  });

  DeviceDetailState copyWith({
    bool? isPowerOn,
    double? brightness,
    Color? selectedColor,
    int? selectedPresetIndex,
  }) {
    return DeviceDetailState(
      isPowerOn: isPowerOn ?? this.isPowerOn,
      brightness: brightness ?? this.brightness,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedPresetIndex: selectedPresetIndex ?? this.selectedPresetIndex,
    );
  }

  @override
  List<Object> get props => [
        isPowerOn,
        brightness,
        selectedColor,
        selectedPresetIndex,
      ];
}
