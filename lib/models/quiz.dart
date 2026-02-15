enum QuizStatus { draft, published }

class Quiz {
  final String id;
  final String title;
  final String? description;
  final DateTime quizDate;
  final int durationMinutes;
  final QuizStatus status;
  final String? createdBy;
  final DateTime? createdAt;
  final int questionCount; // Join/Count field

  Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.quizDate,
    this.durationMinutes = 30,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.questionCount = 0,
  });

  static QuizStatus statusFromString(String s) {
    return s == 'published' ? QuizStatus.published : QuizStatus.draft;
  }

  static String statusToString(QuizStatus s) {
    return s == QuizStatus.published ? 'published' : 'draft';
  }

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      quizDate: DateTime.parse(json['quiz_date']),
      durationMinutes: json['duration_minutes'] ?? 30,
      status: statusFromString(json['status'] ?? 'draft'),
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      questionCount: json['question_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'quiz_date': '${quizDate.year}-${quizDate.month.toString().padLeft(2, '0')}-${quizDate.day.toString().padLeft(2, '0')}',
      'duration_minutes': durationMinutes,
      'status': statusToString(status),
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
