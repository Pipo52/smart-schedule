/// Client clock corrected by a Firestore server sample.
///
/// Last-write-wins compares these instants, so a phone whose clock is
/// ahead does not beat a real later edit from another device.
class SyncClock {
  SyncClock._();

  static Duration offset = Duration.zero;

  static DateTime now() => DateTime.now().toUtc().add(offset);

  static void alignTo(DateTime serverNow) {
    offset = serverNow.toUtc().difference(DateTime.now().toUtc());
  }
}
