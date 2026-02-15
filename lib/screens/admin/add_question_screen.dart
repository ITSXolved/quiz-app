import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/question.dart';
import '../../services/question_service.dart';

class AddQuestionScreen extends StatefulWidget {
  final String adminId;
  final String quizId;
  final DateTime quizDate;

  const AddQuestionScreen({
    super.key,
    required this.adminId,
    required this.quizId,
    required this.quizDate,
  });

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  QuestionType _selectedType = QuestionType.mcq;
  final _questionTextCtrl = TextEditingController();
  final _correctAnswerCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '1');
  bool _isSaving = false;

  final List<TextEditingController> _optionControllers = [
    TextEditingController(), TextEditingController(),
    TextEditingController(), TextEditingController(),
  ];
  final _itemsCtrl = TextEditingController();

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    _correctAnswerCtrl.dispose();
    _marksCtrl.dispose();
    _itemsCtrl.dispose();
    for (final c in _optionControllers) { c.dispose(); }
    super.dispose();
  }

  // Date picker removed as date is fixed to quiz date

  Future<void> _save() async {
    if (_questionTextCtrl.text.trim().isEmpty) { _showError('Please enter a question'); return; }
    if (_correctAnswerCtrl.text.trim().isEmpty && _selectedType != QuestionType.pickAndPlace) { _showError('Please enter the correct answer'); return; }

    setState(() => _isSaving = true);
    try {
      dynamic options;
      if (_selectedType == QuestionType.mcq) {
        options = _optionControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
        if ((options as List).length < 2) { _showError('Please enter at least 2 options'); setState(() => _isSaving = false); return; }
      } else if (_selectedType == QuestionType.pickAndPlace) {
        // Parse [ ] for answers
        final regex = RegExp(r'\[(.*?)\]');
        final matches = regex.allMatches(_questionTextCtrl.text);
        final correctAnswers = matches.map((m) => m.group(1)!.trim()).toList();

        if (correctAnswers.isEmpty) {
          _showError('Use [ ] to define blanks in the question text.');
          setState(() => _isSaving = false);
          return;
        }

        final distractors = _itemsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final allItems = [...correctAnswers, ...distractors];
        allItems.shuffle();

        options = {'items': allItems};
        // Auto-set correct answer
        _correctAnswerCtrl.text = correctAnswers.join('|');
      } else if (_selectedType == QuestionType.yesNo) {
        options = ['Yes', 'No'];
      }

      final question = Question(
        type: _selectedType,
        questionText: _questionTextCtrl.text.trim(),
        options: options,
        correctAnswer: _correctAnswerCtrl.text.trim(),
        marks: int.tryParse(_marksCtrl.text) ?? 1,
        quizDate: widget.quizDate,
        createdBy: widget.adminId,
        quizId: widget.quizId,
      );

      await QuestionService.addQuestion(question);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question added successfully'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to save. Try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.error));
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
            // Top bar
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A).withValues(alpha: 0.5),
                border: Border(bottom: BorderSide(color: AppTheme.surfaceLight.withValues(alpha: 0.3))),
              ),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                ),
                const SizedBox(width: 8),
                const Text('Add New Question', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
              ]),
            ),

            // Form content — centered
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      // Marks input only (Date is fixed)
                      LayoutBuilder(builder: (context, constraints) {
                        return Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.surfaceLight),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_rounded, color: AppTheme.textSecondary, size: 16),
                              const SizedBox(width: 8),
                              Text('${widget.quizDate.day}/${widget.quizDate.month}/${widget.quizDate.year}', 
                                style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: _marksCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Marks',
                                prefixIcon: Icon(Icons.star_rounded, color: AppTheme.accentGold),
                              ),
                            ),
                          ),
                        ]);
                      }),
                      const SizedBox(height: 24),

                      // Question type selector
                      const Text('Question Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: QuestionType.values.map((t) {
                        final isSelected = t == _selectedType;
                        final label = Question(type: t, questionText: '', correctAnswer: '', quizDate: DateTime.now()).typeLabel;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedType = t),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accent : AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.surfaceLight),
                              ),
                              child: Text(label, style: TextStyle(
                                color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                            ),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 24),

                      // Question text
                      TextField(
                        controller: _questionTextCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 48),
                            child: Icon(Icons.help_outline_rounded, color: AppTheme.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type-specific fields
                      if (_selectedType == QuestionType.mcq) ...[
                        const Text('Options', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        ...List.generate(4, (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: _optionControllers[i],
                            decoration: InputDecoration(
                              labelText: 'Option ${String.fromCharCode(65 + i)}',
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(10), width: 28, height: 28,
                                decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                child: Center(child: Text(String.fromCharCode(65 + i), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ),
                        )),
                      ],

                      if (_selectedType == QuestionType.pickAndPlace) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Instructions: Use brackets [ ] for blanks.\nExample: Roses are [red] and Violets are [blue].',
                            style: TextStyle(color: AppTheme.accentGold, fontSize: 13, height: 1.4)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _itemsCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Distractors (Wrong options, comma separated)',
                            hintText: 'green, yellow, black',
                            prefixIcon: Icon(Icons.shuffle_rounded, color: AppTheme.accent),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      if (_selectedType == QuestionType.yesNo) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(12)),
                          child: const Row(children: [
                            Icon(Icons.info_outline, color: AppTheme.textSecondary, size: 18),
                            SizedBox(width: 10),
                            Text('Options: Yes / No', style: TextStyle(color: AppTheme.textSecondary)),
                          ]),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Correct answer (Hidden for Pick & Place as it is auto-derived)
                      if (_selectedType != QuestionType.pickAndPlace) ...[
                        const SizedBox(height: 6),
                        TextField(
                          controller: _correctAnswerCtrl,
                          decoration: InputDecoration(
                            labelText: 'Correct Answer',
                            hintText: _selectedType == QuestionType.yesNo ? 'Yes or No'
                              : _selectedType == QuestionType.mcq ? 'Enter correct option text' : 'Enter correct answer',
                            prefixIcon: const Icon(Icons.check_circle_outline, color: AppTheme.success),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Save button
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Save Question', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



}
