import 'package:flutter/material.dart';

const Map<int, String> eventTypeMap = {
  1: "Activity Resumed",
  23: "Activity Stopped",
  16: "Screen Non-Interactive",
  18: "Keyguard Hidden",
  15: "Screen Interactive",
  17: "Keyguard Shown",
  2: "Activity Paused",
  19: "Foreground Service Start",
  20: "Foreground Service Stop",
  27: "Device Startup",
  26: "Device Shutdown",
  5: "Configuration Change",
  8: "Shortcut Invocation",
  7: "User Interaction",
};

const List<String> eventTypeForDurationList = [
  "Activity Resumed",
  "Activity Paused",
  "Activity Stopped",
];

const Map<String, String> appNameMap = {
  'com.instagram.android': 'Instagram',
  'com.facebook.katana': 'Facebook',
  'com.facebook.lite': 'Facebook Lite',
  'com.zhiliaoapp.musically': 'TikTok',
  'com.ss.android.ugc.trill': 'TikTok',
  'com.twitter.android': 'X',
  'com.discord': 'Discord',
  'com.google.android.youtube': 'YouTube',
  'com.snapchat.android': 'Snapchat',
  'com.whatsapp': 'WhatsApp',
  'com.reddit.frontpage': 'Reddit',
  'com.pinterest': 'Pinterest',
  'com.linkedin.android': 'LinkedIn',
  'com.tumblr': 'Tumblr',
  'tv.twitch.android.app': 'Twitch',
  'com.spotify.music': 'Spotify',
};

const int minSessionDurationSeconds = 120; // 2 minutes
const int sessionMergeThresholdMinutes = 10; // Merge sessions within 10 minutes