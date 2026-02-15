import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/daily_topic.dart';
import '../../models/daily_note_section.dart';
import '../../services/daily_note_service.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'dart:convert';

class AdminDailyNotesScreen extends StatefulWidget {
  const AdminDailyNotesScreen({super.key});

  @override
  State<AdminDailyNotesScreen> createState() => _AdminDailyNotesScreenState();
}

class _AdminDailyNotesScreenState extends State<AdminDailyNotesScreen> {
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
    _topics = await DailyNoteService.getTopicsForDate(date);
    setState(() => _isLoading = false);
  }

  Future<void> _createTopic() async {
    final controller = TextEditingController();
    DateTime creationDate = _selectedDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppTheme.cardBg,
            title: const Text('Create New Note', style: TextStyle(color: AppTheme.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker Row
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: creationDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accentGold, onPrimary: AppTheme.primaryDark, surface: AppTheme.cardBg, onSurface: AppTheme.textPrimary)), child: child!),
                    );
                    if (picked != null) {
                      setStateDialog(() => creationDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.surfaceLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppTheme.accentGold, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${creationDate.day}/${creationDate.month}/${creationDate.year}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title Input
                TextField(
                  controller: controller,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Note Title / Topic',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.surfaceLight)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.accentGold)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isEmpty) return;
                  Navigator.pop(ctx);
                  
                  // Create Topic
                  final newId = await DailyNoteService.createTopic(creationDate, controller.text);
                  
                  // If date changed, update main view
                  if (creationDate != _selectedDate) {
                    setState(() => _selectedDate = creationDate);
                    _fetchTopics(creationDate);
                  } else {
                    _fetchTopics(_selectedDate);
                  }

                  // Navigate seamlessly to editing sections
                  if (mounted) {
                    final newTopic = DailyTopic(
                      id: newId,
                      topicDate: creationDate,
                      title: controller.text,
                      isActive: false, // Default to inactive when created
                      createdAt: DateTime.now(),
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TopicEditorScreen(topic: newTopic)));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold, foregroundColor: AppTheme.primaryDark),
                child: const Text('Create & Add Sections'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleTopicStatus(DailyTopic topic) async {
    await DailyNoteService.toggleTopicStatus(topic.id, !topic.isActive);
    _fetchTopics(_selectedDate);
  }

  Future<void> _deleteTopic(String id) async {
    await DailyNoteService.deleteTopic(id);
    _fetchTopics(_selectedDate);
  }

  Future<void> _seedExampleData() async {
    setState(() => _isLoading = true);
    try {
      // Create Topic
      final topicId = await DailyNoteService.createTopic(DateTime.now(), "DAY 1 NIYYAT — “Main Yahan Kyun Hoon?”");
      
      // Section 1: Opening Reflection
      await _createSection(topicId, "Opening Reflection", [
        {"insert": "Aaj ka sawal seedha dil par:\nMain is stage par Quran kyun seekhna chahta hoon?\nKya:\n"},
        {"insert": "•", "attributes": {"list": "bullet"}},
        {"insert": " Sirf curiosity hai?\n"},
        {"insert": "•", "attributes": {"list": "bullet"}},
        {"insert": " Sirf certificate?\n"},
        {"insert": "•", "attributes": {"list": "bullet"}},
        {"insert": " Ya waqai badalna chahta hoon?\n\n"},
        {"insert": "5 second khamoshi karein.\nDil mein jawab dein.\n"}
      ], 0);

      // Section 2: Quranic Insight
      await _createSection(topicId, "Quranic Insight", [
        {"insert": "Surah Al-Hujurat 49:1\n“Ya ayyuhallazina aamanu la tuqaddimu baina yadayillahi wa rasoolih.”\n\nMatlab:\n“Iman walon, Allah aur Rasool se aage mat badho.”\n\nIska matlab sirf chalna nahi hai.\nIska matlab hai:\n"},
        {"insert": "•", "attributes": {"list": "bullet"}},
        {"insert": " Apni soch ko deen se upar mat rakho\n"},
        {"insert": "•", "attributes": {"list": "bullet"}},
        {"insert": " Apni ego ko haq se upar mat rakho\n"},
        {"insert": "•", "attributes": {"list": "bullet"}},
        {"insert": " Pehle suno, phir samjho, phir jhuk kar accept karo\n\n"},
        {"insert": "Quran us dil mein utarta hai jo jhukta hai.\n"}
      ], 1);

      // Section 3: Tajweed Focus
      await _createSection(topicId, "Tajweed Focus (Day 1)", [
        {"insert": "Rule: Madd Tabee’i (2 count stretch)\nExample:\n“Yaa”\n“Aamanu”\n\nPractice (2 count kheench kar):\nYaa…\nAa…manu…\n\nNote likhein:\nAaj maine madd ko 2 count par control karne ki practice ki.\n"}
      ], 2);

      // Section 4: Life Translation
      await _createSection(topicId, "Life Translation", [
        {"insert": "Agar niyyat saaf nahi:\nIlm information ban jata hai.\nAgar niyyat saaf ho:\nIlm hidayat ban jata hai.\n\nGhar par:\nAgar niyyat jeetne ki ho — jhagda.\nAgar niyyat samajhne ki ho — sukoon.\n\nBusiness mein:\nAgar niyyat sirf munafa — tension.\nAgar niyyat halal — barkat.\n\nJob mein:\nAgar niyyat impresses karna — stress.\nAgar niyyat amanat samajhna — itminan.\n"}
      ], 3);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Example data loaded successfully!')));
      _fetchTopics(_selectedDate);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error seeding data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSection(String topicId, String heading, List<dynamic> content, int index) async {
    await DailyNoteService.createSection(topicId, heading, content, index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surfaceLight)),
          child: Row(
            children: [
              const Text('Daily Notes Topics', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              // Date Filter
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list_rounded, color: AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Create Button
              ElevatedButton.icon(
                onPressed: _createTopic,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Create Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold, 
                  foregroundColor: AppTheme.primaryDark, 
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
              const SizedBox(width: 12),
              IconButton(onPressed: _seedExampleData, icon: const Icon(Icons.cloud_download_rounded, color: AppTheme.accentGold), tooltip: 'Load Example Data'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Topics List
        Expanded(
          child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold)) : 
          _topics.isEmpty ? 
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.topic_outlined, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('No topics for this date', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ) :
          ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) {
              final topic = _topics[i];
              return ListTile(
                tileColor: AppTheme.cardBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.surfaceLight)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(topic.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        topic.isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: topic.isActive ? AppTheme.accentGold : AppTheme.textSecondary,
                      ),
                      onPressed: () => _toggleTopicStatus(topic),
                      tooltip: topic.isActive ? 'Mark as Inactive' : 'Mark as Active',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppTheme.accentGold),
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => TopicEditorScreen(topic: topic)));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                      onPressed: () => _deleteTopic(topic.id),
                    ),
                  ],
                ),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => TopicEditorScreen(topic: topic)));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class TopicEditorScreen extends StatefulWidget {
  final DailyTopic topic;
  const TopicEditorScreen({super.key, required this.topic});

  @override
  State<TopicEditorScreen> createState() => _TopicEditorScreenState();
}

class _TopicEditorScreenState extends State<TopicEditorScreen> {
  List<DailyNoteSection> _sections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  Future<void> _fetchSections() async {
    setState(() => _isLoading = true);
    _sections = await DailyNoteService.getSectionsForTopic(widget.topic.id);
    setState(() => _isLoading = false);
  }

  Future<void> _addSection([DailyNoteSection? section]) async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => SectionEditorScreen(topicId: widget.topic.id, section: section)));
    if (result == true) _fetchSections();
  }

  Future<void> _deleteSection(String id) async {
    await DailyNoteService.deleteSection(id);
    _fetchSections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: Text(widget.topic.title, style: const TextStyle(color: AppTheme.textPrimary)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.accentGold)) :
        ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _sections.length + 1, // +1 for "Add Section" button at end
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (ctx, i) {
            if (i == _sections.length) {
              return Center(
                child: ElevatedButton.icon(
                  onPressed: () => _addSection(),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Add Section'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardBg,
                    foregroundColor: AppTheme.accentGold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    side: const BorderSide(color: AppTheme.accentGold),
                  ),
                ),
              );
            }
            final section = _sections[i];
            // Display preview
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surfaceLight)),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          section.heading,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.textSecondary, size: 20), onPressed: () => _addSection(section)),
                      IconButton(icon: const Icon(Icons.delete, color: AppTheme.error, size: 20), onPressed: () => _deleteSection(section.id)),
                    ],
                  ),
                  iconColor: AppTheme.accentGold,
                  collapsedIconColor: AppTheme.textSecondary,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                      child: Builder(builder: (context) {
                        quill.QuillController controller;
                        try {
                          controller = quill.QuillController(
                            document: quill.Document.fromJson(_ensureValidQuillDelta(section.contentJson)),
                            selection: const TextSelection.collapsed(offset: 0),
                            readOnly: true,
                          );
                        } catch (e) {
                           controller = quill.QuillController.basic();
                        }
                        return quill.QuillEditor.basic(
                          controller: controller,
                          config: const quill.QuillEditorConfig(
                            placeholder: 'No content',
                            scrollable: false,
                            autoFocus: false,
                            expands: false,
                          ),
                        );
                      }),
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

