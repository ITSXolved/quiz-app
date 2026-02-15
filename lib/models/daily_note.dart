class DailyNote {
  final String id;
  final DateTime noteDate;
  final String content;
  final DateTime createdAt;

  DailyNote({
    required this.id,
    required this.noteDate,
    required this.content,
    required this.createdAt,
  });

  factory DailyNote.fromJson(Map<String, dynamic> json) {
    return DailyNote(
      id: json['id'],
      noteDate: DateTime.parse(json['note_date']),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note_date': '${noteDate.year}-${noteDate.month.toString().padLeft(2, '0')}-${noteDate.day.toString().padLeft(2, '0')}',
      'content': content,
    };
  }
}
