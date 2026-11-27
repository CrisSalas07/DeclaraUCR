import 'package:shared_preferences/shared_preferences.dart';

/// Whether this phone already showed the first-use tour (U-06). Kept on the
/// phone, not in the account: a new phone shows it again, which is fine.
abstract class OnboardingStore {
  Future<bool> seen();

  Future<void> markSeen();
}

class PrefsOnboardingStore implements OnboardingStore {
  static const _key = 'onboarding.seen';

  final _prefs = SharedPreferencesAsync();

  @override
  Future<bool> seen() async => await _prefs.getBool(_key) ?? false;

  @override
  Future<void> markSeen() => _prefs.setBool(_key, true);
}

/// For tests and previews: the tour counts as seen unless told otherwise.
class MemoryOnboardingStore implements OnboardingStore {
  MemoryOnboardingStore({this.wasSeen = true});

  bool wasSeen;

  @override
  Future<bool> seen() async => wasSeen;

  @override
  Future<void> markSeen() async => wasSeen = true;
}
