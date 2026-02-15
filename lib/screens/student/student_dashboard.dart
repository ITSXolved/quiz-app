import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../models/response.dart';
import '../../models/quiz.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';
import '../../services/question_service.dart';
import '../login_screen.dart';
import 'quiz_screen.dart';

class StudentDashboard extends StatefulWidget {
  final Student student;
  const StudentDashboard({super.key, required this.student});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;
  List<StudentScore> _scores = [];
  List<Quiz> _availableQuizzes = [];
  Set<String> _completedQuizIds = {};
  bool _isLoading = true;
  bool _sidebarCollapsed = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final scores = await StudentService.getStudentScores(widget.student.id);
      final quizzes = await QuestionService.getPublishedQuizzes();
      
      final completed = scores.map((s) => s.quizId).whereType<String>().toSet();

      setState(() {
        _scores = scores;
        _availableQuizzes = quizzes;
        _completedQuizIds = completed;
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  static const _navItems = [
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.score_rounded, 'Scores'),
    _NavItem(Icons.analytics_rounded, 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryDark, Color(0xFF0A1628)]),
        ),
        child: Row(children: [
          if (!isNarrow) _buildSidebar(isWide),
          Expanded(child: Column(children: [
            _buildTopBar(isNarrow),
            Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : IndexedStack(index: _currentIndex, children: [_buildHome(), _buildScores(), _buildAnalytics()])),
          ])),
        ]),
      ),
      drawer: isNarrow ? _buildDrawer() : null,
    );
  }

  Widget _buildSidebar(bool isWide) {
    final collapsed = !isWide || _sidebarCollapsed;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: collapsed ? 72 : 240,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        border: Border(right: BorderSide(color: AppTheme.surfaceLight.withValues(alpha: 0.5))),
      ),
      child: Column(children: [
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 14 : 20),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              const Expanded(child: Text('Noor-e-Quran', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 16))),
            ],
          ]),
        ),
        Divider(color: AppTheme.surfaceLight.withValues(alpha: 0.3), height: 1),
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('MENU', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          ),
        const SizedBox(height: 4),
        ...List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final isActive = _currentIndex == i;
          return Tooltip(
            message: collapsed ? item.label : '',
            child: InkWell(
              onTap: () => setState(() => _currentIndex = i),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: collapsed ? 10 : 12, vertical: 2),
                padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.accent.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive ? Border.all(color: AppTheme.accent.withValues(alpha: 0.2)) : null,
                ),
                child: Row(
                  mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: isActive ? AppTheme.accent : AppTheme.textSecondary, size: 22),
                    if (!collapsed) ...[
                      const SizedBox(width: 12),
                      Text(item.label, style: TextStyle(color: isActive ? AppTheme.accent : AppTheme.textSecondary,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal, fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        if (isWide)
          IconButton(
            onPressed: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            icon: Icon(_sidebarCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: AppTheme.textSecondary),
          ),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0D1B2A),
      child: SafeArea(child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Noor-e-Quran', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
          ]),
        ),
        Divider(color: AppTheme.surfaceLight.withValues(alpha: 0.3), height: 1),
        const SizedBox(height: 8),
        ...List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final isActive = _currentIndex == i;
          return ListTile(
            leading: Icon(item.icon, color: isActive ? AppTheme.accent : AppTheme.textSecondary),
            title: Text(item.label, style: TextStyle(color: isActive ? AppTheme.accent : AppTheme.textPrimary)),
            selected: isActive, selectedTileColor: AppTheme.accent.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () { setState(() => _currentIndex = i); Navigator.pop(context); },
          );
        }),
      ])),
    );
  }

  Widget _buildTopBar(bool isNarrow) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A).withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: AppTheme.surfaceLight.withValues(alpha: 0.3))),
      ),
      child: Row(children: [
        if (isNarrow) IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary)),
        Text(_navItems[_currentIndex].label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.surfaceLight.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text(widget.student.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13))),
            ),
            const SizedBox(width: 8),
            Text(widget.student.name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            await AuthService.logout();
            if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          tooltip: 'Logout',
          icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary, size: 20),
        ),
      ]),
    );
  }

  Widget _buildHome() {
    final avg = _scores.isEmpty ? 0.0 : _scores.fold<double>(0, (s, e) => s + e.percentage) / _scores.length;
    
    // Sort quizzes: Incomplete first, then by date descending
    final sortedQuizzes = List<Quiz>.from(_availableQuizzes);
    sortedQuizzes.sort((a, b) {
      final aComp = _completedQuizIds.contains(a.id);
      final bComp = _completedQuizIds.contains(b.id);
      if (aComp != bComp) return aComp ? 1 : -1; // Incomplete first
      return b.quizDate.compareTo(a.quizDate); // Newest first
    });

    return RefreshIndicator(onRefresh: _loadData, color: AppTheme.accent, child: ListView(padding: const EdgeInsets.all(28), children: [
      // Quizzes List
      Row(children: [
        const Icon(Icons.quiz_rounded, color: AppTheme.accent, size: 24),
        const SizedBox(width: 10),
        Text('Available Quizzes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 16),
      if (sortedQuizzes.isEmpty)
        _buildEmptyState('No quizzes available', 'Check back later for new quizzes.')
      else
        ...sortedQuizzes.map((q) => _buildQuizCard(q)),

      const SizedBox(height: 32),
      
      // Stats row
      LayoutBuilder(builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossCount, mainAxisSpacing: 16, crossAxisSpacing: 16, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), childAspectRatio: 2.8,
          children: [
            _stat(Icons.assignment_turned_in_rounded, 'Quizzes Taken', '${_scores.length}', AppTheme.accent),
            _stat(Icons.percent_rounded, 'Avg Score', '${avg.toStringAsFixed(0)}%', AppTheme.accentGold),
            _stat(Icons.local_fire_department_rounded, 'Current Streak', '${_streak()} days', AppTheme.warning),
          ],
        );
      }),
      const SizedBox(height: 32),
      const Text('Recent Scores', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      if (_scores.isEmpty)
        _buildEmptyState('No scores yet', 'Take your first quiz to see results!')
      else
        _buildScoresTable(_scores.take(5).toList()),
    ]));
  }

  Widget _buildQuizCard(Quiz quiz) {
    final isCompleted = _completedQuizIds.contains(quiz.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCompleted ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.surfaceLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.article_rounded,
              color: isCompleted ? AppTheme.success : AppTheme.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${quiz.questionCount} Questions • ${quiz.durationMinutes} Min • ${quiz.quizDate.day}/${quiz.quizDate.month}/${quiz.quizDate.year}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!isCompleted)
            FilledButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(student: widget.student, quiz: quiz)));
                _loadData();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Start'),
            )
          else
            const Chip(
              label: Text('Completed', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.transparent,
              side: BorderSide(color: AppTheme.success),
              labelStyle: TextStyle(color: AppTheme.success),
            ),
        ],
      ),
    );
  }

  Widget _buildScores() {
    return ListView(padding: const EdgeInsets.all(28), children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceLight)),
        child: Row(children: [
          const Icon(Icons.score_rounded, color: AppTheme.accent, size: 20),
          const SizedBox(width: 12),
          Text('${_scores.length} quiz results', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ]),
      ),
      const SizedBox(height: 20),
      if (_scores.isEmpty)
        _buildEmptyState('No scores yet', 'Complete quizzes to see your results')
      else
        _buildScoresTable(_scores),
    ]);
  }

  Widget _buildScoresTable(List<StudentScore> scores) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceLight)),
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
              DataColumn(label: Text('QUIZ')),
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('CORRECT')),
              DataColumn(label: Text('MARKS')),
              DataColumn(label: Text('SCORE')),
            ],
            rows: List.generate(scores.length, (i) {
              final s = scores[i];
              final pct = s.percentage;
              final color = pct >= 70 ? AppTheme.success : pct >= 40 ? AppTheme.warning : AppTheme.error;
              return DataRow(cells: [
                DataCell(Text('${i + 1}', style: const TextStyle(color: AppTheme.textSecondary))),
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(s.quizTitle ?? 'Quiz', overflow: TextOverflow.ellipsis),
                )),
                DataCell(Text('${s.quizDate.day}/${s.quizDate.month}/${s.quizDate.year}')),
                DataCell(Text('${s.correctAnswers}/${s.totalQuestions}')),
                DataCell(Text('${s.obtainedMarks}/${s.totalMarks}')),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                )),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalytics() {
    if (_scores.length < 2) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.insights_rounded, size: 60, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
        const SizedBox(height: 16), Text('Need at least 2 quizzes for analytics', style: Theme.of(context).textTheme.bodyMedium),
      ]));
    }

    final rev = _scores.reversed.toList();
    final tc = _scores.fold<int>(0, (s, e) => s + e.correctAnswers);
    final tq = _scores.fold<int>(0, (s, e) => s + e.totalQuestions);
    final pct = tq > 0 ? (tc / tq * 100) : 0.0;

    return ListView(padding: const EdgeInsets.all(28), children: [
      // Top row: accuracy + streak side by side
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _accuracyCard(pct, tc, tq)),
            const SizedBox(width: 20),
            Expanded(child: _chartCard(rev)),
          ]);
        }
        return Column(children: [
          _accuracyCard(pct, tc, tq),
          const SizedBox(height: 20),
          _chartCard(rev),
        ]);
      }),
    ]);
  }

  Widget _accuracyCard(double pct, int tc, int tq) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.surfaceLight)),
      child: Column(children: [
        const Text('Overall Accuracy', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 20),
        SizedBox(width: 140, height: 140, child: Stack(fit: StackFit.expand, children: [
          CircularProgressIndicator(value: pct / 100, strokeWidth: 12, backgroundColor: AppTheme.surfaceLight,
            color: pct >= 70 ? AppTheme.success : pct >= 40 ? AppTheme.warning : AppTheme.error),
          Center(child: Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary))),
        ])),
        const SizedBox(height: 16),
        Text('$tc / $tq correct answers', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _chartCard(List<StudentScore> rev) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.surfaceLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Score Trend', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        SizedBox(height: 220, child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.surfaceLight, strokeWidth: 1)),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35,
              getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)))),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false), minY: 0, maxY: 100,
          lineBarsData: [LineChartBarData(
            spots: rev.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.percentage)).toList(),
            isCurved: true, color: AppTheme.accent, barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) =>
              FlDotCirclePainter(radius: 4, color: AppTheme.accent, strokeWidth: 2, strokeColor: Colors.white)),
            belowBarData: BarAreaData(show: true, color: AppTheme.accent.withValues(alpha: 0.15)),
          )],
        ))),
      ]),
    );
  }

  int _streak() {
    if (_scores.isEmpty) return 0;
    int s = 1; // Start with 1 if there's at least one score
    // Logic for streak calculation might need refinement if not strictly daily
    // For now, strict daily check
    DateTime? p;
    final sorted = List<StudentScore>.from(_scores)..sort((a, b) => b.quizDate.compareTo(a.quizDate));
    // If multiple quizzes on same day, treat as one day activity
    final uniqueDates = sorted.map((s) => DateTime(s.quizDate.year, s.quizDate.month, s.quizDate.day)).toSet().toList();
    uniqueDates.sort((a, b) => b.compareTo(a));

    if (uniqueDates.isEmpty) return 0;

    // Check if today or yesterday has a quiz
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (uniqueDates.first.difference(today).inDays.abs() > 1) return 0;

    p = uniqueDates.first;
    for (int i = 1; i < uniqueDates.length; i++) {
        if (p!.difference(uniqueDates[i]).inDays == 1) {
            s++;
            p = uniqueDates[i];
        } else {
            break;
        }
    }
    return s;
  }

  Widget _stat(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_rounded, size: 50, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
