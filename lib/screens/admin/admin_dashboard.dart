import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/question_service.dart';
import '../../services/student_service.dart';
import '../../models/quiz.dart';
 // Keep for type check if needed
import '../../models/student.dart';
import '../login_screen.dart';
import 'create_quiz_screen.dart';
import 'quiz_questions_screen.dart';
import 'student_list_screen.dart';
import 'admin_daily_notes_screen.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AdminDashboard({super.key, required this.adminData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  // 0: Overview, 1: Quizzes, 2: Students, 3: Daily Notes
  List<Quiz> _quizzes = [];
  List<Student> _students = [];
  bool _isLoading = true;
  int _totalQuestions = 0;
  bool _sidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final quizzes = await QuestionService.getAllQuizzes();
      final students = await StudentService.getPaidStudents();
      
      int qCount = 0;
      for (var q in quizzes) { qCount += q.questionCount; }

      setState(() {
        _quizzes = quizzes;
        _students = students;
        _totalQuestions = qCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  final _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Overview'),
    _NavItem(Icons.assignment_rounded, 'Quizzes'),
    _NavItem(Icons.people_rounded, 'Students'),
    _NavItem(Icons.calendar_today_rounded, 'Daily Notes'),
  ];


  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.surface],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Sidebar
              if (!isNarrow)
                _buildSidebar(isWide),
        
              // Main content area
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isNarrow),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold))
                          : _buildContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Mobile drawer
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
      child: Column(
        children: [
          // Logo area
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: collapsed ? 14 : 20),
            child: Row(
              children: [
                SizedBox(
                  height: 40,
                  width: collapsed ? 40 : 140,
                  child: Image.asset('assets/images/zyra_logo.png', fit: BoxFit.contain),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.surfaceLight.withValues(alpha: 0.3), height: 1),
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('MAIN MENU', style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            ),
          const SizedBox(height: 4),
          // Nav items
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
                        Text(item.label, style: TextStyle(
                          color: isActive ? AppTheme.accentGold : AppTheme.textSecondary,
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
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
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
                selected: isActive,
                selectedTileColor: AppTheme.accentGold.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  setState(() => _currentIndex = i);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
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
      child: Row(
        children: [
          if (isNarrow)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
              ),
            ),
          Text(
            _navItems[_currentIndex].label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (_currentIndex == 1)
            FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateQuizScreen(adminId: widget.adminData['id'])));
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Quiz'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded, color: AppTheme.accentGold, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.adminData['email']?.split('@')[0] ?? 'Admin', 
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0: return _buildOverview();
      case 1: return _buildQuizzesTable();
      case 2: return StudentListScreen(students: _students);
      case 3: return const AdminDailyNotesScreen();
      default: return _buildOverview();
    }
  }

  Widget _buildOverview() {
    // Stats calc
    final pubCount = _quizzes.where((q) => q.status == QuizStatus.published).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accentGold,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          // Welcome banner
          Container(
            padding: const EdgeInsets.all(28),
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
                    Text('Welcome back, Admin', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text('You have ${_quizzes.length} quizzes and ${_students.length} students to manage today.', 
                      style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 14)),
                  ]),
                ),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.accentGold, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Stats grid
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final crossCount = constraints.maxWidth > 800 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isMobile ? 1.8 : 2.2,
              children: [
                _StatCard(icon: Icons.people_rounded, label: 'Total Students', value: '${_students.length}', color: AppTheme.accentGold),
                _StatCard(icon: Icons.quiz_rounded, label: 'Total Quizzes', value: '${_quizzes.length}', color: AppTheme.accentGold),
                _StatCard(icon: Icons.published_with_changes_rounded, label: "Published Quizzes", value: '$pubCount', color: AppTheme.success),
                _StatCard(icon: Icons.question_answer_outlined, label: 'Total Questions', value: '$_totalQuestions', color: AppTheme.warning),
              ],
            );
          }),
          const SizedBox(height: 32),

          // Recent Activity
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppTheme.accentGold, size: 22),
              const SizedBox(width: 12),
              const Text('Recent Quizzes', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _currentIndex = 1),
                icon: const Text('View All', style: TextStyle(color: AppTheme.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                label: const Icon(Icons.arrow_forward_rounded, color: AppTheme.accentGold, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildRecentQuizzesTable(),
        ],
      ),
    );
  }

  Widget _buildRecentQuizzesTable() {
    if (_quizzes.isEmpty) {
      return _buildEmptyState('No quizzes created yet', 'Click "Create Quiz" to get started');
    }

    final recent = _quizzes.take(8).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.surface),
                  dataRowColor: WidgetStateProperty.all(AppTheme.cardBg),
                  headingTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  dataTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('TITLE')),
                    DataColumn(label: Text('DATE')),
                    DataColumn(label: Text('QUESTIONS')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: List.generate(recent.length, (i) {
                    final q = recent[i];
                    return DataRow(
                      onSelectChanged: (_) {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => QuizQuestionsScreen(adminId: widget.adminData['id'], quiz: q)));
                      },
                      cells: [
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Text(q.title, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      DataCell(Text('${q.quizDate.day}/${q.quizDate.month}/${q.quizDate.year}')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)),
                        child: Text('${q.questionCount}', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                      )),
                      DataCell(_StatusBadge(status: q.status)),
                      DataCell(IconButton(
                        onPressed: () => _deleteQuiz(q),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                        tooltip: 'Delete',
                      )),
                    ]);
                  }),
                ),
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildQuizzesTable() {
    if (_quizzes.isEmpty) {
      return Center(child: _buildEmptyState('No quizzes found', 'Click "Create Quiz" to get started'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.accentGold,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          // Filter/search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceLight)),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text('${_quizzes.length} quizzes total', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const Spacer(),
              _StatusBadge(status: QuizStatus.published),
              const SizedBox(width: 8),
              const Text('Published', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 20),
          // Quizzes data table
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.surfaceLight.withValues(alpha: 0.5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppTheme.surface),
                        dataRowColor: WidgetStateProperty.all(AppTheme.cardBg),
                        headingTextStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        dataTextStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('TITLE')),
                          DataColumn(label: Text('DATE')),
                          DataColumn(label: Text('DURATION')),
                          DataColumn(label: Text('QUESTIONS')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: List.generate(_quizzes.length, (i) {
                          final q = _quizzes[i];
                          return DataRow(
                            onSelectChanged: (_) {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => QuizQuestionsScreen(adminId: widget.adminData['id'], quiz: q)));
                            },
                            cells: [
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 250),
                                child: Text(q.title, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            DataCell(Text('${q.quizDate.day}/${q.quizDate.month}/${q.quizDate.year}')),
                            DataCell(Text('${q.durationMinutes} min')),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)),
                              child: Text('${q.questionCount}', style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                            )),
                            DataCell(_StatusBadge(status: q.status)),
                            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                onPressed: () {
                                   // Edit quiz metadata? Not implemented yet, maybe later.
                                   // For now just open details
                                   Navigator.push(context, MaterialPageRoute(builder: (_) => QuizQuestionsScreen(adminId: widget.adminData['id'], quiz: q)));
                                },
                                icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 20),
                                tooltip: 'Manage Questions',
                              ),
                              IconButton(
                                onPressed: () => _deleteQuiz(q),
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 20),
                                tooltip: 'Delete',
                              ),
                            ])),
                          ]);
                        }),
                      ),
                    ),
                  );
                }
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteQuiz(Quiz q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Quiz?'),
        content: Text('Delete "${q.title}" and all its questions? This cannot be undone.'),
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
      await QuestionService.deleteQuiz(q.id);
      _loadData();
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 60, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // Remove _todayStr if unused or keep if used elsewhere. It was used in _buildOverview only.
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 180;
        return Container(
          padding: EdgeInsets.all(isSmall ? 12 : 16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isSmall ? 18 : 22),
              ),
              SizedBox(width: isSmall ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label, 
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: isSmall ? 10 : 12), 
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final QuizStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPub = status == QuizStatus.published;
    final color = isPub ? AppTheme.success : AppTheme.textSecondary;
    final label = isPub ? 'PUBLISHED' : 'DRAFT';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

