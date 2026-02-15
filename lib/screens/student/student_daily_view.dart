import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/daily_topic.dart';
import '../../models/daily_note_section.dart';
import '../../services/daily_note_service.dart';
import '../../models/quiz.dart';
import '../../models/student.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

class StudentDailyView extends StatefulWidget {
  final Student student;
  final List<Quiz> allQuizzes;
  final Function(Quiz) onStartQuiz;

  const StudentDailyView({
    super.key, 
    required this.student, 
    required this.allQuizzes,
    required this.onStartQuiz,
  });

  @override
  State<StudentDailyView> createState() => _StudentDailyViewState();
}

class _StudentDailyViewState extends State<StudentDailyView> {
  DateTime _selectedDate = DateTime.now();
  List<DailyTopic> _topics = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTopics(_selectedDate);
  }

  Future<void> _fetchTopics(DateTime date) async {
    setState(() => _isLoading = true);
    final allTopics = await DailyNoteService.getTopicsForDate(date);
    _topics = allTopics.where((t) => t.isActive).toList();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Filter quizzes for this date
    final quizzesForDate = widget.allQuizzes.where((q) {
      return q.quizDate.year == _selectedDate.year &&
             q.quizDate.month == _selectedDate.month &&
             q.quizDate.day == _selectedDate.day;
    }).toList();

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Text('Daily Study', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceLight),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accentGold, onPrimary: AppTheme.primaryDark, surface: AppTheme.cardBg, onSurface: AppTheme.textPrimary)), child: child!),
                      );
                      if (picked != null && picked != _selectedDate) {
                        setState(() => _selectedDate = picked);
                        _fetchTopics(picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           const Icon(Icons.calendar_month, color: AppTheme.accentGold, size: 18),
                           const SizedBox(width: 8),
                           Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                           const SizedBox(width: 4),
                           const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Topics Section
        if (_topics.isNotEmpty) ...[
          const SliverToBoxAdapter(
             child: Padding(
               padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
               child: Text('Classes & Topics', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
             ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0, // Square
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final topic = _topics[index];
                  return Card(
                    color: AppTheme.cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.surfaceLight)),
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TopicViewerScreen(topic: topic))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.school_rounded, color: AppTheme.accentGold, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              topic.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: _topics.length,
              ),
            ),
          ),
        ] else if (!_isLoading) 
           SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppTheme.cardBg.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.5), style: BorderStyle.none)),
              child: const Column(children: [
                   Icon(Icons.topic_outlined, color: AppTheme.textSecondary, size: 40),
                   SizedBox(height: 12),
                   Text('No topics scheduled for this day.', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),

        // Quizzes Section
        const SliverToBoxAdapter(
           child: Padding(
             padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
             child: Text('Quizzes for this day', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
           ),
        ),
        if (quizzesForDate.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0, // Square
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final q = quizzesForDate[index];
                  return Card(
                    color: AppTheme.cardBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.surfaceLight)),
                    margin: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => widget.onStartQuiz(q),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.quiz_rounded, color: AppTheme.accentGold, size: 32),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              q.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('${q.durationMinutes} mins', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: quizzesForDate.length,
              ),
            ),
          )
        else
          SliverToBoxAdapter(
             child: Container(
               margin: const EdgeInsets.symmetric(horizontal: 20),
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(color: AppTheme.cardBg.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12)),
               child: const Center(child: Text('No quizzes via this view.', style: TextStyle(color: AppTheme.textSecondary))),
             ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }
}

class TopicViewerScreen extends StatefulWidget {
  final DailyTopic topic;
  const TopicViewerScreen({super.key, required this.topic});

  @override
  State<TopicViewerScreen> createState() => _TopicViewerScreenState();
}

class _TopicViewerScreenState extends State<TopicViewerScreen> {
  List<DailyNoteSection> _sections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  List<dynamic> _ensureValidQuillDelta(List<dynamic>? json) {
    if (json == null || json.isEmpty) return [{'insert': '\n'}];
    final safeJson = List<dynamic>.from(json);
    final last = safeJson.last;
    if (last is Map && last['insert'] is String) {
      if (!(last['insert'] as String).endsWith('\n')) {
        safeJson.add({'insert': '\n'});
      }
    } else {
      safeJson.add({'insert': '\n'});
    }
    return safeJson;
  }

  Future<void> _fetchSections() async {
    setState(() => _isLoading = true);
    _sections = await DailyNoteService.getSectionsForTopic(widget.topic.id);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        title: Text(widget.topic.title, style: const TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold)) :
        ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (ctx, i) {
            final section = _sections[i];
            
            // Try to parse json content
            quill.QuillController qController;
             try {
               qController = quill.QuillController(
                  document: quill.Document.fromJson(_ensureValidQuillDelta(section.contentJson)),
                  selection: const TextSelection.collapsed(offset: 0),
                  readOnly: true,
               );
            } catch (e) {
               qController = quill.QuillController.basic();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 24), // margin instead of separator if needed, but ListView.separated handles it
              decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surfaceLight)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  title: Text(
                    section.heading,
                    style: const TextStyle(color: AppTheme.accentGold, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  iconColor: AppTheme.accentGold,
                  collapsedIconColor: AppTheme.textSecondary,
                  children: [
                    quill.QuillEditor.basic(
                      controller: qController,
                      config: const quill.QuillEditorConfig(
                        placeholder: '',
                        scrollable: false,
                        autoFocus: false,
                        expands: false,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }
}
