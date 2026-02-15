class DailyTopic {
  final String id;
  final DateTime topicDate;
  final String title;
  final bool isActive;
  final DateTime createdAt;

  DailyTopic({
    required this.id,
    required this.topicDate,
    required this.title,
    required this.isActive,
    required this.createdAt,
  });

  factory DailyTopic.fromJson(Map<String, dynamic> json) {
    return DailyTopic(
      id: json['id'],
      topicDate: DateTime.parse(json['topic_date']),
      title: json['title'],
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic_date': '${topicDate.year}-${topicDate.month.toString().padLeft(2, '0')}-${topicDate.day.toString().padLeft(2, '0')}',
      'title': title,
      'is_active': isActive,
    };
  }
}
