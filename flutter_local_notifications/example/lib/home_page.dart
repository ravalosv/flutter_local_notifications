import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'info_value_string.dart';
import 'notification_service.dart';
import 'padded_elevated_button.dart';
import 'received_notification.dart';
import 'second_page.dart';

class HomePage extends StatefulWidget {
  const HomePage(
    this.notificationAppLaunchDetails, {
    Key? key,
  }) : super(key: key);

  static const String routeName = '/';

  final NotificationAppLaunchDetails? notificationAppLaunchDetails;

  bool get didNotificationLaunchApp => notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _linuxIconPathController = TextEditingController();

  bool _notificationsEnabled = false;

  LocalNotificationService localNotificationService = LocalNotificationService.obtenerInstancia();

  @override
  void initState() {
    super.initState();
    _isAndroidPermissionGranted();
    _requestPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
  }

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted =
          await localNotificationService.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.areNotificationsEnabled() ?? false;

      setState(() {
        _notificationsEnabled = granted;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await localNotificationService.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await localNotificationService.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          localNotificationService.flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission = await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }

  void _configureDidReceiveLocalNotificationSubject() {
    localNotificationService.didReceiveLocalNotificationStream.stream.listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null ? Text(receivedNotification.title!) : null,
          content: receivedNotification.body != null ? Text(receivedNotification.body!) : null,
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => SecondPage(receivedNotification.payload),
                  ),
                );
              },
              child: const Text('Ok'),
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    localNotificationService.selectNotificationStream.stream.listen((String? payload) async {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (BuildContext context) => SecondPage(payload),
      ));
    });
  }

  @override
  void dispose() {
    localNotificationService.didReceiveLocalNotificationStream.close();
    localNotificationService.selectNotificationStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Column(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Text('Tap on a notification when it appears to trigger'
                        ' navigation'),
                  ),
                  InfoValueString(
                    title: 'Did notification launch app?',
                    value: widget.didNotificationLaunchApp,
                  ),
                  if (widget.didNotificationLaunchApp) ...<Widget>[
                    const Text('Launch notification details'),
                    InfoValueString(title: 'Notification id', value: widget.notificationAppLaunchDetails!.notificationResponse?.id),
                    InfoValueString(title: 'Action id', value: widget.notificationAppLaunchDetails!.notificationResponse?.actionId),
                    InfoValueString(title: 'Input', value: widget.notificationAppLaunchDetails!.notificationResponse?.input),
                    InfoValueString(
                      title: 'Payload:',
                      value: widget.notificationAppLaunchDetails!.notificationResponse?.payload,
                    ),
                  ],
                  PaddedElevatedButton(
                    buttonText: 'Show plain notification with payload',
                    onPressed: () async {
                      await localNotificationService.showNotification();
                    },
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Show plain notification that has no title with '
                        'payload',
                    onPressed: () async {
                      await localNotificationService.showNotificationWithNoTitle();
                    },
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Show plain notification that has no body with '
                        'payload',
                    onPressed: () async {
                      await localNotificationService.showNotificationWithNoBody();
                    },
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Show notification with custom sound',
                    onPressed: () async {
                      await localNotificationService.showNotificationCustomSound();
                    },
                  ),
                  if (kIsWeb || !Platform.isLinux) ...<Widget>[
                    PaddedElevatedButton(
                      buttonText: 'Schedule notification to appear in 5 seconds '
                          'based on local time zone',
                      onPressed: () async {
                        await localNotificationService.zonedScheduleNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Schedule notification to appear in 5 seconds '
                          'based on local time zone using alarm clock',
                      onPressed: () async {
                        await localNotificationService.zonedScheduleAlarmClockNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Repeat notification every minute',
                      onPressed: () async {
                        await localNotificationService.repeatNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Schedule daily 10:00:00 am notification in your '
                          'local time zone',
                      onPressed: () async {
                        await localNotificationService.scheduleDailyTenAMNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Schedule daily 10:00:00 am notification in your '
                          "local time zone using last year's date",
                      onPressed: () async {
                        await localNotificationService.scheduleDailyTenAMLastYearNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Schedule weekly 10:00:00 am notification in your '
                          'local time zone',
                      onPressed: () async {
                        await localNotificationService.scheduleWeeklyTenAMNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Schedule weekly Monday 10:00:00 am notification '
                          'in your local time zone',
                      onPressed: () async {
                        await localNotificationService.scheduleWeeklyMondayTenAMNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Check pending notifications',
                      onPressed: () async {
                        await localNotificationService.checkPendingNotificationRequests(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Get active notifications',
                      onPressed: () async {
                        await localNotificationService.getActiveNotifications(context);
                      },
                    ),
                  ],
                  PaddedElevatedButton(
                    buttonText: 'Schedule monthly Monday 10:00:00 am notification in '
                        'your local time zone',
                    onPressed: () async {
                      await localNotificationService.scheduleMonthlyMondayTenAMNotification();
                    },
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Schedule yearly Monday 10:00:00 am notification in '
                        'your local time zone',
                    onPressed: () async {
                      await localNotificationService.scheduleYearlyMondayTenAMNotification();
                    },
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Show notification with no sound',
                    onPressed: () async {
                      await localNotificationService.showNotificationWithNoSound();
                    },
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Cancel latest notification',
                    onPressed: () async {
                      await localNotificationService.cancelNotification();
                    },
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Cancel all notifications',
                    onPressed: () async {
                      await localNotificationService.cancelAllNotifications();
                    },
                  ),
                  const Divider(),
                  const Text(
                    'Notifications with actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  PaddedElevatedButton(
                    buttonText: 'Show notification with plain actions',
                    onPressed: () async {
                      await localNotificationService.showNotificationWithActions();
                    },
                  ),
                  if (Platform.isLinux)
                    PaddedElevatedButton(
                      buttonText: 'Show notification with icon action (if supported)',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithIconAction();
                      },
                    ),
                  if (!Platform.isLinux)
                    PaddedElevatedButton(
                      buttonText: 'Show notification with text action',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithTextAction();
                      },
                    ),
                  if (!Platform.isLinux)
                    PaddedElevatedButton(
                      buttonText: 'Show notification with text choice',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithTextChoice();
                      },
                    ),
                  const Divider(),
                  if (Platform.isAndroid) ...<Widget>[
                    const Text(
                      'Android-specific examples',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('notifications enabled: $_notificationsEnabled'),
                    PaddedElevatedButton(
                      buttonText: 'Check if notifications are enabled for this app',
                      onPressed: () async {
                        await localNotificationService.areNotifcationsEnabledOnAndroid(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Request permission (API 33+)',
                      onPressed: () => _requestPermissions(),
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show plain notification with payload and update '
                          'channel description',
                      onPressed: () async {
                        await localNotificationService.showNotificationUpdateChannelDescription();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show plain notification as public on every '
                          'lockscreen',
                      onPressed: () async {
                        await localNotificationService.showPublicNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with custom vibration pattern, '
                          'red LED and red icon',
                      onPressed: () async {
                        await localNotificationService.showNotificationCustomVibrationIconLed();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification using Android Uri sound',
                      onPressed: () async {
                        await localNotificationService.showSoundUriNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification that times out after 3 seconds',
                      onPressed: () async {
                        await localNotificationService.showTimeoutNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show insistent notification',
                      onPressed: () async {
                        await localNotificationService.showInsistentNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show big picture notification using local images',
                      onPressed: () async {
                        await localNotificationService.showBigPictureNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show big picture notification using base64 String '
                          'for images',
                      onPressed: () async {
                        await localNotificationService.showBigPictureNotificationBase64();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show big picture notification using URLs for '
                          'Images',
                      onPressed: () async {
                        await localNotificationService.showBigPictureNotificationURL();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show big picture notification, hide large icon '
                          'on expand',
                      onPressed: () async {
                        await localNotificationService.showBigPictureNotificationHiddenLargeIcon();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show media notification',
                      onPressed: () async {
                        await localNotificationService.showNotificationMediaStyle();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show big text notification',
                      onPressed: () async {
                        await localNotificationService.showBigTextNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show inbox notification',
                      onPressed: () async {
                        await localNotificationService.showInboxNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show messaging notification',
                      onPressed: () async {
                        await localNotificationService.showMessagingNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show grouped notifications',
                      onPressed: () async {
                        await localNotificationService.showGroupedNotifications();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with tag',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithTag();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Cancel notification with tag',
                      onPressed: () async {
                        await localNotificationService.cancelNotificationWithTag();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show ongoing notification',
                      onPressed: () async {
                        await localNotificationService.showOngoingNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with no badge, alert only once',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithNoBadge();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show progress notification - updates every second',
                      onPressed: () async {
                        await localNotificationService.showProgressNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show indeterminate progress notification',
                      onPressed: () async {
                        await localNotificationService.showIndeterminateProgressNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification without timestamp',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithoutTimestamp();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with custom timestamp',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithCustomTimestamp();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with custom sub-text',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithCustomSubText();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with chronometer',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithChronometer();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show full-screen notification',
                      onPressed: () async {
                        await localNotificationService.showFullScreenNotification(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with number if the launcher '
                          'supports',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithNumber();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with sound controlled by '
                          'alarm volume',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithAudioAttributeAlarm();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Create grouped notification channels',
                      onPressed: () async {
                        await localNotificationService.createNotificationChannelGroup(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Delete notification channel group',
                      onPressed: () async {
                        await localNotificationService.deleteNotificationChannelGroup(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Create notification channel',
                      onPressed: () async {
                        await localNotificationService.createNotificationChannel(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Delete notification channel',
                      onPressed: () async {
                        await localNotificationService.deleteNotificationChannel(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Get notification channels',
                      onPressed: () async {
                        await localNotificationService.getNotificationChannels(context);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Start foreground service',
                      onPressed: () async {
                        await localNotificationService.startForegroundService();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Start foreground service with blue background '
                          'notification',
                      onPressed: () async {
                        await localNotificationService.startForegroundServiceWithBlueBackgroundNotification();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Stop foreground service',
                      onPressed: () async {
                        await localNotificationService.stopForegroundService();
                      },
                    ),
                  ],
                  if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) ...<Widget>[
                    const Text(
                      'iOS and macOS-specific examples',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Request permission',
                      onPressed: _requestPermissions,
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with subtitle',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithSubtitle();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with icon badge',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithIconBadge();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with attachment (with thumbnail)',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithAttachment(hideThumbnail: false);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with attachment (no thumbnail)',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithAttachment(hideThumbnail: true);
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with attachment (clipped thumbnail)',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithClippedThumbnailAttachment();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notifications with thread identifier',
                      onPressed: () async {
                        await localNotificationService.showNotificationsWithThreadIdentifier();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with time sensitive interruption '
                          'level',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithTimeSensitiveInterruptionLevel();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with banner but not in '
                          'notification centre',
                      onPressed: () async {
                        await localNotificationService.showNotificationWithBannerNotInNotificationCentre();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification in notification centre only',
                      onPressed: () async {
                        await localNotificationService.showNotificationInNotificationCentreOnly();
                      },
                    ),
                  ],
                  if (!kIsWeb && Platform.isLinux) ...<Widget>[
                    const Text(
                      'Linux-specific examples',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FutureBuilder<LinuxServerCapabilities>(
                      future: localNotificationService.getLinuxCapabilities(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<LinuxServerCapabilities> snapshot,
                      ) {
                        if (snapshot.hasData) {
                          final LinuxServerCapabilities caps = snapshot.data!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Capabilities of the current system:',
                                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                InfoValueString(
                                  title: 'Body text:',
                                  value: caps.body,
                                ),
                                InfoValueString(
                                  title: 'Hyperlinks in body text:',
                                  value: caps.bodyHyperlinks,
                                ),
                                InfoValueString(
                                  title: 'Images in body:',
                                  value: caps.bodyImages,
                                ),
                                InfoValueString(
                                  title: 'Markup in the body text:',
                                  value: caps.bodyMarkup,
                                ),
                                InfoValueString(
                                  title: 'Animated icons:',
                                  value: caps.iconMulti,
                                ),
                                InfoValueString(
                                  title: 'Static icons:',
                                  value: caps.iconStatic,
                                ),
                                InfoValueString(
                                  title: 'Notification persistence:',
                                  value: caps.persistence,
                                ),
                                InfoValueString(
                                  title: 'Sound:',
                                  value: caps.sound,
                                ),
                                InfoValueString(
                                  title: 'Actions:',
                                  value: caps.actions,
                                ),
                                InfoValueString(
                                  title: 'Action icons:',
                                  value: caps.actionIcons,
                                ),
                                InfoValueString(
                                  title: 'Other capabilities:',
                                  value: caps.otherCapabilities,
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with body markup',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationWithBodyMarkup();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with category',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationWithCategory();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with byte data icon',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationWithByteDataIcon();
                      },
                    ),
                    Builder(
                      builder: (BuildContext context) => PaddedElevatedButton(
                        buttonText: 'Show notification with file path icon',
                        onPressed: () async {
                          final String path = _linuxIconPathController.text;
                          if (path.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter the icon path'),
                              ),
                            );
                            return;
                          }
                          await localNotificationService.showLinuxNotificationWithPathIcon(path);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                      child: TextField(
                        controller: _linuxIconPathController,
                        decoration: InputDecoration(
                          hintText: 'Enter the icon path',
                          constraints: const BoxConstraints.tightFor(
                            width: 300,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _linuxIconPathController.clear(),
                          ),
                        ),
                      ),
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with theme icon',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationWithThemeIcon();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with theme sound',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationWithThemeSound();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with critical urgency',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationWithCriticalUrgency();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification with timeout',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationWithTimeout();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Suppress notification sound',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationSuppressSound();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Transient notification',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationTransient();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Resident notification',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationResident();
                      },
                    ),
                    PaddedElevatedButton(
                      buttonText: 'Show notification on '
                          'different screen location',
                      onPressed: () async {
                        await localNotificationService.showLinuxNotificationDifferentLocation();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
