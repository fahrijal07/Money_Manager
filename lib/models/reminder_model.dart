class ReminderModel {
  final int? id;
  final String title;
  final String description;
  final DateTime dateTime;
  final bool isActive;

  ReminderModel({
    this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['dateTime']),
      isActive: map['isActive'] == 1,
    );
  }
}
