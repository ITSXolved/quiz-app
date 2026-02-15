class DailySession {
  final String id;
  final DateTime sessionDate;
  final String heading;
  final String content;
  final int orderIndex;
  final DateTime createdAt;

  DailySession({
    required this.id,
    required this.sessionDate,
    required this.heading,
    required this.content,
    required this.orderIndex,
    required this.createdAt,
  });

  factory DailySession.fromJson(Map<String, dynamic> json) {
    return DailySession(
      id: json['id'],
      sessionDate: DateTime.parse(json['session_date']),
      heading: json['heading'],
      content: json['content'],
      orderIndex: json['order_index'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_date': '${sessionDate.year}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}',
      'heading': heading,
      'content': content,
      'order_index': orderIndex,
    };
  }
}
