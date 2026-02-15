class DailyNoteSection {
  final String id;
  final String topicId;
  final String heading;
  final dynamic contentJson; // Can be List or Map depending on Quill version, usually List of operations
  final int orderIndex;
  final DateTime createdAt;

  DailyNoteSection({
    required this.id,
    required this.topicId,
    required this.heading,
    required this.contentJson,
    required this.orderIndex,
    required this.createdAt,
  });

  factory DailyNoteSection.fromJson(Map<String, dynamic> json) {
    return DailyNoteSection(
      id: json['id'],
      topicId: json['topic_id'],
      heading: json['heading'],
      contentJson: json['content_json'],
      orderIndex: json['order_index'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic_id': topicId,
      'heading': heading,
      'content_json': contentJson,
      'order_index': orderIndex,
    };
  }
}
