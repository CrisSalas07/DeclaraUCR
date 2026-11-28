import 'package:shared_preferences/shared_preferences.dart';

/// Whether an account already saw the first-use tour on this phone (U-06).
/// Per account, so every new account sees it once even on a phone where
/// someone else already did; a new phone shows it again, which is fine.
abstract class OnboardingStore {
  /// Whether the account [uid] was already shown the tour.
  Future<bool> seen(String uid);

  /// Records that [uid] saw the tour, so it does not open by itself again.
  Future<void> markSeen(String uid);
}

/// [OnboardingStore] in the phone's shared preferences.
class PrefsOnboardingStore implements OnboardingStore {
  final _prefs = SharedPreferencesAsync();

  static String _key(String uid) => 'onboarding.seen.$uid';

  @override
  Future<bool> seen(String uid) async =>
      await _prefs.getBool(_key(uid)) ?? false;

  @override
  Future<void> markSeen(String uid) => _prefs.setBool(_key(uid), true);
}

/// For tests and previews: the tour counts as seen unless told otherwise.
class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore({this.wasSeen = true});

  bool wasSeen;
  final _seenBy = <String>{};

  @override
  Future<bool> seen(String uid) async => wasSeen || _seenBy.contains(uid);

  @override
  Future<void> markSeen(String uid) async => _seenBy.add(uid);
}