class SectionEditorScreen extends StatefulWidget {
  final String topicId;
  final DailyNoteSection? section;
  const SectionEditorScreen({super.key, required this.topicId, this.section});

  @override
  State<SectionEditorScreen> createState() => _SectionEditorScreenState();
}

class _SectionEditorScreenState extends State<SectionEditorScreen> {
  late TextEditingController _headingController;
  late quill.QuillController _quillController;

  @override
  void initState() {
    super.initState();
    _headingController = TextEditingController(text: widget.section?.heading ?? '');
    
    if (widget.section != null && widget.section!.contentJson != null) {
      try {
        _quillController = quill.QuillController(
          document: quill.Document.fromJson(_ensureValidQuillDelta(widget.section!.contentJson)),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
         _quillController = quill.QuillController.basic();
      }
    } else {
      _quillController = quill.QuillController.basic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        title: Text(widget.section == null ? 'New Section' : 'Edit Section', style: const TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () async {
              if (_headingController.text.isEmpty) return;
              final json = _quillController.document.toDelta().toJson();
              
              if (widget.section == null) {
                await DailyNoteService.createSection(widget.topicId, _headingController.text, json, 0); // Order index 0 for now
              } else {
                await DailyNoteService.updateSection(widget.section!.id, _headingController.text, json, widget.section!.orderIndex);
              }
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _headingController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Section Heading',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          Divider(color: AppTheme.surfaceLight.withValues(alpha: 0.5)),
          quill.QuillSimpleToolbar(
            controller: _quillController,
            config: const quill.QuillSimpleToolbarConfig(
              showBackgroundColorButton: false, // Keep it simple
              showColorButton: true,
              showFontFamily: false, // Use default
              showFontSize: true,
              toolbarIconAlignment: WrapAlignment.start,
              decoration: BoxDecoration(color: AppTheme.cardBg),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.surface, // Better contrast for editing
              child: quill.QuillEditor.basic(
                controller: _quillController,
                 config: const quill.QuillEditorConfig(
                  placeholder: 'Start typing your notes here...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
