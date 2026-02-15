import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../models/response.dart';
import '../../models/quiz.dart';
import '../../services/auth_service.dart';
import '../../services/student_service.dart';
import 'student_daily_view.dart';
import '../../services/question_service.dart';
import '../login_screen.dart';
import 'quiz_screen.dart';
import '../../services/daily_note_service.dart';
import '../../models/daily_topic.dart';
// TopicViewerScreen is in student_daily_view.dart

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
  List<DailyTopic> _todayTopics = []; // New state variable
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
      final todayTopics = await DailyNoteService.getTopicsForDate(DateTime.now());
      
      
      final completed = scores.map((s) => s.quizId).whereType<String>().toSet();

      setState(() {
        _scores = scores;
        _availableQuizzes = quizzes;
        _todayTopics = todayTopics.where((t) => t.isActive).toList();
        _completedQuizIds = completed;
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Home'),
    _NavItem(Icons.calendar_today_rounded, 'Daily Study'),
    _NavItem(Icons.score_rounded, 'My Scores'),
    _NavItem(Icons.analytics_rounded, 'Analytics'),
  ];

  Future<void> _startQuiz(Quiz quiz) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(student: widget.student, quiz: quiz)));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primaryDark, AppTheme.surface]),
        ),
        child: SafeArea(
          child: Row(children: [
            if (!isNarrow) _buildSidebar(isWide),
            Expanded(child: Column(children: [
              _buildTopBar(isNarrow),
              Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
                : IndexedStack(index: _currentIndex, children: [_buildHome(), StudentDailyView(student: widget.student, allQuizzes: _availableQuizzes, onStartQuiz: _startQuiz), _buildScores(), _buildAnalytics()])),
            ])),
          ]),
        ),
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
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.surfaceLight.withValues(alpha: 0.5))),
      ),
      child: Column(children: [
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 14 : 20),
          child: Row(children: [
            SizedBox(
              height: 40,
              width: collapsed ? 40 : 140,
              child: Image.asset('assets/images/zyra_logo.png', fit: BoxFit.contain),
            ),
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
                  color: isActive ? AppTheme.accentGold.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isActive ? Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)) : null,
                ),
                child: Row(
                  mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: isActive ? AppTheme.accentGold : AppTheme.textSecondary, size: 22),
                    if (!collapsed) ...[
                      const SizedBox(width: 12),
                      Text(item.label, style: TextStyle(color: isActive ? AppTheme.accentGold : AppTheme.textSecondary,
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
      backgroundColor: AppTheme.surface,
      child: SafeArea(child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            SizedBox(
              height: 45,
              width: 160,
              child: Image.asset('assets/images/zyra_logo.png', fit: BoxFit.contain),
            ),
          ]),
        ),
        Divider(color: AppTheme.surfaceLight.withValues(alpha: 0.3), height: 1),
        const SizedBox(height: 8),
        ...List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final isActive = _currentIndex == i;
          return ListTile(
            leading: Icon(item.icon, color: isActive ? AppTheme.accentGold : AppTheme.textSecondary),
            title: Text(item.label, style: TextStyle(color: isActive ? AppTheme.accentGold : AppTheme.textPrimary)),
            selected: isActive, selectedTileColor: AppTheme.accentGold.withValues(alpha: 0.1),
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
        color: AppTheme.surface.withValues(alpha: 0.5),
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
              decoration: BoxDecoration(color: AppTheme.accentGold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(7)),
              child: Center(child: Text(widget.student.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.w600, fontSize: 13))),
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

    return RefreshIndicator(onRefresh: _loadData, color: AppTheme.accentGold, child: ListView(padding: const EdgeInsets.all(28), children: [
      // Welcome banner
      Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.accentGold.withValues(alpha: 0.15), AppTheme.accentGold.withValues(alpha: 0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Salam, ${widget.student.name.split(' ')[0]}!', 
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text('You have ${_availableQuizzes.length - _completedQuizIds.length} quizzes pending for review.', 
                  style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 14)),
              ]),
            ),
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentGold, size: 24),
            ),
          ],
        ),
      ),

      // Today's Learning Section
      if (_todayTopics.isNotEmpty || sortedQuizzes.any((q) => _isSameDay(q.quizDate, DateTime.now()))) ...[
        Row(children: [
           Icon(Icons.today_rounded, color: AppTheme.accentGold, size: 22),
           const SizedBox(width: 12),
           const Text("Today's Learning", style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          // Calculate item width: if wide, half width minus spacing/2. If narrow, full width.
          final itemWidth = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
          
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ..._todayTopics.map((topic) => SizedBox(width: itemWidth, child: _buildTopicCard(topic, isGridItem: true))),
              ...sortedQuizzes.where((q) => _isSameDay(q.quizDate, DateTime.now())).map((q) => SizedBox(width: itemWidth, child: _buildQuizCard(q, isGridItem: true))),
            ],
          );
        }),
        const SizedBox(height: 32),
      ],

      // Quizzes List
      Row(children: [
        Icon(Icons.rocket_launch_rounded, color: AppTheme.accentGold, size: 22),
        const SizedBox(width: 12),
        const Text('Pick up where you left off', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 20),
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
            _stat(Icons.assignment_turned_in_rounded, 'Quizzes Taken', '${_scores.length}', AppTheme.accentGold),
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

  Widget _buildQuizCard(Quiz quiz, {bool isGridItem = false}) {
    final isCompleted = _completedQuizIds.contains(quiz.id);
    return Container(
      margin: isGridItem ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCompleted ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.surfaceLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isCompleted ? AppTheme.success : AppTheme.accentGold).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.menu_book_rounded,
              color: isCompleted ? AppTheme.success : AppTheme.accentGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  children: [
                    _quizInfoChip(Icons.timer_outlined, '${quiz.durationMinutes}m'),
                    _quizInfoChip(Icons.help_outline_rounded, '${quiz.questionCount} Qs'),
                    _quizInfoChip(Icons.calendar_today_rounded, '${quiz.quizDate.day}/${quiz.quizDate.month}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isCompleted)
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(student: widget.student, quiz: quiz)));
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: AppTheme.accentGold.withValues(alpha: 0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            )
          else
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _quizInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildScores() {
    return ListView(padding: const EdgeInsets.all(28), children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceLight)),
        child: Row(children: [
          const Icon(Icons.score_rounded, color: AppTheme.accentGold, size: 20),
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
      width: double.infinity,
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceLight)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth < 800 ? 800 : constraints.maxWidth), 
              child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.surface),
              dataRowColor: WidgetStateProperty.all(AppTheme.cardBg),
              headingTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              dataTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
              columnSpacing: 28,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('QUIZ')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('READING STATUS')), // New Column
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
                  DataCell(Container( // Reading Status Cell
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 14),
                      SizedBox(width: 4),
                      Text('Completed', style: TextStyle(color: AppTheme.success, fontSize: 11, fontWeight: FontWeight.w500)),
                    ]),
                  )),
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
          );
        }),
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
            isCurved: true, color: AppTheme.accentGold, barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) =>
              FlDotCirclePainter(radius: 4, color: AppTheme.accentGold, strokeWidth: 2, strokeColor: Colors.white)),
            belowBarData: BarAreaData(show: true, color: AppTheme.accentGold.withValues(alpha: 0.15)),
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildTopicCard(DailyTopic topic, {bool isGridItem = false}) {
    return Container(
      margin: isGridItem ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
           // Navigate to Topic Viewer
           Navigator.push(context, MaterialPageRoute(builder: (_) => TopicViewerScreen(topic: topic)));
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppTheme.accentGold, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('${topic.topicDate.day}/${topic.topicDate.month}/${topic.topicDate.year}', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: AppTheme.accentGold),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
