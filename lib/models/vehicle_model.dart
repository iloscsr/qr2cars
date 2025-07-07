class VehicleModel {
  final String id;
  final String name;
  final String licensePlate;
  final DateTime createdAt;
  final String qrContent;

  VehicleModel({
    required this.id,
    required this.name,
    required this.licensePlate,
    required this.createdAt,
    String? qrContent,
  }) : qrContent = qrContent ?? 'Araç: $name\nPlaka: $licensePlate\nSahip: QR2Cars Kullanıcısı';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'licensePlate': licensePlate,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'qrContent': qrContent,
    };
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      name: json['name'],
      licensePlate: json['licensePlate'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      qrContent: json['qrContent'],
    );
  }

  VehicleModel copyWith({
    String? id,
    String? name,
    String? licensePlate,
    DateTime? createdAt,
    String? qrContent,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      licensePlate: licensePlate ?? this.licensePlate,
      createdAt: createdAt ?? this.createdAt,
      qrContent: qrContent ?? this.qrContent,
    );
  }

  @override
  String toString() {
    return 'VehicleModel(id: $id, name: $name, licensePlate: $licensePlate, createdAt: $createdAt, qrContent: $qrContent)';
  }
} 