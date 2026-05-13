import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/job.dart';
import '../providers/app_state.dart';
import '../screens/chat_screen.dart';
import '../screens/job_detail_screen.dart';

/// Sprint 8: håndterer FCM push-varsler ende-til-ende.
///
/// - Lagrer/oppdaterer FCM-token i profiles.fcm_token via AppState
/// - Viser lokal banner via flutter_local_notifications når app er i foreground
///   (FCM viser ikke OS-banner i foreground på iOS by default)
/// - Ruter til riktig skjerm når bruker trykker på push (background, terminated, foreground)
///
/// Singleton fordi vi trenger samme navigatorKey + samme listener-set
/// gjennom hele app-livet.
class PushNotificationsService {
  PushNotificationsService._();
  static final PushNotificationsService instance = PushNotificationsService._();

  /// GlobalKey som settes på MaterialApp.navigatorKey i main.dart, slik at
  /// vi kan navigere fra service-laget når en push tappes (utenfor BuildContext).
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  AppState? _appState;
  bool _initialized = false;
  bool _localPluginReady = false;
  String? _currentToken;
  RemoteMessage? _pendingTapMessage;

  /// Kalles én gang fra AppState-constructor. Setter opp listeners og
  /// flutter_local_notifications. Idempotent — trygt å kalle flere ganger.
  Future<void> init(AppState appState) async {
    _appState = appState;
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    // Token-rotasjon: oppdater i profiles ved hver endring.
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    // Foreground: vis lokal banner siden FCM ikke gjør det automatisk på iOS.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background-tap: app var i bakgrunn, bruker trykket på push.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Cold-start-tap: app var lukket, bruker trykket på push.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // Lagre — _routeFromData trenger navigator + jobs lastet.
      _pendingTapMessage = initial;
      _tryDispatchPending();
    }
  }

  Future<void> _initLocalNotifications() async {
    if (_localPluginReady) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    // flutter_local_notifications v21 bruker named parameters for initialize
    // (settings + onDidReceiveNotificationResponse). Tidligere versjoner var
    // positional. Hvis du senere oppgraderer pakken, sjekk om signaturen
    // fortsatt er den samme — det er ikke breaking i forhold til andre v21+
    // versjoner som vi vet om nå.
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _routeFromPayloadString(payload);
        }
      },
    );
    _localPluginReady = true;
  }

  /// Steg 1: viser OS-prompt for push-tillatelse. Kalles fra onboarding.
  /// Returnerer true hvis brukeren tillot, false ellers.
  /// Bruker kan IKKE være authenticated her — dette skjer FØR register.
  Future<bool> requestPermissionPreAuth() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('PushNotif requestPermissionPreAuth error: $e');
      return false;
    }
  }

  /// Kalles fra AppState etter vellykket login/register/loadCurrentUser.
  /// Hvis brukeren allerede har tillatt push (typisk returning user eller
  /// nettopp tillot via onboarding), henter token og lagrer i profiles.
  /// Hvis tillatelse ikke gitt, gjør den ingenting — bruker kan re-aktivere
  /// fra Settings senere.
  Future<void> tryFetchAndSaveIfAuthorized() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _fetchAndSaveToken();
      }
      // Pending tap fra cold-start kan nå rute siden jobs er lastet og
      // navigator er klar.
      _tryDispatchPending();
    } catch (e) {
      debugPrint('PushNotif tryFetchAndSaveIfAuthorized error: $e');
    }
  }

  /// Kalles fra AppState.logout. Rydder lokal state og setter token=null
  /// i profiles slik at gammel device ikke får push for ny bruker.
  Future<void> clearOnLogout() async {
    final state = _appState;
    if (state != null) {
      // Best-effort: hvis token-write feiler er det ikke katastrofalt,
      // brukeren er allerede logget ut og får bare push for sin gamle bruker
      // til token roteres neste gang.
      await state.setFcmToken(null);
    }
    _currentToken = null;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('PushNotif deleteToken error: $e');
    }
  }

  Future<void> _fetchAndSaveToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    if (token == _currentToken) return;
    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    _currentToken = token;
    final state = _appState;
    if (state == null) return;
    if (!state.isAuthenticated) return;
    await state.setFcmToken(token);
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Bruker kan ha skrudd av in-app-banner via push_notifications_enabled-toggle,
    // men dersom Edge Function har sendt push hit betyr det at toggle er ON
    // (Edge Function respekterer toggle). Vis banner.
    final payload = _payloadFromMessage(message);
    // flutter_local_notifications v21 bruker named parameters for show.
    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title ?? 'SmartHjelp',
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'smarthjelp_push',
          'SmartHjelp varsler',
          channelDescription: 'Varsler om oppdrag og meldinger',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    _pendingTapMessage = message;
    _tryDispatchPending();
  }

  void _tryDispatchPending() {
    final pending = _pendingTapMessage;
    if (pending == null) return;
    final state = _appState;
    final navigator = navigatorKey.currentState;
    if (state == null || navigator == null) return;
    if (!state.isAuthenticated) return;

    _pendingTapMessage = null;
    _routeFromData(pending.data);
  }

  String _payloadFromMessage(RemoteMessage message) {
    final type = message.data['type']?.toString() ?? '';
    final jobId = message.data['job_id']?.toString() ?? '';
    return '$type|$jobId';
  }

  void _routeFromPayloadString(String payload) {
    final parts = payload.split('|');
    final type = parts.isNotEmpty ? parts[0] : '';
    final jobId = parts.length > 1 ? parts[1] : '';
    _routeFromData({'type': type, 'job_id': jobId});
  }

  Future<void> _routeFromData(Map<String, dynamic> data) async {
    final type = data['type']?.toString();
    final jobId = data['job_id']?.toString();
    if (jobId == null || jobId.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final state = _appState;
    if (state == null) return;

    Job? job = state.getJobById(jobId);
    if (job == null) {
      // Cold-start eller jobben er ikke lastet ennå — prøv å reload.
      await state.reloadJobs();
      job = state.getJobById(jobId);
    }
    if (job == null) {
      // Ga opp — kanskje jobben er slettet eller bruker ikke har tilgang.
      debugPrint('PushNotif route: job $jobId not found etter reload');
      return;
    }

    // type=='message' → ChatScreen, alt annet → JobDetailScreen.
    // Eksisterende navigasjon-loop-fix (fromChat/fromJobDetail) gjelder her
    // også: vi pushes nye routes på toppen, så hvis bruker var midt i en
    // chat for en annen jobb og får push for en tredje, får de et nytt nivå
    // i nav-stacken. Akseptabelt for MVP — alternativ er pushReplacement,
    // men det fjerner navigasjonshistorikk uventet.
    if (type == 'message') {
      navigator.push(
        MaterialPageRoute(builder: (_) => ChatScreen(job: job!)),
      );
    } else {
      navigator.push(
        MaterialPageRoute(builder: (_) => JobDetailScreen(job: job!)),
      );
    }
  }
}