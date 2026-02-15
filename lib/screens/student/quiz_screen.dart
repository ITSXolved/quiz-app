import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../models/question.dart';
import '../../models/quiz.dart';
import '../../services/question_service.dart';
import '../../services/student_service.dart';

class QuizScreen extends StatefulWidget {
  final Student student;
  final Quiz quiz;
  const QuizScreen({super.key, required this.student, required this.quiz});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  final Map<String, String> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentQ = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final qs = await QuestionService.getQuestionsByQuizId(widget.quiz.id);
    setState(() { _questions = qs; _isLoading = false; });
  }

  Future<void> _submit() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please answer all questions'), backgroundColor: AppTheme.warning));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await StudentService.submitQuizResponses(
        studentId: widget.student.id,
        quizId: widget.quiz.id,
        questions: _questions,
        answers: _answers,
        quizDate: widget.quiz.quizDate, // Or DateTime.now() if we track completion time? Logic uses quizDate.
      );
      if (mounted) _showResult();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    } finally { if (mounted) setState(() => _isSubmitting = false); }
  }

  void _showResult() {
    int correct = 0, total = 0;
    for (final q in _questions) {
      total += q.marks;
      if (q.correctAnswer.trim().toLowerCase() == (_answers[q.id] ?? '').trim().toLowerCase()) correct += q.marks;
    }
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.emoji_events_rounded, color: AppTheme.accentGold, size: 60),
            const SizedBox(height: 20),
            const Text('Quiz Complete!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('$correct / $total', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold,
              color: correct / total >= 0.7 ? AppTheme.success : correct / total >= 0.4 ? AppTheme.warning : AppTheme.error)),
            const SizedBox(height: 4),
            const Text('marks scored', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back to Dashboard'),
            )),
          ]),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryDark, Color(0xFF0A1628)])),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.accent))));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryDark, Color(0xFF0A1628)])),
          child: Column(children: [
            _topBar(),
            const Expanded(child: Center(child: Text('No questions for today', style: TextStyle(color: AppTheme.textSecondary)))),
          ]),
        ),
      );
    }

    final q = _questions[_currentQ];
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, Color(0xFF0A1628)])),
        child: Column(children: [
          _topBar(),
          Expanded(child: Row(children: [
            // Question navigator sidebar on wide screens
            if (isWide)
              Container(
                width: 260,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  border: Border(right: BorderSide(color: AppTheme.surfaceLight.withValues(alpha: 0.3))),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 16),
                    child: Text('QUESTIONS', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                  ),
                  Expanded(child: ListView.builder(
                    itemCount: _questions.length,
                    itemBuilder: (_, i) {
                      final isActive = i == _currentQ;
                      final isAnswered = _answers.containsKey(_questions[i].id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() => _currentQ = i),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.accent.withValues(alpha: 0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  color: isAnswered ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.surfaceLight.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: isAnswered
                                  ? const Icon(Icons.check_rounded, color: AppTheme.success, size: 14)
                                  : Text('${i + 1}', style: TextStyle(color: isActive ? AppTheme.accent : AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Question ${i + 1}', style: TextStyle(
                                color: isActive ? AppTheme.accent : AppTheme.textSecondary, fontSize: 14,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                        ),
                      );
                    },
                  )),
                ]),
              ),
            // Main question area — centered
            Expanded(child: Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Row(children: [
                    Text('Question ${_currentQ + 1} of ${_questions.length}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text('${q.marks} marks', style: const TextStyle(color: AppTheme.accentGold, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ClipRRect(borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: (_currentQ + 1) / _questions.length, minHeight: 4,
                      backgroundColor: AppTheme.surfaceLight, color: AppTheme.accent)),
                ),
                // Question content
                Expanded(child: ListView(padding: const EdgeInsets.all(32), children: [
                  _TypeBadge(type: q.type),
                  const SizedBox(height: 20),
                  if (q.type != QuestionType.pickAndPlace)
                    Text(q.questionText, style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, height: 1.4
                    )),
                  const SizedBox(height: 40),
                  _buildAnswerWidget(q),
                ])),
                // Navigation
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 14, 28, 20),
                  child: Row(children: [
                    if (_currentQ > 0)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary, side: const BorderSide(color: AppTheme.textSecondary),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => setState(() => _currentQ--),
                        child: const Text('Previous'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _isSubmitting ? null : () {
                        if (_currentQ < _questions.length - 1) { setState(() => _currentQ++); } else { _submit(); }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _currentQ < _questions.length - 1 ? AppTheme.accent : AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_currentQ < _questions.length - 1 ? 'Next' : 'Submit Quiz'),
                    ),
                  ]),
                ),
              ]),
            ))),
          ])),
        ]),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A).withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: AppTheme.surfaceLight.withValues(alpha: 0.3))),
      ),
      child: Row(children: [
        IconButton(
          onPressed: () => Navigator.pop(context), 
          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
          tooltip: 'Exit Quiz',
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.quiz.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('In progress...', style: TextStyle(color: AppTheme.accentGold.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildAnswerWidget(Question q) {
    final selected = _answers[q.id];
    switch (q.type) {
      case QuestionType.mcq:
        final opts = q.options is List ? List<String>.from(q.options) : <String>[];
        return Column(children: opts.map((o) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _answers[q.id!] = o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected == o ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected == o ? AppTheme.accent : AppTheme.surfaceLight, width: selected == o ? 2 : 1)),
              child: Row(children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle,
                  color: selected == o ? AppTheme.accent : Colors.transparent,
                  border: Border.all(color: selected == o ? AppTheme.accent : AppTheme.textSecondary, width: 2)),
                  child: selected == o ? const Icon(Icons.check, color: Colors.white, size: 16) : null),
                const SizedBox(width: 14),
                Expanded(child: Text(o, style: TextStyle(color: selected == o ? AppTheme.accent : AppTheme.textPrimary, fontSize: 15))),
              ]),
            ),
          ),
        )).toList());

      case QuestionType.yesNo:
        return Row(children: ['Yes', 'No'].map((o) => Expanded(child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _answers[q.id!] = o),
            child: Container(
              margin: EdgeInsets.only(right: o == 'Yes' ? 8 : 0, left: o == 'No' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: selected == o ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected == o ? AppTheme.accent : AppTheme.surfaceLight, width: selected == o ? 2 : 1)),
              child: Center(child: Text(o, style: TextStyle(
                color: selected == o ? AppTheme.accent : AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
            ),
          ),
        ))).toList());

      case QuestionType.typeAnswer:
        return TextField(onChanged: (v) => _answers[q.id!] = v,
          maxLines: 3, decoration: const InputDecoration(hintText: 'Type your answer here...', alignLabelWithHint: true));

      case QuestionType.pickAndPlace:
        final items = List<String>.from(q.options['items'] is List ? q.options['items'] : []);
        final regex = RegExp(r'\[(.*?)\]');
        final matches = regex.allMatches(q.questionText);
        final blankCount = matches.length;

        List<String> currentAnswers;
        if (_answers.containsKey(q.id)) {
          currentAnswers = _answers[q.id]!.split('|');
          if (currentAnswers.length != blankCount) currentAnswers = List.filled(blankCount, '');
        } else {
          currentAnswers = List.filled(blankCount, '');
        }

        final pool = List<String>.from(items);
        for (final ans in currentAnswers) {
          if (ans.isNotEmpty && pool.contains(ans)) pool.remove(ans);
        }

        List<Widget> sentenceWidgets = [];
        int lastMatchEnd = 0;
        int blankIndex = 0;

        for (final match in matches) {
          if (match.start > lastMatchEnd) {
            sentenceWidgets.add(Text(q.questionText.substring(lastMatchEnd, match.start),
              style: const TextStyle(fontSize: 18, color: AppTheme.textPrimary, height: 1.8)));
          }

          final index = blankIndex;
          sentenceWidgets.add(
            DragTarget<String>(
              onAcceptWithDetails: (details) => setState(() {
                currentAnswers[index] = details.data;
                _answers[q.id!] = currentAnswers.join('|');
              }),
              builder: (context, candidateData, rejectedData) {
                final filled = currentAnswers[index];
                return GestureDetector(
                  onTap: () {
                    if (filled.isNotEmpty) setState(() {
                      currentAnswers[index] = '';
                      _answers[q.id!] = currentAnswers.join('|');
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    constraints: const BoxConstraints(minWidth: 80, minHeight: 40),
                    decoration: BoxDecoration(
                      color: filled.isNotEmpty ? AppTheme.accent : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: candidateData.isNotEmpty ? AppTheme.accentGold : AppTheme.textSecondary.withValues(alpha: 0.3)),
                    ),
                    child: Text(filled, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            )
          );
          lastMatchEnd = match.end;
          blankIndex++;
        }
        if (lastMatchEnd < q.questionText.length) {
          sentenceWidgets.add(Text(q.questionText.substring(lastMatchEnd),
            style: const TextStyle(fontSize: 18, color: AppTheme.textPrimary, height: 1.8)));
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: sentenceWidgets),
          const SizedBox(height: 40),
          const Text('Drag words to fill blanks:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: pool.map((item) {
            return Draggable<String>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)]),
                  child: Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.5, child: _buildPill(item)),
              child: _buildPill(item),
            );
          }).toList()),
        ]);
    }
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final QuestionType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = {
      QuestionType.mcq: AppTheme.accent,
      QuestionType.pickAndPlace: AppTheme.accentGold,
      QuestionType.yesNo: AppTheme.success,
      QuestionType.typeAnswer: AppTheme.warning,
    };
    final labels = {
      QuestionType.mcq: 'MCQ', QuestionType.pickAndPlace: 'Pick & Place',
      QuestionType.yesNo: 'Yes/No', QuestionType.typeAnswer: 'Type Answer',
    };
    final c = colors[type]!;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
        child: Text(labels[type]!, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}
