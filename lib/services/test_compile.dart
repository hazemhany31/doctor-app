import 'package:flutter_local_notifications/flutter_local_notifications.dart';
void main() {
  const details = AndroidNotificationDetails(
    'channel',
    'name',
    channelDescription: 'desc',
  );
  assert(details.channelId == 'channel');
}
