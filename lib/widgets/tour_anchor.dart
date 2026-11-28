import 'package:flutter/widgets.dart';

/// The parts of a screen the guided tour can point at. Outside the tour
/// (no [TourScope] above) an anchor is just its child.
class TourScope extends InheritedWidget {
  const TourScope({super.key, required this.keys, required super.child});

  /// One key per anchor id, shared by the whole tour.
  final Map<String, GlobalKey> keys;

  static TourScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TourScope>();

  @override
  bool updateShouldNotify(TourScope oldWidget) => keys != oldWidget.keys;
}

/// A part of a screen the tour can point at, found by its [id].
class TourAnchor extends StatelessWidget {
  const TourAnchor({super.key, required this.id, required this.child});

  /// Id of the part, as the tour's stops name it (`schedule.grid`).
  final String id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = TourScope.maybeOf(context);
    if (scope == null) return child;
    return KeyedSubtree(
      key: scope.keys.putIfAbsent(id, () => GlobalKey(debugLabel: id)),
      child: child,
    );
  }
}
