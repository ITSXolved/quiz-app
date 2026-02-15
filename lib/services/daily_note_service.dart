import '../config/supabase_config.dart';
import '../models/daily_topic.dart';
import '../models/daily_note_section.dart';

class DailyNoteService {
  static const String _topicsTable = 'daily_topics';
  static const String _sectionsTable = 'daily_note_sections';

  // --- Topics ---

  static Future<List<DailyTopic>> getTopicsForDate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await SupabaseConfig.client
          .from(_topicsTable)
          .select()
          .eq('topic_date', dateStr)
          .order('created_at', ascending: true);
      return (response as List).map((e) => DailyTopic.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<String> createTopic(DateTime date, String title) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final res = await SupabaseConfig.client.from(_topicsTable).insert({
      'topic_date': dateStr,
      'title': title,
    }).select().single();
    return res['id'] as String;
  }

  static Future<void> deleteTopic(String id) async {
    await SupabaseConfig.client.from(_topicsTable).delete().eq('id', id);
  }

  static Future<void> toggleTopicStatus(String id, bool isActive) async {
    await SupabaseConfig.client.from(_topicsTable).update({
      'is_active': isActive,
    }).eq('id', id);
  }

  // --- Sections ---

  static Future<List<DailyNoteSection>> getSectionsForTopic(String topicId) async {
    try {
      final response = await SupabaseConfig.client
          .from(_sectionsTable)
          .select()
          .eq('topic_id', topicId)
          .order('order_index', ascending: true);
      return (response as List).map((e) => DailyNoteSection.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> createSection(String topicId, String heading, dynamic contentJson, int orderIndex) async {
    await SupabaseConfig.client.from(_sectionsTable).insert({
      'topic_id': topicId,
      'heading': heading,
      'content_json': contentJson,
      'order_index': orderIndex,
    });
  }

  static Future<void> updateSection(String id, String heading, dynamic contentJson, int orderIndex) async {
    await SupabaseConfig.client.from(_sectionsTable).update({
      'heading': heading,
      'content_json': contentJson,
      'order_index': orderIndex,
    }).eq('id', id);
  }

  static Future<void> deleteSection(String id) async {
    await SupabaseConfig.client.from(_sectionsTable).delete().eq('id', id);
  }
}
