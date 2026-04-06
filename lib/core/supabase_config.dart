class SupabaseConfig {
  // FYLL INN DISSE NÅR DU ER KLAR
  static const String url = 'SETT_INN_SUPABASE_URL';
  static const String anonKey = 'SETT_INN_SUPABASE_ANON_KEY';

  static bool get isConfigured =>
      url != 'SETT_INN_SUPABASE_URL' &&
      anonKey != 'SETT_INN_SUPABASE_ANON_KEY';
}