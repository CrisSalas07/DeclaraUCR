/// A value that arrives from a stream: still loading, failed, or loaded
/// (the loaded value itself may be `null`, e.g. a person without profile).
class Loadable<T> {
  const Loadable.loading() : value = null, loading = true, failed = false;
  const Loadable.data(this.value) : loading = false, failed = false;
  const Loadable.failed() : value = null, loading = false, failed = true;

  final T? value;
  final bool loading;
  final bool failed;
}
