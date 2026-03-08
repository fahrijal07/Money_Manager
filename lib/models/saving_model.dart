class SavingModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;

  SavingModel({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
    };
  }

  factory SavingModel.fromMap(Map<String, dynamic> map) {
    return SavingModel(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      savedAmount: map['savedAmount'],
    );
  }

  double get progress => savedAmount / targetAmount;
}
