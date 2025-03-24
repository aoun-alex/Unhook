import 'package:flutter/material.dart';
import '../models/alternative_model.dart';

/// Enhanced mapping of package names to detailed app metadata
const Map<String, AppMetadata> appMetadataMap = {
  // Social Media Apps
  'com.instagram.android': AppMetadata(
    displayName: 'Instagram',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'VSCO',
        description: 'Focus on photography without likes and endless scrolling',
        packageName: 'com.vsco.cam',
        icon: Icons.camera_alt,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Photography Walk',
        description: 'Take 20 minutes to capture real-world beauty with your camera',
        isOfflineActivity: true,
        icon: Icons.photo_camera,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Create a Photo Album',
        description: 'Print photos and create a physical album of your favorite memories',
        isOfflineActivity: true,
        icon: Icons.photo_album,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.facebook.katana': AppMetadata(
    displayName: 'Facebook',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Call a Friend',
        description: 'Direct connection is more meaningful than scrolling through updates',
        isOfflineActivity: true,
        icon: Icons.call,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Meetup',
        description: 'Find in-person social events aligned with your interests',
        packageName: 'com.meetup',
        icon: Icons.groups,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Journal',
        description: 'Write down your thoughts instead of posting them online',
        isOfflineActivity: true,
        icon: Icons.book,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.facebook.lite': AppMetadata(
    displayName: 'Facebook Lite',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Community Volunteering',
        description: 'Connect with people while making a difference',
        isOfflineActivity: true,
        icon: Icons.volunteer_activism,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Signal',
        description: 'Privacy-focused messaging with friends and family',
        packageName: 'org.thoughtcrime.securesms',
        icon: Icons.message,
        category: 'App Alternative',
      ),
    ],
  ),

  'com.zhiliaoapp.musically': AppMetadata(
    displayName: 'TikTok',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Learn a Dance',
        description: 'Practice a choreography in real life instead of just watching',
        isOfflineActivity: true,
        icon: Icons.dance_ballroom,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Headspace',
        description: 'Try a quick guided meditation instead of scrolling',
        packageName: 'com.getsomeheadspace.android',
        icon: Icons.self_improvement,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Create Content',
        description: 'Plan and film your own creative content instead of only consuming',
        isOfflineActivity: true,
        icon: Icons.video_camera_back,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.ss.android.ugc.trill': AppMetadata(
    displayName: 'TikTok',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Learn a Dance',
        description: 'Practice a choreography in real life instead of just watching',
        isOfflineActivity: true,
        icon: Icons.dance_ballroom,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Headspace',
        description: 'Try a quick guided meditation instead of scrolling',
        packageName: 'com.getsomeheadspace.android',
        icon: Icons.self_improvement,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Create Content',
        description: 'Plan and film your own creative content instead of only consuming',
        isOfflineActivity: true,
        icon: Icons.video_camera_back,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.ss.android.ugc.tiktok': AppMetadata(
    displayName: 'TikTok',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Learn a Dance',
        description: 'Practice a choreography in real life instead of just watching',
        isOfflineActivity: true,
        icon: Icons.dance_ballroom,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Headspace',
        description: 'Try a quick guided meditation instead of scrolling',
        packageName: 'com.getsomeheadspace.android',
        icon: Icons.self_improvement,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Create Content',
        description: 'Plan and film your own creative content instead of only consuming',
        isOfflineActivity: true,
        icon: Icons.video_camera_back,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.twitter.android': AppMetadata(
    displayName: 'X',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Read a Book',
        description: 'Engage with longer-form content rather than quick takes',
        isOfflineActivity: true,
        icon: Icons.menu_book,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Pocket',
        description: 'Save and read thoughtful articles when you have time',
        packageName: 'com.ideashower.readitlater.pro',
        icon: Icons.bookmark,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Write in a Journal',
        description: 'Express your thoughts privately instead of tweeting',
        isOfflineActivity: true,
        icon: Icons.edit_note,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.twitter.lite': AppMetadata(
    displayName: 'X Lite',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Read a Book',
        description: 'Engage with longer-form content rather than quick takes',
        isOfflineActivity: true,
        icon: Icons.menu_book,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Pocket',
        description: 'Save and read thoughtful articles when you have time',
        packageName: 'com.ideashower.readitlater.pro',
        icon: Icons.bookmark,
        category: 'App Alternative',
      ),
    ],
  ),

  // Communication Apps
  'com.discord': AppMetadata(
    displayName: 'Discord',
    category: AppCategories.messaging,
    alternatives: [
      Alternative(
        title: 'In-Person Game Night',
        description: 'Organize a board game night with friends',
        isOfflineActivity: true,
        icon: Icons.casino,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Scheduled Voice Calls',
        description: 'Have focused conversations instead of constant checking',
        isOfflineActivity: true,
        icon: Icons.schedule_send,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.whatsapp': AppMetadata(
    displayName: 'WhatsApp',
    category: AppCategories.messaging,
    alternatives: [
      Alternative(
        title: 'Set Communication Hours',
        description: 'Dedicate specific times for checking messages',
        isOfflineActivity: true,
        icon: Icons.schedule,
        category: 'Habit Change',
      ),
      Alternative(
        title: 'Write a Letter',
        description: 'Craft a thoughtful, physical letter to someone you care about',
        isOfflineActivity: true,
        icon: Icons.mail,
        category: 'Offline Activity',
      ),
    ],
  ),

  // Entertainment Apps
  'com.google.android.youtube': AppMetadata(
    displayName: 'YouTube',
    category: AppCategories.entertainment,
    alternatives: [
      Alternative(
        title: 'Spotify Podcasts',
        description: 'Listen to podcasts while moving around instead of watching videos',
        packageName: 'com.spotify.music',
        icon: Icons.podcasts,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Audiobooks',
        description: 'Try an audiobook for more structured content consumption',
        packageName: 'com.audible.application',
        icon: Icons.menu_book,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Learn a Skill',
        description: 'Practice a skill instead of watching others do it',
        isOfflineActivity: true,
        icon: Icons.construction,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.google.android.apps.youtube.music': AppMetadata(
    displayName: 'YouTube Music',
    category: AppCategories.entertainment,
    alternatives: [
      Alternative(
        title: 'Play an Instrument',
        description: 'Practice playing music instead of only listening',
        isOfflineActivity: true,
        icon: Icons.piano,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Attend a Concert',
        description: 'Experience music live for a more engaging experience',
        isOfflineActivity: true,
        icon: Icons.music_note,
        category: 'Offline Activity',
      ),
    ],
  ),

  'tv.twitch.android.app': AppMetadata(
    displayName: 'Twitch',
    category: AppCategories.entertainment,
    alternatives: [
      Alternative(
        title: 'Play the Game',
        description: 'Play the games you watch others play',
        isOfflineActivity: true,
        icon: Icons.sports_esports,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Game with Friends',
        description: 'Organize a multiplayer session with friends',
        isOfflineActivity: true,
        icon: Icons.group,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Learn Game Development',
        description: 'Start creating your own game with beginner-friendly tools',
        packageName: 'com.unity3d.unityhub',
        icon: Icons.code,
        category: 'Skill Building',
      ),
    ],
  ),

  'com.spotify.music': AppMetadata(
    displayName: 'Spotify',
    category: AppCategories.entertainment,
    alternatives: [
      Alternative(
        title: 'Create a Playlist',
        description: 'Curate a thoughtful playlist instead of endless shuffling',
        packageName: 'com.spotify.music',
        icon: Icons.playlist_add,
        category: 'Mindful Usage',
      ),
      Alternative(
        title: 'Learn an Instrument',
        description: 'Create music instead of only consuming it',
        isOfflineActivity: true,
        icon: Icons.music_note,
        category: 'Offline Activity',
      ),
    ],
  ),

  // More Social Apps
  'com.snapchat.android': AppMetadata(
    displayName: 'Snapchat',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Open Camera',
        description: 'Take proper photos to keep and share more meaningfully',
        isOfflineActivity: true,
        icon: Icons.camera,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Video Call',
        description: 'Have a real-time conversation instead of asynchronous snaps',
        isOfflineActivity: true,
        icon: Icons.video_call,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.reddit.frontpage': AppMetadata(
    displayName: 'Reddit',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Curated News Apps',
        description: 'Try apps that provide curated, high-quality content',
        packageName: 'com.apple.news',
        icon: Icons.newspaper,
        category: 'App Alternative',
      ),
      Alternative(
        title: 'Subscribe to a Newsletter',
        description: 'Get curated content delivered on a schedule',
        isOfflineActivity: true,
        icon: Icons.mail,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Join a Club',
        description: 'Engage with people who share your interests in person',
        isOfflineActivity: true,
        icon: Icons.groups,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.pinterest': AppMetadata(
    displayName: 'Pinterest',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Create a Vision Board',
        description: 'Make a physical collage of ideas and inspiration',
        isOfflineActivity: true,
        icon: Icons.dashboard,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Try a DIY Project',
        description: 'Actually make something you\'ve saved instead of just collecting ideas',
        isOfflineActivity: true,
        icon: Icons.build,
        category: 'Offline Activity',
      ),
    ],
  ),

  'com.linkedin.android': AppMetadata(
    displayName: 'LinkedIn',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Professional Meetup',
        description: 'Attend industry events for in-person networking',
        isOfflineActivity: true,
        icon: Icons.business,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Skill Development',
        description: 'Take time to learn new professional skills instead of browsing',
        packageName: 'com.linkedin.learning',
        icon: Icons.school,
        category: 'App Alternative',
      ),
    ],
  ),

  'com.tumblr': AppMetadata(
    displayName: 'Tumblr',
    category: AppCategories.socialMedia,
    alternatives: [
      Alternative(
        title: 'Start a Blog',
        description: 'Write long-form content on a personal website or journaling platform',
        isOfflineActivity: true,
        icon: Icons.article,
        category: 'Offline Activity',
      ),
      Alternative(
        title: 'Notion',
        description: 'Use Notion for creative writing or inspiration boards',
        packageName: 'notion.id',
        icon: Icons.note,
        category: 'App Alternative',
      ),
    ],
  ),

  // Extend with more apps as needed
};