class IotDeviceModel {
  final String id;
  final String name;
  final String type;
  final bool status;

  const IotDeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
  });

  IotDeviceModel copyWith({
    String? id,
    String? name,
    String? type,
    bool? status,
  }) {
    return IotDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'type': type, 'status': status};
  }

  factory IotDeviceModel.fromMap(Map<String, dynamic> map) {
    return IotDeviceModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      status: map['status'] as bool? ?? false,
    );
  }
}
