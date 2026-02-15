import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';
import '../../models/response.dart';

class StudentListScreen extends StatefulWidget {
  final List<Student> students;
  const StudentListScreen({super.key, required this.students});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _search = '';

  List<Student> get _filtered {
    if (_search.isEmpty) return widget.students;
    final q = _search.toLowerCase();
    return widget.students.where((s) => s.name.toLowerCase().contains(q) || s.mobile.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: AppTheme.accent, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Search students...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('${_filtered.length} Students', style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Data table
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF0D1B2A)),
                dataRowColor: WidgetStateProperty.all(AppTheme.cardBg),
                headingTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                dataTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                columnSpacing: 28,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('NAME')),
                  DataColumn(label: Text('PHONE')),
                  DataColumn(label: Text('EMAIL')),
                  DataColumn(label: Text('PAYMENT')),
                  DataColumn(label: Text('PROGRESS')),
                ],
                rows: List.generate(_filtered.length, (i) {
                  final s = _filtered[i];
                  return DataRow(cells: [
                    DataCell(Text('${i + 1}', style: const TextStyle(color: AppTheme.textSecondary))),
                    DataCell(
                      Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text(s.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 14))),
                        ),
                        const SizedBox(width: 10),
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    DataCell(Text(s.mobile)),
                    DataCell(Text(s.email ?? '—', style: TextStyle(color: s.email != null ? AppTheme.textPrimary : AppTheme.textSecondary))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Text('PAID', style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    )),
                    DataCell(IconButton(
                      onPressed: () => _showProgress(s),
                      icon: const Icon(Icons.bar_chart_rounded, color: AppTheme.accent, size: 20),
                      tooltip: 'View Progress',
                    )),
                  ]);
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showProgress(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(student.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(student.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                      Text(student.mobile, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    ]),
                  ),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary)),
                ]),
              ),
              // Scores
              Expanded(
                child: FutureBuilder<List<StudentScore>>(
                  future: StudentService.getStudentScores(student.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
                    }
                    final scores = snapshot.data ?? [];
                    if (scores.isEmpty) {
                      return const Center(child: Text('No quiz scores yet', style: TextStyle(color: AppTheme.textSecondary)));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: scores.length,
                      separatorBuilder: (_, __) => Divider(color: AppTheme.surfaceLight.withValues(alpha: 0.3), height: 1),
                      itemBuilder: (_, i) {
                        final s = scores[i];
                        final pct = s.percentage;
                        final color = pct >= 70 ? AppTheme.success : pct >= 40 ? AppTheme.warning : AppTheme.error;
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
                          ),
                          title: Text('${s.quizDate.day}/${s.quizDate.month}/${s.quizDate.year}', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                          subtitle: Text('${s.correctAnswers}/${s.totalQuestions} correct', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${s.obtainedMarks}/${s.totalMarks}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              if (s.quizId != null)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textSecondary, size: 18),
                                  tooltip: 'Reset Attempt',
                                  onPressed: () => _confirmDeleteResult(s),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _confirmDeleteResult(StudentScore score) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Reset Attempt?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will delete the student\'s answers and score for this quiz. They will be able to take it again.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              if (score.quizId == null) return;
              await StudentService.deleteStudentResult(score.studentId, score.quizId!);
              if (mounted) {
                setState(() {}); // Refresh list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attempt reset successfully'), backgroundColor: AppTheme.success),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
