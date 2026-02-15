import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/quiz.dart';
import '../../services/question_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final String adminId;
  const CreateQuizScreen({super.key, required this.adminId});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  DateTime _selectedDate = DateTime.now();
  QuizStatus _status = QuizStatus.draft;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.accent, surface: AppTheme.cardBg),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) { _showError('Please enter a quiz title'); return; }
    
    setState(() => _isSaving = true);
    try {
      final quiz = Quiz(
        id: '', // Supabase generates ID usually, but if using custom ID we need one. 
                // Wait, QuestionService.createQuiz uses insert(quiz.toJson()). 
                // toJson doesn't include ID usually for inserts if DB auto-gens.
                // My Quiz model has 'required this.id'.
                // I should make ID optional in model or handle it.
                // Let's assume DB generates it. I'll pass empty string or handle toJson to exclude ID.
                // Actually my Quiz.toJson DOES NOT include ID. So it's fine.
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        quizDate: _selectedDate,
        durationMinutes: int.tryParse(_durationCtrl.text) ?? 30,
        status: _status,
        createdBy: widget.adminId,
      );

      await QuestionService.createQuiz(quiz);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz created successfully'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      _showError('Failed to create quiz: $e');
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
                const Text('Create New Quiz', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
              ]),
            ),

            // Form content
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      // Title
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quiz Title',
                          hintText: 'e.g., Weekly Quran Quiz - Juz 1',
                          prefixIcon: Icon(Icons.title_rounded, color: AppTheme.accent),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      TextField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 48),
                            child: Icon(Icons.description_outlined, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Date & Duration
                      Row(children: [
                        Expanded(child: _datePickerCard()),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (mins)',
                              prefixIcon: Icon(Icons.timer_outlined, color: AppTheme.accentGold),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),

                      // Status Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceLight),
                        ),
                        child: Row(children: [
                          const Icon(Icons.published_with_changes_rounded, color: AppTheme.textSecondary),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Quiz Status', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(_status == QuizStatus.published ? 'Visible to students' : 'Hidden (Draft)',
                              style: TextStyle(color: _status == QuizStatus.published ? AppTheme.success : AppTheme.textSecondary, fontSize: 12)),
                          ]),
                          const Spacer(),
                          Switch(
                            value: _status == QuizStatus.published,
                            activeTrackColor: AppTheme.success,
                            activeColor: Colors.white,
                            onChanged: (v) => setState(() => _status = v ? QuizStatus.published : QuizStatus.draft),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Create Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

  Widget _datePickerCard() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Schedule Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.calendar_today_rounded, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    );
  }
}
