import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/quiz.dart';
import '../../models/question.dart';
import '../../services/question_service.dart';
import 'add_question_screen.dart';

class QuizQuestionsScreen extends StatefulWidget {
  final String adminId;
  final Quiz quiz;

  const QuizQuestionsScreen({super.key, required this.adminId, required this.quiz});

  @override
  State<QuizQuestionsScreen> createState() => _QuizQuestionsScreenState();
}

class _QuizQuestionsScreenState extends State<QuizQuestionsScreen> {
  late Quiz _quiz;
  List<Question> _questions = [];
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _quiz = widget.quiz;
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final qs = await QuestionService.getQuestionsByQuizId(_quiz.id);
      setState(() => _questions = qs);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus() async {
    setState(() => _isUpdating = true);
    try {
      final newStatus = _quiz.status == QuizStatus.published ? QuizStatus.draft : QuizStatus.published;
      final updatedQuiz = Quiz(
        id: _quiz.id,
        title: _quiz.title,
        description: _quiz.description,
        quizDate: _quiz.quizDate,
        durationMinutes: _quiz.durationMinutes,
        status: newStatus,
        createdBy: _quiz.createdBy,
        questionCount: _questions.length, // Update count while we are at it
      );
      
      await QuestionService.updateQuiz(_quiz.id, updatedQuiz);
      
      setState(() {
        _quiz = updatedQuiz;
        _isUpdating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quiz ${newStatus == QuizStatus.published ? "Published" : "Unpublished"}'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _deleteQuestion(String id) async {
    try {
      await QuestionService.deleteQuestion(id);
      _loadQuestions();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question deleted'), backgroundColor: AppTheme.success));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _deleteQuiz() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Quiz?', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Delete "${_quiz.title}" and all its questions? This cannot be undone.', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await QuestionService.deleteQuiz(_quiz.id);
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh dashboard
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz deleted'), backgroundColor: AppTheme.success));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryDark, Color(0xFF0A1628)]),
        ),
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A).withValues(alpha: 0.5),
                border: Border(bottom: BorderSide(color: AppTheme.surfaceLight.withValues(alpha: 0.3))),
              ),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context, true), // Return true to refresh
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_quiz.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('${_quiz.questionCount} Questions • ${_quiz.durationMinutes} mins', 
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ]),
                const Spacer(),
                // Status Toggle
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: Row(children: [
                    Text(_quiz.status == QuizStatus.published ? 'Published' : 'Draft', 
                      style: TextStyle(color: _quiz.status == QuizStatus.published ? AppTheme.success : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24, width: 36,
                      child: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _quiz.status == QuizStatus.published,
                          activeTrackColor: AppTheme.success,
                          activeColor: Colors.white,
                          onChanged: _isUpdating ? null : (v) => _toggleStatus(),
                        ),
                      ),
                    ),
                  ]),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddQuestionScreen(
                        adminId: widget.adminId, 
                        quizId: _quiz.id,
                        quizDate: _quiz.quizDate, // Use quiz date
                      )),
                    );
                    _loadQuestions();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Question'),
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _deleteQuiz,
                  tooltip: 'Delete Quiz',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ),

            // Questions List
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _questions.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.quiz_outlined, size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No questions yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: () async {
                         await Navigator.push(context, MaterialPageRoute(builder: (_) => AddQuestionScreen(
                           adminId: widget.adminId, quizId: widget.quiz.id, quizDate: widget.quiz.quizDate)));
                         _loadQuestions();
                      }, child: const Text('Add your first question', style: TextStyle(color: AppTheme.accent))),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.surfaceLight),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)),
                              child: Text('Q${index + 1}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (q.type == QuestionType.mcq ? AppTheme.accent : AppTheme.accentGold).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(q.typeLabel, style: TextStyle(
                                    color: q.type == QuestionType.mcq ? AppTheme.accent : AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                Text('${q.marks} marks', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ]),
                              const SizedBox(height: 8),
                              Text(q.questionText, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Text('Answer: ${q.correctAnswer}', style: const TextStyle(color: AppTheme.success, fontSize: 13)),
                            ])),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                              onPressed: () => _deleteQuestion(q.id!),
                            ),
                          ]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
