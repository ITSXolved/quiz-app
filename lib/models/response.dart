class StudentResponse {
  final String? id;
  final String studentId;
  final String questionId;
  final String? quizId;
  final String? answer;
  final bool isCorrect;
  final int score;
  final DateTime? answeredAt;

  StudentResponse({
    this.id,
    required this.studentId,
    required this.questionId,
    this.quizId,
    this.answer,
    this.isCorrect = false,
    this.score = 0,
    this.answeredAt,
  });

  factory StudentResponse.fromJson(Map<String, dynamic> json) {
    return StudentResponse(
      id: json['id'],
      studentId: json['student_id'],
      questionId: json['question_id'],
      quizId: json['quiz_id'],
      answer: json['answer'],
      isCorrect: json['is_correct'] ?? false,
      score: json['score'] ?? 0,
      answeredAt: json['answered_at'] != null ? DateTime.parse(json['answered_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'question_id': questionId,
      if (quizId != null) 'quiz_id': quizId,
      'answer': answer,
      'is_correct': isCorrect,
      'score': score,
    };
  }
}

class StudentScore {
  final String? id;
  final String? quizId;
  final String? quizTitle;
  final String studentId;
  final DateTime quizDate;
  final int totalMarks;
  final int obtainedMarks;
  final int totalQuestions;
  final int correctAnswers;

  StudentScore({
    this.id,
    this.quizId,
    this.quizTitle,
    required this.studentId,
    required this.quizDate,
    this.totalMarks = 0,
    this.obtainedMarks = 0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
  });

  double get percentage => totalMarks > 0 ? (obtainedMarks / totalMarks) * 100 : 0;

  factory StudentScore.fromJson(Map<String, dynamic> json) {
    return StudentScore(
      id: json['id'],
      quizId: json['quiz_id'],
      quizTitle: json['quizzes'] != null ? json['quizzes']['title'] : null,
      studentId: json['student_id'],
      quizDate: DateTime.parse(json['quiz_date']),
      totalMarks: json['total_marks'] ?? 0,
      obtainedMarks: json['obtained_marks'] ?? 0,
      totalQuestions: json['total_questions'] ?? 0,
      correctAnswers: json['correct_answers'] ?? 0,
    );
  }
}
