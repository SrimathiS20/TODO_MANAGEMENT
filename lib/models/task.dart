class Task {
  String title;
  bool isCompleted;
  String? description;
  DateTime? date;

  Task({
    required this.title,
    required this.isCompleted,
    this.description,
    this.date,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
      description: json['description'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'description': description,
      'date': date?.toIso8601String(),
    };
  }
}  