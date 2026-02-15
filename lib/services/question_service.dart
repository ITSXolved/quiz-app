import '../config/supabase_config.dart';
import '../models/question.dart';
import '../models/quiz.dart';

class QuestionService {
  // --- Quiz Methods ---

  static Future<void> createQuiz(Quiz quiz) async {
    await SupabaseConfig.client.from('quizzes').insert(quiz.toJson());
  }

  static Future<void> updateQuiz(String id, Quiz quiz) async {
    await SupabaseConfig.client.from('quizzes').update(quiz.toJson()).eq('id', id);
  }

  static Future<void> deleteQuiz(String id) async {
    // Explicitly delete related data
    await SupabaseConfig.client.from('student_responses').delete().eq('quiz_id', id);
    await SupabaseConfig.client.from('student_scores').delete().eq('quiz_id', id);
    await SupabaseConfig.client.from('quiz_questions').delete().eq('quiz_id', id);
    await SupabaseConfig.client.from('quizzes').delete().eq('id', id);
  }

  static Future<List<Quiz>> getAllQuizzes() async {
    final response = await SupabaseConfig.client
        .from('quizzes')
        .select('*, question_count:quiz_questions(count)')
        .order('quiz_date', ascending: false)
        .order('created_at', ascending: false);
        
    return (response as List).map((e) {
      // Supabase returns count as [{count: N}] for foreign key relation join sometimes?
      // Or simply integer if using count aggregate properly.
      // Usually select('*, quiz_questions(count)') returns {..., quiz_questions: [{count: 3}]}
      final data = Map<String, dynamic>.from(e);
      if (data['question_count'] is List && (data['question_count'] as List).isNotEmpty) {
        data['question_count'] = (data['question_count'] as List)[0]['count'];
      } else {
        data['question_count'] = 0;
      }
      return Quiz.fromJson(data);
    }).toList();
  }

  static Future<List<Quiz>> getPublishedQuizzes() async {
    final response = await SupabaseConfig.client
        .from('quizzes')
        .select('*, question_count:quiz_questions(count)')
        .eq('status', 'published')
        .order('quiz_date', ascending: false);

    return (response as List).map((e) {
      final data = Map<String, dynamic>.from(e);
      if (data['question_count'] is List && (data['question_count'] as List).isNotEmpty) {
        data['question_count'] = (data['question_count'] as List)[0]['count'];
      } else {
        data['question_count'] = 0;
      }
      return Quiz.fromJson(data);
    }).toList();
  }

  static Future<List<Question>> getQuestionsByQuizId(String quizId) async {
    final response = await SupabaseConfig.client
        .from('quiz_questions')
        .select()
        .eq('quiz_id', quizId)
        .order('created_at');
    return (response as List).map((e) => Question.fromJson(e)).toList();
  }

  // --- Legacy Methods (kept for compatibility during migration) ---

  static Future<List<Question>> getQuestionsByDate(DateTime date) async {
    // ... (existing implementation)
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await SupabaseConfig.client
        .from('quiz_questions')
        .select()
        .eq('quiz_date', dateStr)
        .order('created_at');
    return (response as List).map((e) => Question.fromJson(e)).toList();
  }


  static Future<List<Question>> getAllQuestions() async {
    final response = await SupabaseConfig.client
        .from('quiz_questions')
        .select()
        .order('quiz_date', ascending: false)
        .order('created_at');
    return (response as List).map((e) => Question.fromJson(e)).toList();
  }

  static Future<void> addQuestion(Question question) async {
    await SupabaseConfig.client.from('quiz_questions').insert(question.toJson());
  }

  static Future<void> updateQuestion(String id, Question question) async {
    await SupabaseConfig.client.from('quiz_questions').update(question.toJson()).eq('id', id);
  }

  static Future<void> deleteQuestion(String id) async {
    await SupabaseConfig.client.from('quiz_questions').delete().eq('id', id);
  }

  static Future<List<DateTime>> getAvailableDates() async {
    final response = await SupabaseConfig.client
        .from('quiz_questions')
        .select('quiz_date')
        .order('quiz_date', ascending: false);
    final dates = <DateTime>{};
    for (final r in response) {
      dates.add(DateTime.parse(r['quiz_date']));
    }
    return dates.toList();
  }

  static Future<Map<String, int>> getQuestionCountByDate() async {
    final response = await SupabaseConfig.client
        .from('quiz_questions')
        .select('quiz_date, marks');
    final Map<String, int> counts = {};
    for (final r in response) {
      final date = r['quiz_date'] as String;
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }
}
