class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'info', 'warning', 'success', 'error'

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.type = 'info',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'info',
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, message: $message, createdAt: $createdAt, isRead: $isRead, type: $type)';
  }
} 