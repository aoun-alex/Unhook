
const Map<int, String> eventTypeMap = {
  1: "Activity Resumed",
  2: "Activity Paused",
  3: "Activity Stopped",
  4: "Activity Destroyed",
  5: "Configuration Change",
  6: "Activity Restarted",
  7: "User Interaction",
  8: "Shortcut Invocation",
  9: "Device Wakeup",
  10: "User Present",
  11: "Package Uninstalled",
  12: "Package Installed",
  13: "Package Replaced",
  14: "Package Suspended",
  15: "Screen Interactive",
  16: "Screen Non-Interactive",
  17: "Keyguard Shown",
  18: "Keyguard Hidden",
  19: "Foreground Service Start",
  20: "Foreground Service Stop",
  21: "System Interaction",
  22: "User Stopped",
  23: "Activity Stopped",
  24: "Device Shutdown",
  25: "Device Idle",
  26: "Device Shutdown",
  27: "Device Startup",
};

const List<String> eventTypeForDurationList = [
  "Activity Resumed",
  "Activity Paused",
  "Activity Stopped",
  "User Interaction",
  "Screen Interactive",
  "Foreground Service Start",
  "Foreground Service Stop",
];

const Map<String, String> appNameMap = {
  'com.instagram.android': 'Instagram',
  'com.facebook.katana': 'Facebook',
  'com.facebook.lite': 'Facebook Lite',

  'com.zhiliaoapp.musically': 'TikTok',
  'com.ss.android.ugc.trill': 'TikTok',
  'com.ss.android.ugc.tiktok': 'TikTok',

  'com.twitter.android': 'X',
  'com.twitter.lite': 'X Lite',

  'com.discord': 'Discord',
  'com.whatsapp': 'WhatsApp',
  'com.whatsapp.w4b': 'WhatsApp Business',

  'com.google.android.youtube': 'YouTube',
  'com.google.android.apps.youtube.music': 'YouTube Music',
  'tv.twitch.android.app': 'Twitch',
  'com.spotify.music': 'Spotify',

  'com.snapchat.android': 'Snapchat',
  'com.reddit.frontpage': 'Reddit',
  'reddit.news': 'Reddit',
  'com.pinterest': 'Pinterest',
  'com.pinterest.twa': 'Pinterest',
  'com.asus.pinterest': 'Pinterest',
  'com.linkedin.android': 'LinkedIn',
  'com.tumblr': 'Tumblr',

};

const int minSessionDurationSeconds = 60;
const int sessionMergeThresholdMinutes = 10;