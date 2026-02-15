import '../config/supabase_config.dart';
import '../models/student.dart';
import '../models/question.dart';
import '../models/response.dart';

class StudentService {
  // Get all paid students
  static Future<List<Student>> getPaidStudents() async {
    final response = await SupabaseConfig.client
        .from('applications')
        .select()
        .eq('payment_status', 'completed')
        .order('name');
    return (response as List).map((e) => Student.fromJson(e)).toList();
  }

  // Get student by ID
  static Future<Student?> getStudentById(String id) async {
    final response = await SupabaseConfig.client
        .from('applications')
        .select()
        .eq('id', id)
        .maybeSingle();
    return response != null ? Student.fromJson(response) : null;
  }

  // Submit quiz responses + compute score
  static Future<void> submitQuizResponses({
    required String studentId,
    required String quizId,
    required List<Question> questions,
    required Map<String, String> answers,
    required DateTime quizDate,
  }) async {
    int totalMarks = 0;
    int obtainedMarks = 0;
    int correctCount = 0;

    final List<Map<String, dynamic>> responses = [];

    for (final q in questions) {
      final answer = answers[q.id] ?? '';
      final isCorrect = _checkAnswer(q, answer);
      final score = isCorrect ? q.marks : 0;

      totalMarks += q.marks;
      if (isCorrect) {
        obtainedMarks += score;
        correctCount++;
      }

      responses.add({
        'student_id': studentId,
        'question_id': q.id,
        'quiz_id': quizId,
        'answer': answer,
        'is_correct': isCorrect,
        'score': score,
      });
    }

    // Upsert responses
    // We should probably rely on ID if possible, but upsert works.
    // Ensure uniqueness on (student_id, question_id) might not be enough if same question reused?
    // But questions are linked to quiz.
    await SupabaseConfig.client
        .from('student_responses')
        .upsert(responses, onConflict: 'student_id,question_id');

    // Upsert quiz score
    final dateStr = '${quizDate.year}-${quizDate.month.toString().padLeft(2, '0')}-${quizDate.day.toString().padLeft(2, '0')}';
    await SupabaseConfig.client.from('student_scores').upsert({
      'student_id': studentId,
      'quiz_id': quizId,
      'quiz_date': dateStr,
      'total_marks': totalMarks,
      'obtained_marks': obtainedMarks,
      'total_questions': questions.length,
      'correct_answers': correctCount,
    }, onConflict: 'student_id,quiz_id');
  }

  static bool _checkAnswer(Question q, String answer) {
    if (answer.isEmpty) return false;
    final correct = q.correctAnswer.trim().toLowerCase();
    final given = answer.trim().toLowerCase();

    switch (q.type) {
      case QuestionType.mcq:
      case QuestionType.yesNo:
      case QuestionType.typeAnswer:
        return correct == given;
      case QuestionType.pickAndPlace:
        return correct == given;
    }
  }

  // Get student's scores
  static Future<List<StudentScore>> getStudentScores(String studentId) async {
    final response = await SupabaseConfig.client
        .from('student_scores')
        .select('*, quizzes(title)')
        .eq('student_id', studentId)
        .order('quiz_date', ascending: false);
    return (response as List).map((e) => StudentScore.fromJson(e)).toList();
  }

  // Get student's responses for a quiz
  static Future<List<StudentResponse>> getStudentResponses(String studentId, String quizId) async {
    final response = await SupabaseConfig.client
        .from('student_responses')
        .select()
        .eq('student_id', studentId)
        .eq('quiz_id', quizId);
    return (response as List).map((e) => StudentResponse.fromJson(e)).toList();
  }

  // Check if student has already completed a quiz
  static Future<bool> hasCompletedQuiz(String studentId, String quizId) async {
    final response = await SupabaseConfig.client
        .from('student_scores')
        .select('id')
        .eq('student_id', studentId)
        .eq('quiz_id', quizId)
        .maybeSingle();
    return response != null;
  }

  // Get all scores for admin view
  static Future<List<Map<String, dynamic>>> getAllScoresWithStudents() async {
    final response = await SupabaseConfig.client
        .from('student_scores')
        .select('*, applications(name, mobile)')
        .order('quiz_date', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
  // Delete student's result for a specific quiz (Reset attempt)
  static Future<void> deleteStudentResult(String studentId, String quizId) async {
    await SupabaseConfig.client
        .from('student_responses')
        .delete()
        .eq('student_id', studentId)
        .eq('quiz_id', quizId);

    await SupabaseConfig.client
        .from('student_scores')
        .delete()
        .eq('student_id', studentId)
        .eq('quiz_id', quizId);
  }
}
