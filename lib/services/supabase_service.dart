import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  final Uuid _uuid = const Uuid();

  /// 🔥 TEST: Opprett jobb i Supabase
  Future<void> createTestJob() async {
    try {
      final jobData = {
        'id': _uuid.v4(), // ✅ FIX: UUID
        'title': 'TEST JOBB',
        'description': 'Dette er en test fra Flutter',
        'price': 500,
        'category': 'Test',
        'location_name': 'Skien',
        'lat': 59.14,
        'lng': 9.65,
        'created_by_user_id': _uuid.v4(), // ✅ FIX: UUID
        'status': 'open',
      };

      final response = await client.from('jobs').insert(jobData);

      print("✅ SUCCESS: Job inserted");
      print(response);
    } catch (e) {
      print("❌ ERROR inserting job:");
      print(e);
    }
  }

  /// 🔥 Hent alle jobber
  Future<List<dynamic>> getJobs() async {
    try {
      final response = await client.from('jobs').select();

      print("📥 FETCHED JOBS:");
      print(response);

      return response;
    } catch (e) {
      print("❌ ERROR fetching jobs:");
      print(e);
      return [];
    }
  }
}