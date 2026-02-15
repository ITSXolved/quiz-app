enum QuestionType { mcq, pickAndPlace, yesNo, typeAnswer }

class Question {
  final String? id;
  final QuestionType type;
  final String questionText;
  final dynamic options; // JSON: list for MCQ, map for pick_and_place
  final String correctAnswer;
  final int marks;
  final DateTime quizDate;
  final String? createdBy;
  final DateTime? createdAt;

  final String? quizId;

  Question({
    this.id,
    required this.type,
    required this.questionText,
    this.options,
    required this.correctAnswer,
    this.marks = 1,
    required this.quizDate,
    this.createdBy,
    this.createdAt,
    this.quizId,
  });

  static QuestionType typeFromString(String s) {
    switch (s) {
      case 'mcq':
        return QuestionType.mcq;
      case 'pick_and_place':
        return QuestionType.pickAndPlace;
      case 'yes_no':
        return QuestionType.yesNo;
      case 'type_answer':
        return QuestionType.typeAnswer;
      default:
        return QuestionType.mcq;
    }
  }

  static String typeToString(QuestionType t) {
    switch (t) {
      case QuestionType.mcq:
        return 'mcq';
      case QuestionType.pickAndPlace:
        return 'pick_and_place';
      case QuestionType.yesNo:
        return 'yes_no';
      case QuestionType.typeAnswer:
        return 'type_answer';
    }
  }

  String get typeLabel {
    switch (type) {
      case QuestionType.mcq:
        return 'MCQ';
      case QuestionType.pickAndPlace:
        return 'Pick & Place';
      case QuestionType.yesNo:
        return 'Yes / No';
      case QuestionType.typeAnswer:
        return 'Type Answer';
    }
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      type: typeFromString(json['question_type']),
      questionText: json['question_text'],
      options: json['options'],
      correctAnswer: json['correct_answer'],
      marks: json['marks'] ?? 1,
      quizDate: DateTime.parse(json['quiz_date']),
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      quizId: json['quiz_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_type': typeToString(type),
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'marks': marks,
      'quiz_date': '${quizDate.year}-${quizDate.month.toString().padLeft(2, '0')}-${quizDate.day.toString().padLeft(2, '0')}',
      if (createdBy != null) 'created_by': createdBy,
      if (quizId != null) 'quiz_id': quizId,
    };
  }
}
