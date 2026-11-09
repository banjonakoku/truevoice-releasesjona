import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await TrueVoiceStore.instance.load();
  runApp(const TrueVoiceApp());
}

// ============================================================
// STORE
// ============================================================

class TrueVoiceStore extends ChangeNotifier {
  TrueVoiceStore._();

  static final TrueVoiceStore instance = TrueVoiceStore._();

  final ImagePicker picker = ImagePicker();

  List<CommunityPost> posts = [];
  List<Group> groups = [];
  List<Appointment> appointments = [];
  List<FreelanceService> freelanceServices = [];

  final Set<String> connections = {};
  final Set<String> incomingRequests = {};
  final Set<String> sentRequests = {};

  final Set<String> blockedUsers = {};
  final Set<String> likedTopics = {};
  final Set<String> savedPostIds = {};

  String userName = 'Jonathan Bansah';
  String userProfession = 'Healthcare Student';
  String userLocation = 'Worldwide';
  String userBio =
      'Learning, connecting and growing in healthcare.';

  String? profileImagePath;

  bool notificationsEnabled = true;
  bool privateProfile = false;
  bool allowMessages = true;
  bool showOnlineStatus = true;

  String languageCode = '';
  bool loaded = false;
  bool hasSeenOnboarding = false;
    VerificationRequest? myVerificationRequest;
  final List<VerificationRequest> pendingVerifications = [];
  final List<AppNotification> notifications = [];
  bool isVerified = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    userName = prefs.getString('userName') ?? userName;
    userProfession =
        prefs.getString('userProfession') ?? userProfession;
    userLocation =
        prefs.getString('userLocation') ?? userLocation;
    userBio = prefs.getString('userBio') ?? userBio;
    profileImagePath = prefs.getString('profileImagePath');

    notificationsEnabled =
        prefs.getBool('notificationsEnabled') ?? true;
    privateProfile =
        prefs.getBool('privateProfile') ?? false;
    allowMessages =
        prefs.getBool('allowMessages') ?? true;
    showOnlineStatus =
        prefs.getBool('showOnlineStatus') ?? true;

    languageCode = prefs.getString('languageCode') ?? '';
    hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
        isVerified = prefs.getBool('isVerified') ?? false;

    final myVerificationData = prefs.getString('myVerificationRequest');
    if (myVerificationData != null) {
      myVerificationRequest = VerificationRequest.fromMap(
        jsonDecode(myVerificationData) as Map<String, dynamic>,
      );
    }

    
    final notifData = prefs.getString('notifications');
    if (notifData != null) {
      final decoded = jsonDecode(notifData) as List<dynamic>;
      notifications
        ..clear()
        ..addAll(
          decoded.map((item) => AppNotification.fromMap(
                item as Map<String, dynamic>,
              )),
        );
    }
        if (notifications.isEmpty ||
        notifications.length < 5) {
      notifications
        ..clear()
        ..addAll(demoNotifications());
    }

    final postData = prefs.getString('posts');
    if (postData != null) {
      final decoded = jsonDecode(postData) as List<dynamic>;
      posts = decoded
          .map((item) => CommunityPost.fromMap(
                item as Map<String, dynamic>,
              ))
          .toList();
    }

    final groupData = prefs.getString('groups');
    if (groupData != null) {
      final decoded = jsonDecode(groupData) as List<dynamic>;
      groups = decoded
          .map((item) => Group.fromMap(
                item as Map<String, dynamic>,
              ))
          .toList();
    }

    final appointmentData = prefs.getString('appointments');
    if (appointmentData != null) {
      final decoded =
          jsonDecode(appointmentData) as List<dynamic>;
      appointments = decoded
          .map((item) => Appointment.fromMap(
                item as Map<String, dynamic>,
              ))
          .toList();
    }

    final freelanceData = prefs.getString('freelanceServices');
    if (freelanceData != null) {
      final decoded =
          jsonDecode(freelanceData) as List<dynamic>;
      freelanceServices = decoded
          .map((item) => FreelanceService.fromMap(
                item as Map<String, dynamic>,
              ))
          .toList();
    }

    connections
      ..clear()
      ..addAll(prefs.getStringList('connections') ?? []);

    incomingRequests
      ..clear()
      ..addAll(prefs.getStringList('incomingRequests') ?? []);

    sentRequests
      ..clear()
      ..addAll(prefs.getStringList('sentRequests') ?? []);

    blockedUsers
      ..clear()
      ..addAll(prefs.getStringList('blockedUsers') ?? []);

    savedPostIds
      ..clear()
      ..addAll(prefs.getStringList('savedPostIds') ?? []);

    likedTopics
      ..clear()
      ..addAll(prefs.getStringList('likedTopics') ?? []);

    if (posts.isEmpty) posts = demoPosts();
    if (groups.isEmpty) groups = demoGroups();
    if (freelanceServices.isEmpty) {
      freelanceServices = demoFreelanceServices();
    }

    loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'posts',
      jsonEncode(posts.map((p) => p.toMap()).toList()),
    );
    await prefs.setString(
      'groups',
      jsonEncode(groups.map((g) => g.toMap()).toList()),
    );
    await prefs.setString(
      'appointments',
      jsonEncode(
        appointments.map((a) => a.toMap()).toList(),
      ),
    );
    await prefs.setString(
      'freelanceServices',
      jsonEncode(
        freelanceServices.map((f) => f.toMap()).toList(),
      ),
    );

    await prefs.setStringList('connections', connections.toList());
    await prefs.setStringList(
      'incomingRequests',
      incomingRequests.toList(),
    );
    await prefs.setStringList(
      'sentRequests',
      sentRequests.toList(),
    );
    await prefs.setStringList(
      'blockedUsers',
      blockedUsers.toList(),
    );
    await prefs.setStringList(
      'savedPostIds',
      savedPostIds.toList(),
    );
    await prefs.setStringList(
      'likedTopics',
      likedTopics.toList(),
    );

    await prefs.setString('userName', userName);
    await prefs.setString('userProfession', userProfession);
    await prefs.setString('userLocation', userLocation);
    await prefs.setString('userBio', userBio);
    await prefs.setString('languageCode', languageCode);

    if (profileImagePath != null) {
      await prefs.setString(
        'profileImagePath',
        profileImagePath!,
      );
    }

    await prefs.setBool(
      'notificationsEnabled',
      notificationsEnabled,
    );
    await prefs.setBool('privateProfile', privateProfile);
    await prefs.setBool('allowMessages', allowMessages);
    await prefs.setBool(
      'showOnlineStatus',
      showOnlineStatus,
    );
      await prefs.setBool(
      'showOnlineStatus',
      showOnlineStatus,
    );

    await prefs.setBool('isVerified', isVerified);
     await prefs.setBool('hasSeenOnboarding', hasSeenOnboarding);

    if (myVerificationRequest != null) {
      await prefs.setString(
        'myVerificationRequest',
        jsonEncode(myVerificationRequest!.toMap()),
      );
    }

    await prefs.setString(
      'pendingVerifications',
      jsonEncode(
        pendingVerifications.map((v) => v.toMap()).toList(),
      ),
    );
    
    await prefs.setString(
      'notifications',
      jsonEncode(
        notifications.map((n) => n.toMap()).toList(),
      ),
    );
  }

  // ---------- POSTS ----------

  void addPost(CommunityPost post) {
    posts.insert(0, post);
    save();
    notifyListeners();
  }

  void deletePost(String id) {
    posts.removeWhere((post) => post.id == id);
    savedPostIds.remove(id);
    save();
    notifyListeners();
  }

  void updatePost(CommunityPost updated) {
    final index = posts.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      posts[index] = updated;
      save();
      notifyListeners();
    }
  }

  void toggleLike(CommunityPost post) {
    post.liked = !post.liked;
    if (post.liked) {
      post.likes++;
      likedTopics.addAll(post.topics);
    } else {
      post.likes = post.likes > 0 ? post.likes - 1 : 0;
    }
    save();
    notifyListeners();
  }

  void toggleSave(CommunityPost post) {
    post.saved = !post.saved;
    if (post.saved) {
      savedPostIds.add(post.id);
    } else {
      savedPostIds.remove(post.id);
    }
    save();
    notifyListeners();
  }

  // ---------- COMMENTS ----------

  void addComment(
    CommunityPost post,
    String text, {
    String? parentId,
  }) {
    post.comments.add(
      Comment(
        id: newId(),
        author: userName,
        content: text,
        time: 'Just now',
        isOwnComment: true,
        parentId: parentId,
      ),
    );
    likedTopics.addAll(post.topics);
    save();
    notifyListeners();
  }

  void deleteComment(
    CommunityPost post,
    String commentId,
  ) {
    post.comments.removeWhere((c) => c.id == commentId);
    post.comments.removeWhere((c) => c.parentId == commentId);
    save();
    notifyListeners();
  }

  void reactToComment(
    CommunityPost post,
    String commentId,
    String emoji,
  ) {
    for (final c in post.comments) {
      if (c.id == commentId) {
        c.reactions[emoji] = (c.reactions[emoji] ?? 0) + 1;
        save();
        notifyListeners();
        return;
      }
    }
  }

  // ---------- CONNECTIONS ----------

  void sendConnectionRequest(String name) {
    if (connections.contains(name)) return;
    if (sentRequests.contains(name)) return;
    sentRequests.add(name);
    save();
    notifyListeners();
  }

  void approveConnection(String name) {
    incomingRequests.remove(name);
    connections.add(name);
    save();
    notifyListeners();
  }

  void denyConnection(String name) {
    incomingRequests.remove(name);
    save();
    notifyListeners();
  }

  void cancelConnectionRequest(String name) {
    sentRequests.remove(name);
    save();
    notifyListeners();
  }

  void simulateIncomingRequest(String name) {
    if (!connections.contains(name) &&
        !incomingRequests.contains(name) &&
        name != userName) {
      incomingRequests.add(name);
      save();
      notifyListeners();
    }
  }

  void block(String name) {
    blockedUsers.add(name);
    connections.remove(name);
    incomingRequests.remove(name);
    sentRequests.remove(name);
    save();
    notifyListeners();
  }

  void unblock(String name) {
    blockedUsers.remove(name);
    save();
    notifyListeners();
  }

  // ---------- APPOINTMENTS ----------

  void addAppointment(Appointment appointment) {
    appointments.add(appointment);
    save();
    notifyListeners();
  }

  void cancelAppointment(Appointment appointment) {
    appointment.status = 'Cancelled';
    save();
    notifyListeners();
  }

  void updateAppointmentStatus(
    Appointment appointment,
    String status,
  ) {
    appointment.status = status;
    save();
    notifyListeners();
  }

  // ---------- GROUPS ----------

  void createGroup(Group group) {
    groups.insert(0, group);
    save();
    notifyListeners();
  }

  void joinGroup(Group group) {
    if (group.verificationRequired) {
      if (!group.pendingMembers.contains(userName)) {
        group.pendingMembers.add(userName);
      }
    } else {
      if (!group.members.contains(userName)) {
        group.members.add(userName);
      }
    }
    save();
    notifyListeners();
  }

  void approveMember(Group group, String name) {
    group.pendingMembers.remove(name);
    if (!group.members.contains(name)) {
      group.members.add(name);
    }
    save();
    notifyListeners();
  }

  
  void deleteGroup(Group group) {
    groups.removeWhere((g) => g.id == group.id);
    posts.removeWhere((p) => p.groupId == group.id);
    save();
    notifyListeners();
  }

  void leaveGroup(Group group) {
    group.members.remove(userName);
    group.pendingMembers.remove(userName);
    save();
    notifyListeners();
  }

  void addGroupMessage(Group group, GroupMessage msg) {
    group.messages.add(msg);
    save();
    notifyListeners();
  }

  
  void removeGroupMessage(Group group, String messageId) {
    group.messages.removeWhere((m) => m.id == messageId);
    save();
    notifyListeners();
  }

  void addGroupPost(Group group, CommunityPost post) {
    post.groupId = group.id;
    posts.insert(0, post);
    save();
    notifyListeners();
  }

  List<CommunityPost> postsForGroup(String groupId) {
    return posts.where((p) => p.groupId == groupId).toList();
  }

  // ---------- RECOMMENDATIONS ----------

  List<CommunityPost> recommendedPosts() {
    if (likedTopics.isEmpty) {
      return posts.take(3).toList();
    }
    final sorted = [...posts];
    sorted.sort((a, b) {
      final aScore =
          a.topics.where(likedTopics.contains).length;
      final bScore =
          b.topics.where(likedTopics.contains).length;
      return bScore.compareTo(aScore);
    });
    return sorted.take(3).toList();
  }

  // ---------- PROFILE / SETTINGS ----------

  void updateProfile({
    required String name,
    required String profession,
    required String location,
    required String bio,
  }) {
    userName = name;
    userProfession = profession;
    userLocation = location;
    userBio = bio;
    save();
    notifyListeners();
  }

  void setProfileImage(String path) {
    profileImagePath = path;
    save();
    notifyListeners();
  }

  void setNotifications(bool value) {
    notificationsEnabled = value;
    save();
    notifyListeners();
  }

  void setOnlineStatus(bool value) {
    showOnlineStatus = value;
    save();
    notifyListeners();
  }

  void setAllowMessages(bool value) {
    allowMessages = value;
    save();
    notifyListeners();
  }

  void setPrivateProfile(bool value) {
    privateProfile = value;
    save();
    notifyListeners();
  }

  void setLanguage(String value) {
    languageCode = value;
    save();
    notifyListeners();
  }

  
  void completeOnboarding() {
    hasSeenOnboarding = true;
    save();
    notifyListeners();
  }
  
  void submitVerification(VerificationRequest request) {
    myVerificationRequest = request;
    pendingVerifications.add(request);
    save();
    notifyListeners();
  }

  void approveVerification(String id) {
    final index = pendingVerifications.indexWhere((v) => v.id == id);
    if (index == -1) return;
    pendingVerifications[index].status = 'Approved';
    if (myVerificationRequest?.id == id) {
      myVerificationRequest!.status = 'Approved';
      isVerified = true;
    }
    save();
    notifyListeners();
  }

  void rejectVerification(String id) {
    final index = pendingVerifications.indexWhere((v) => v.id == id);
    if (index == -1) return;
    pendingVerifications[index].status = 'Rejected';
    if (myVerificationRequest?.id == id) {
      myVerificationRequest!.status = 'Rejected';
      isVerified = false;
    }
    save();
    notifyListeners();
  }

  
  int get unreadNotificationCount =>
      notifications.where((n) => !n.read).length;

  void markNotificationRead(String id) {
    for (final n in notifications) {
      if (n.id == id) {
        n.read = true;
        break;
      }
    }
    save();
    notifyListeners();
  }

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n.read = true;
    }
    save();
    notifyListeners();
  }

  void addNotification(AppNotification n) {
    notifications.insert(0, n);
    save();
    notifyListeners();
  }

  
  void deleteDmMessage(ChatMessage msg) {
    // No store holds DM messages currently — DMs live in ChatPage state.
  }

  void addFreelanceService(FreelanceService service) {
    freelanceServices.insert(0, service);
    save();
    notifyListeners();
  }

  String newId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}

// ============================================================
// MODELS
// ============================================================

class Comment {
  Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.time,
    this.isOwnComment = false,
    this.parentId,
    Map<String, int>? reactions,
  }) : reactions = reactions ?? {};

  final String id;
  final String author;
  final String content;
  final String time;
  bool isOwnComment;
  String? parentId;
  Map<String, int> reactions;

  Map<String, dynamic> toMap() => {
        'id': id,
        'author': author,
        'content': content,
        'time': time,
        'isOwnComment': isOwnComment,
        'parentId': parentId,
        'reactions': reactions,
      };

  factory Comment.fromMap(Map<String, dynamic> map) {
    final rawReactions = map['reactions'];
    final reactions = <String, int>{};
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        reactions[k.toString()] =
            v is int ? v : int.tryParse('$v') ?? 0;
      });
    }
    return Comment(
      id: map['id'] as String,
      author: map['author'] as String,
      content: map['content'] as String,
      time: map['time'] as String,
      isOwnComment: map['isOwnComment'] as bool? ?? false,
      parentId: map['parentId'] as String?,
      reactions: reactions,
    );
  }
}

class CommunityPost {
  CommunityPost({
    required this.id,
    required this.name,
    required this.profession,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
    required this.topics,
    this.liked = false,
    this.saved = false,
    this.commentsEnabled = true,
    this.mediaPath,
    this.mediaType,
    this.groupId,
  });

  final String id;
  String name;
  String profession;
  String time;
  String content;
  int likes;
  List<Comment> comments;
  List<String> topics;
  bool liked;
  bool saved;
  bool commentsEnabled;
  String? mediaPath;
  String? mediaType;
  String? groupId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'profession': profession,
        'time': time,
        'content': content,
        'likes': likes,
        'comments': comments.map((e) => e.toMap()).toList(),
        'topics': topics,
        'liked': liked,
        'saved': saved,
        'commentsEnabled': commentsEnabled,
        'mediaPath': mediaPath,
        'mediaType': mediaType,
        'groupId': groupId,
      };

  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      id: map['id'] as String,
      name: map['name'] as String,
      profession: map['profession'] as String,
      time: map['time'] as String,
      content: map['content'] as String,
      likes: map['likes'] as int? ?? 0,
      comments: (map['comments'] as List<dynamic>? ?? [])
          .map((item) => Comment.fromMap(
                item as Map<String, dynamic>,
              ))
          .toList(),
      topics: List<String>.from(
        map['topics'] as List<dynamic>? ?? [],
      ),
      liked: map['liked'] as bool? ?? false,
      saved: map['saved'] as bool? ?? false,
      commentsEnabled:
          map['commentsEnabled'] as bool? ?? true,
      mediaPath: map['mediaPath'] as String?,
      mediaType: map['mediaType'] as String?,
      groupId: map['groupId'] as String?,
    );
  }
}

class GroupMessage {
  GroupMessage({
    required this.id,
    required this.author,
    required this.content,
    required this.time,
    this.isAudio = false,
    this.audioPath,
    Map<String, int>? reactions,
  }) : reactions = reactions ?? {};

  final String id;
  final String author;
  final String content;
  final String time;
  final bool isAudio;
  final String? audioPath;
  Map<String, int> reactions;

  Map<String, dynamic> toMap() => {
        'id': id,
        'author': author,
        'content': content,
        'time': time,
        'isAudio': isAudio,
        'audioPath': audioPath,
        'reactions': reactions,
      };

  factory GroupMessage.fromMap(Map<String, dynamic> map) {
    final rawReactions = map['reactions'];
    final reactions = <String, int>{};
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        reactions[k.toString()] =
            v is int ? v : int.tryParse('$v') ?? 0;
      });
    }
    return GroupMessage(
      id: map['id'] as String,
      author: map['author'] as String,
      content: map['content'] as String,
      time: map['time'] as String,
      isAudio: map['isAudio'] as bool? ?? false,
      audioPath: map['audioPath'] as String?,
      reactions: reactions,
    );
  }
}

class Group {
  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rules,
    required this.adminName,
    required this.verificationRequired,
    required this.members,
    required this.pendingMembers,
    List<GroupMessage>? messages,
  }) : messages = messages ?? [];

  final String id;
  final String name;
  final String description;
  final String category;
  final String rules;
  final String adminName;
  final bool verificationRequired;
  final List<String> members;
  final List<String> pendingMembers;
  List<GroupMessage> messages;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'rules': rules,
        'adminName': adminName,
        'verificationRequired': verificationRequired,
        'members': members,
        'pendingMembers': pendingMembers,
        'messages': messages.map((m) => m.toMap()).toList(),
      };

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      rules: map['rules'] as String,
      adminName: map['adminName'] as String,
      verificationRequired:
          map['verificationRequired'] as bool? ?? false,
      members: List<String>.from(
        map['members'] as List<dynamic>? ?? [],
      ),
      pendingMembers: List<String>.from(
        map['pendingMembers'] as List<dynamic>? ?? [],
      ),
      messages: (map['messages'] as List<dynamic>? ?? [])
          .map((item) => GroupMessage.fromMap(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }
}

class Service {
  const Service({
    required this.name,
    required this.price,
  });

  final String name;
  final double price;
}

class WorkingHours {
  const WorkingHours({
    required this.startHour,
    required this.endHour,
    this.daysOfWeek = const [1, 2, 3, 4, 5],
  });

  final int startHour;
  final int endHour;
  final List<int> daysOfWeek;

  bool isWithin(DateTime date, TimeOfDay time) {
    if (!daysOfWeek.contains(date.weekday)) return false;
    return time.hour >= startHour && time.hour < endHour;
  }

  String get label {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = daysOfWeek
        .map((d) => dayNames[(d - 1) % 7])
        .join(', ');
    return '$days · ${startHour.toString().padLeft(2, '0')}:00 – ${endHour.toString().padLeft(2, '0')}:00';
  }

  Map<String, dynamic> toMap() => {
        'startHour': startHour,
        'endHour': endHour,
        'daysOfWeek': daysOfWeek,
      };

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      startHour: map['startHour'] as int? ?? 8,
      endHour: map['endHour'] as int? ?? 17,
      daysOfWeek: List<int>.from(
        map['daysOfWeek'] as List<dynamic>? ?? [1, 2, 3, 4, 5],
      ),
    );
  }
}

class Appointment {
  Appointment({
    required this.id,
    required this.professional,
    required this.profession,
    required this.service,
    required this.date,
    required this.time,
    this.status = 'Upcoming',
    this.facility,
  });

  final String id;
  final String professional;
  final String profession;
  final String service;
  final DateTime date;
  final TimeOfDay time;
  String status;
  final String? facility;

  Map<String, dynamic> toMap() => {
        'id': id,
        'professional': professional,
        'profession': profession,
        'service': service,
        'date': date.toIso8601String(),
        'timeHour': time.hour,
        'timeMinute': time.minute,
        'status': status,
        'facility': facility,
      };

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      professional: map['professional'] as String,
      profession: map['profession'] as String,
      service: map['service'] as String,
      date: DateTime.parse(map['date'] as String),
      time: TimeOfDay(
        hour: map['timeHour'] as int? ?? 9,
        minute: map['timeMinute'] as int? ?? 0,
      ),
      status: map['status'] as String? ?? 'Upcoming',
      facility: map['facility'] as String?,
    );
  }
}

class Professional {
  const Professional({
    required this.name,
    required this.profession,
    required this.location,
    required this.bio,
    required this.services,
    this.verified = false,
    this.workingHours = const WorkingHours(
      startHour: 8,
      endHour: 17,
    ),
  });

  final String name;
  final String profession;
  final String location;
  final String bio;
  final List<Service> services;
  final bool verified;
  final WorkingHours workingHours;
}

class Facility {
  const Facility({
    required this.name,
    required this.type,
    required this.location,
    required this.address,
    required this.hours,
    required this.phone,
    required this.email,
    required this.services,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String type;
  final String location;
  final String address;
  final String hours;
  final String phone;
  final String email;
  final List<Service> services;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates =>
      latitude != null && longitude != null;

  String get mapsUrl {
    if (hasCoordinates) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
  }
}

class FreelanceService {
  FreelanceService({
    required this.id,
    required this.providerName,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.location,
    this.address,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String providerName;
  final String title;
  final String description;
  final String category;
  final double price;
  final String location;
  final String? address;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates =>
      latitude != null && longitude != null;

  String get mapsUrl {
    if (hasCoordinates) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address ?? location)}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'providerName': providerName,
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'location': location,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory FreelanceService.fromMap(Map<String, dynamic> map) {
    return FreelanceService(
      id: map['id'] as String,
      providerName: map['providerName'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      location: map['location'] as String,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

// ============================================================
// DEMO COMMUNITY DATA
// ============================================================

List<CommunityPost> demoPosts() {
  return [
    CommunityPost(
      id: 'health1',
      name: 'Dr. Sarah Mensah',
      profession: 'General Practitioner',
      time: '15m',
      content:
          'Stroke awareness matters. Knowing the warning signs and seeking emergency care quickly can make a major difference. Health education should empower people to act early.',
      likes: 86,
      topics: ['Health Education', 'Stroke', 'Emergency Care'],
      comments: [
        Comment(
          id: 'hc1',
          author: 'Michael Addo',
          content:
              'Health education like this is extremely important.',
          time: '8m',
        ),
      ],
    ),
    CommunityPost(
      id: 'health2',
      name: 'Ama Boateng',
      profession: 'Speech & Language Therapist',
      time: '42m',
      content:
          'What does a speech-language therapist actually do? We support communication, speech, language, voice, fluency and swallowing across different stages of life. Communication is healthcare.',
      likes: 74,
      topics: ['Speech Therapy', 'Communication', 'Healthcare'],
      comments: [],
    ),
    CommunityPost(
      id: 'health3',
      name: 'Dr. Kwame Asare',
      profession: 'Audiologist',
      time: '1h',
      content:
          'When was the last time you had your hearing checked? Hearing health is often overlooked because hearing changes can happen gradually.',
      likes: 63,
      topics: ['Audiology', 'Hearing Health', 'Prevention'],
      comments: [],
    ),
    CommunityPost(
      id: 'health4',
      name: 'Akosua Owusu',
      profession: 'Psychologist',
      time: '2h',
      content:
          'Mental health conversations should not only happen during a crisis. Asking for support early is a strength, not a weakness.',
      likes: 91,
      topics: ['Mental Health', 'Wellbeing'],
      comments: [],
    ),
    CommunityPost(
      id: 'health5',
      name: 'Michael Addo',
      profession: 'Physiotherapist',
      time: '3h',
      content:
          'Healthcare works best when professionals collaborate. A patient may need several different professionals working toward the same goal.',
      likes: 58,
      topics: ['Healthcare', 'Teamwork', 'Rehabilitation'],
      comments: [],
    ),
    CommunityPost(
      id: 'health6',
      name: 'TrueVoice Community',
      profession: 'Health Education',
      time: '5h',
      content:
          'Question for the community: What is one healthcare topic you wish people understood better?',
      likes: 112,
      topics: ['Health Education', 'Community', 'Discussion'],
      comments: [],
    ),
    CommunityPost(
      id: 'health7',
      name: 'Nurse Akua Mensah',
      profession: 'Registered Nurse',
      time: '6h',
      content:
          'Home nursing tip: keep a small notebook with all medications, dosages and times. When a family member or doctor asks, you can answer in seconds.',
      likes: 67,
      topics: ['Nursing', 'Home Care', 'Caregiving'],
      comments: [],
    ),
    CommunityPost(
      id: 'health8',
      name: 'Dr. Fatima Al-Hassan',
      profession: 'Dentist',
      time: '8h',
      content:
          'Brushing twice a day is good. Brushing twice a day AND flossing once is what actually prevents gum disease. Flossing is the difference.',
      likes: 143,
      topics: ['Dentistry', 'Prevention', 'Oral Health'],
      comments: [],
    ),
    CommunityPost(
      id: 'health9',
      name: 'Kwesi Amankwah',
      profession: 'Pharmacist',
      time: '10h',
      content:
          'Reminder: antibiotics do not treat colds or flu. They treat bacterial infections. Taking them unnecessarily makes them less effective when you really need them.',
      likes: 189,
      topics: ['Pharmacy', 'Antibiotics', 'Public Health'],
      comments: [],
    ),
    CommunityPost(
      id: 'health10',
      name: 'Grace Mwangi',
      profession: 'Dietitian',
      time: '12h',
      content:
          'You do not need to cut out entire food groups to be healthy. Small, consistent changes beat drastic diets every time.',
      likes: 156,
      topics: ['Nutrition', 'Wellbeing', 'Health Education'],
      comments: [],
    ),
    CommunityPost(
      id: 'health11',
      name: 'Dr. Rohan Mehta',
      profession: 'General Practitioner',
      time: '1d',
      content:
          'Preventive care is not expensive — it is the cheapest form of healthcare. Annual check-ups catch problems long before they become emergencies.',
      likes: 98,
      topics: ['Prevention', 'Healthcare', 'Health Education'],
      comments: [],
    ),
    CommunityPost(
      id: 'health12',
      name: 'Dr. Yaw Boakye',
      profession: 'Psychiatrist',
      time: '1d',
      content:
          'Mental health medications are not a sign of weakness. They are a tool. Like glasses for eyesight, they help the brain work the way it needs to.',
      likes: 167,
      topics: ['Mental Health', 'Medication', 'Stigma'],
      comments: [],
    ),
  ];
}

List<Group> demoGroups() {
  return [
    Group(
      id: 'g1',
      name: 'Heart Cancer Heroes',
      description:
          'A peer-support and health-education community for people affected by heart cancers and their caregivers.',
      category: 'Support',
      rules:
          'Respect everyone. No diagnosis. No harassment. Protect personal information. Share verified health information where possible.',
      adminName: 'TrueVoice Community',
      verificationRequired: false,
      members: ['TrueVoice Community'],
      pendingMembers: [],
      messages: [
        GroupMessage(
          id: 'gm1',
          author: 'TrueVoice Community',
          content: 'Welcome to the group! 👋',
          time: '2h',
        ),
      ],
    ),
    Group(
      id: 'g2',
      name: 'SLP Graduates Network',
      description:
          'A private community for Speech and Language Pathology graduates worldwide.',
      category: 'Professional',
      rules:
          'Members must meet the group eligibility requirement. Be respectful. Do not share confidential patient information.',
      adminName: 'Jonathan Bansah',
      verificationRequired: true,
      members: ['Jonathan Bansah'],
      pendingMembers: [],
      messages: [],
    ),
    Group(
      id: 'g3',
      name: 'Global Healthcare Students',
      description:
          'A community for healthcare students everywhere — nursing, medicine, therapy and public health.',
      category: 'Students',
      rules:
          'Respect members. No academic dishonesty. No patient-identifying information.',
      adminName: 'TrueVoice Community',
      verificationRequired: false,
      members: ['TrueVoice Community'],
      pendingMembers: [],
      messages: [],
    ),
    Group(
      id: 'g4',
      name: 'Parents & Caregivers',
      description:
          'A space for parents and caregivers to share experiences and learn from one another.',
      category: 'Caregivers',
      rules:
          'Be supportive. Do not diagnose other members. Respect privacy.',
      adminName: 'TrueVoice Community',
      verificationRequired: false,
      members: ['TrueVoice Community'],
      pendingMembers: [],
      messages: [],
    ),
    Group(
      id: 'g5',
      name: 'Nurses Worldwide',
      description:
          'A community of registered nurses sharing best practice, career advice and support.',
      category: 'Professional',
      rules:
          'Respect all members. No patient-identifying info. Share evidence-based practice.',
      adminName: 'TrueVoice Community',
      verificationRequired: false,
      members: ['TrueVoice Community'],
      pendingMembers: [],
      messages: [],
    ),
    Group(
      id: 'g6',
      name: 'Mental Health Matters',
      description:
          'A safe space to talk about mental health, coping strategies and recovery.',
      category: 'Support',
      rules:
          'Be kind. No medical advice. Crisis resources pinned. Respect privacy.',
      adminName: 'TrueVoice Community',
      verificationRequired: false,
      members: ['TrueVoice Community'],
      pendingMembers: [],
      messages: [],
    ),
    Group(
      id: 'g7',
      name: 'Physiotherapy Professionals',
      description:
          'A global community for physiotherapists to discuss cases, techniques and research.',
      category: 'Professional',
      rules:
          'Evidence-based discussion. No patient identifiers. Respect colleagues.',
      adminName: 'TrueVoice Community',
      verificationRequired: false,
      members: ['TrueVoice Community'],
      pendingMembers: [],
      messages: [],
    ),
  ];
}


// ============================================================
// DEMO PROFESSIONALS
// ============================================================

const List<Professional> professionals = [
  Professional(
    name: 'Dr. Sarah Mensah',
    profession: 'General Practitioner',
    location: 'Accra, Ghana',
    bio: 'General healthcare professional focused on accessible patient-centred care.',
    verified: true,
    workingHours: WorkingHours(
      startHour: 8, endHour: 17,
      daysOfWeek: [1, 2, 3, 4, 5],
    ),
    services: [
      Service(name: 'General Consultation', price: 150),
      Service(name: 'Health Review', price: 100),
    ],
  ),
  Professional(
    name: 'Michael Addo',
    profession: 'Physiotherapist',
    location: 'London, UK',
    bio: 'Physiotherapist supporting mobility, rehabilitation and functional recovery.',
    workingHours: WorkingHours(
      startHour: 9, endHour: 18,
      daysOfWeek: [1, 2, 3, 4, 5, 6],
    ),
    services: [
      Service(name: 'Physiotherapy Consultation', price: 120),
      Service(name: 'Rehabilitation Session', price: 150),
    ],
  ),
  Professional(
    name: 'Ama Boateng',
    profession: 'Speech & Language Therapist',
    location: 'Toronto, Canada',
    bio: 'Speech and language therapist supporting communication and swallowing needs.',
    verified: true,
    workingHours: WorkingHours(
      startHour: 8, endHour: 16,
      daysOfWeek: [1, 2, 3, 4, 5],
    ),
    services: [
      Service(name: 'Speech & Language Assessment', price: 150),
      Service(name: 'Therapy Session', price: 100),
    ],
  ),
  Professional(
    name: 'Dr. Elena Vasquez',
    profession: 'Audiologist',
    location: 'Madrid, Spain',
    bio: 'Audiologist providing hearing assessment and rehabilitation services.',
    workingHours: WorkingHours(
      startHour: 8, endHour: 17,
      daysOfWeek: [1, 2, 3, 4, 5],
    ),
    services: [
      Service(name: 'Hearing Assessment', price: 180),
      Service(name: 'Hearing Consultation', price: 120),
    ],
  ),
  Professional(
    name: 'Akosua Owusu',
    profession: 'Psychologist',
    location: 'Nairobi, Kenya',
    bio: 'Psychologist supporting emotional wellbeing and psychological care.',
    workingHours: WorkingHours(
      startHour: 10, endHour: 19,
      daysOfWeek: [1, 2, 3, 4, 5],
    ),
    services: [
      Service(name: 'Psychological Consultation', price: 200),
      Service(name: 'Follow-up Session', price: 150),
    ],
  ),
  Professional(
    name: 'Dr. Rohan Mehta',
    profession: 'General Practitioner',
    location: 'Mumbai, India',
    bio: 'Family medicine doctor focused on preventive care and chronic disease management.',
    verified: true,
    workingHours: WorkingHours(
      startHour: 9, endHour: 18,
      daysOfWeek: [1, 2, 3, 4, 5, 6],
    ),
    services: [
      Service(name: 'General Consultation', price: 100),
      Service(name: 'Annual Health Check', price: 150),
    ],
  ),
  Professional(
    name: 'Dr. Lucas Silva',
    profession: 'Physiotherapist',
    location: 'São Paulo, Brazil',
    bio: 'Sports and rehabilitation physiotherapist working with athletes and post-surgery recovery.',
    workingHours: WorkingHours(
      startHour: 7, endHour: 19,
      daysOfWeek: [1, 2, 3, 4, 5, 6],
    ),
    services: [
      Service(name: 'Sports Physiotherapy', price: 140),
      Service(name: 'Post-Surgery Rehab', price: 160),
    ],
  ),
  Professional(
    name: 'Nurse Akua Mensah',
    profession: 'Registered Nurse',
    location: 'Kumasi, Ghana',
    bio: 'Registered nurse specialising in home care, wound management and elderly support.',
    verified: true,
    workingHours: WorkingHours(
      startHour: 6, endHour: 20,
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    ),
    services: [
      Service(name: 'Home Nursing Visit', price: 120),
      Service(name: 'Wound Care', price: 90),
    ],
  ),
  Professional(
    name: 'Dr. Fatima Al-Hassan',
    profession: 'Dentist',
    location: 'Cairo, Egypt',
    bio: 'Dental surgeon specialising in preventive dentistry, cosmetic care and paediatric patients.',
    verified: true,
    workingHours: WorkingHours(
      startHour: 9, endHour: 18,
      daysOfWeek: [1, 2, 3, 4, 5],
    ),
    services: [
      Service(name: 'Dental Check-up', price: 80),
      Service(name: 'Teeth Cleaning', price: 120),
      Service(name: 'Filling', price: 150),
    ],
  ),
  Professional(
    name: 'Kwesi Amankwah',
    profession: 'Pharmacist',
    location: 'Takoradi, Ghana',
    bio: 'Community pharmacist providing medication reviews, chronic condition support and health advice.',
    verified: true,
    workingHours: WorkingHours(
      startHour: 8, endHour: 20,
      daysOfWeek: [1, 2, 3, 4, 5, 6],
    ),
    services: [
      Service(name: 'Medication Review', price: 60),
      Service(name: 'Prescription Consultation', price: 40),
    ],
  ),
  Professional(
    name: 'Grace Mwangi',
    profession: 'Dietitian',
    location: 'Nairobi, Kenya',
    bio: 'Clinical dietitian helping patients manage diabetes, weight and heart-healthy eating.',
    verified: true,
    workingHours: WorkingHours(
      startHour: 9, endHour: 17,
      daysOfWeek: [1, 2, 3, 4, 5],
    ),
    services: [
      Service(name: 'Nutrition Consultation', price: 130),
      Service(name: 'Meal Plan', price: 90),
    ],
  ),
  Professional(
    name: 'Dr. Yaw Boakye',
    profession: 'Psychiatrist',
    location: 'Accra, Ghana',
    bio: 'Psychiatrist offering medication management and therapy for mood and anxiety disorders.',
    workingHours: WorkingHours(
      startHour: 10, endHour: 18,
      daysOfWeek: [1, 2, 3, 4, 5],
    ),
    services: [
      Service(name: 'Psychiatric Evaluation', price: 250),
      Service(name: 'Medication Review', price: 150),
    ],
  ),
];

const List<Facility> facilities = [
  Facility(
    name: 'Accra Central Hospital',
    type: 'Hospitals & Clinics',
    location: 'Accra, Ghana',
    address: 'Accra, Ghana',
    hours: 'Open 24 hours',
    phone: '+233 000 000 000',
    email: 'info@accracentral.example',
    latitude: 5.6037,
    longitude: -0.1870,
    services: [
      Service(name: 'Outpatient Service', price: 0),
      Service(name: 'Specialist Consultation', price: 0),
    ],
  ),
  Facility(
    name: 'TrueVoice Health Centre',
    type: 'Hospitals & Clinics',
    location: 'Global',
    address: 'Online and in-person',
    hours: 'Monday–Friday: 8:00–17:00',
    phone: '+00 000 000 001',
    email: 'contact@truevoice.example',
    services: [
      Service(name: 'General Consultation', price: 100),
      Service(name: 'Health Screening', price: 120),
    ],
  ),
  Facility(
    name: 'WellCare Pharmacy',
    type: 'Pharmacies',
    location: 'Lagos, Nigeria',
    address: 'Victoria Island, Lagos',
    hours: 'Monday–Saturday: 8:00–20:00',
    phone: '+234 000 000 002',
    email: 'pharmacy@wellcare.example',
    latitude: 6.4281,
    longitude: 3.4219,
    services: [
      Service(name: 'Pharmacy Service', price: 0),
    ],
  ),
  Facility(
    name: 'Global Diagnostic Lab',
    type: 'Laboratories',
    location: 'London, UK',
    address: 'Central London, UK',
    hours: 'Monday–Saturday: 7:00–18:00',
    phone: '+44 000 000 003',
    email: 'lab@globaldiagnostic.example',
    latitude: 51.5074,
    longitude: -0.1278,
    services: [
      Service(name: 'Laboratory Service', price: 0),
    ],
  ),
  Facility(
    name: 'Vision Imaging Centre',
    type: 'Imaging Centres',
    location: 'New York, USA',
    address: 'Manhattan, New York',
    hours: 'Monday–Friday: 8:00–17:00',
    phone: '+1 000 000 004',
    email: 'imaging@visionimaging.example',
    latitude: 40.7128,
    longitude: -74.0060,
    services: [
      Service(name: 'Imaging Service', price: 0),
    ],
  ),
  Facility(
    name: 'Kumasi Community Clinic',
    type: 'Hospitals & Clinics',
    location: 'Kumasi, Ghana',
    address: 'Adum, Kumasi',
    hours: 'Monday–Saturday: 7:00–21:00',
    phone: '+233 000 000 005',
    email: 'clinic@kumasi.example',
    latitude: 6.6885,
    longitude: -1.6244,
    services: [
      Service(name: 'General Consultation', price: 80),
      Service(name: 'Child Health', price: 60),
      Service(name: 'Antenatal Care', price: 90),
    ],
  ),
  Facility(
    name: 'Cape Coast Diagnostic Centre',
    type: 'Laboratories',
    location: 'Cape Coast, Ghana',
    address: 'Cape Coast, Central Region',
    hours: 'Monday–Saturday: 6:30–18:00',
    phone: '+233 000 000 006',
    email: 'lab@capecoast.example',
    latitude: 5.1054,
    longitude: -1.2466,
    services: [
      Service(name: 'Blood Test', price: 50),
      Service(name: 'Malaria Test', price: 30),
      Service(name: 'Full Panel', price: 250),
    ],
  ),
  Facility(
    name: 'Nairobi Dental Centre',
    type: 'Hospitals & Clinics',
    location: 'Nairobi, Kenya',
    address: 'Westlands, Nairobi',
    hours: 'Monday–Saturday: 9:00–19:00',
    phone: '+254 000 000 007',
    email: 'info@nairobidental.example',
    latitude: -1.2921,
    longitude: 36.8219,
    services: [
      Service(name: 'Dental Check-up', price: 70),
      Service(name: 'Root Canal', price: 300),
    ],
  ),
  Facility(
    name: 'Madrid Hearing Institute',
    type: 'Hospitals & Clinics',
    location: 'Madrid, Spain',
    address: 'Salamanca, Madrid',
    hours: 'Monday–Friday: 9:00–18:00',
    phone: '+34 000 000 008',
    email: 'info@madridhearing.example',
    latitude: 40.4168,
    longitude: -3.7038,
    services: [
      Service(name: 'Hearing Test', price: 100),
      Service(name: 'Hearing Aid Fitting', price: 500),
    ],
  ),
  Facility(
    name: 'Cairo Family Clinic',
    type: 'Hospitals & Clinics',
    location: 'Cairo, Egypt',
    address: 'Zamalek, Cairo',
    hours: 'Open 24 hours',
    phone: '+20 000 000 009',
    email: 'info@cairofamily.example',
    latitude: 30.0444,
    longitude: 31.2357,
    services: [
      Service(name: 'General Consultation', price: 90),
      Service(name: 'Paediatrics', price: 120),
    ],
  ),
];

List<FreelanceService> demoFreelanceServices() {
  return [
    FreelanceService(
      id: 'f1',
      providerName: 'Nurse Akua Mensah',
      title: 'Home Nursing Care',
      description:
          'Professional home nursing for elderly and post-surgery patients. Includes wound care, medication support and vitals monitoring.',
      category: 'Nursing',
      price: 200,
      location: 'Accra',
      address: 'East Legon, Accra',
      latitude: 5.6352,
      longitude: -0.1563,
    ),
    FreelanceService(
      id: 'f2',
      providerName: 'Kofi Speech Therapy',
      title: 'Speech Therapy Session',
      description:
          'One-on-one speech therapy for children and adults. Flexible scheduling, home visits available.',
      category: 'Speech Therapy',
      price: 150,
      location: 'Ho',
      address: 'Ho, Volta Region',
      latitude: 6.6009,
      longitude: 0.4713,
    ),
    FreelanceService(
      id: 'f3',
      providerName: 'Physio Care Ghana',
      title: 'Physiotherapy at Home',
      description:
          'Mobile physiotherapy for rehabilitation, sports injuries and post-operative recovery.',
      category: 'Physiotherapy',
      price: 180,
      location: 'Kumasi',
      address: 'Asokwa, Kumasi',
      latitude: 6.6666,
      longitude: -1.6163,
    ),
    FreelanceService(
      id: 'f4',
      providerName: 'Mental Health Hub',
      title: 'Counselling Session',
      description:
          'Confidential counselling for stress, anxiety, grief and relationships. Online or in person.',
      category: 'Counselling',
      price: 220,
      location: 'Accra',
      address: 'Osu, Accra',
      latitude: 5.5564,
      longitude: -0.1780,
    ),
    FreelanceService(
      id: 'f5',
      providerName: 'Dr. Yaw Antwi',
      title: 'Health Consultation',
      description:
          'General medical consultation, second opinions and health advice. Home or clinic visits.',
      category: 'Medical',
      price: 250,
      location: 'Tema',
      address: 'Community 1, Tema',
      latitude: 5.6698,
      longitude: -0.0166,
    ),
  ];
}

// ============================================================
// LANGUAGE / LOCALIZATION
// ============================================================

class TVLanguage {
  const TVLanguage({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}

const supportedLanguages = [
  TVLanguage(code: 'en', name: 'English'),
  TVLanguage(code: 'fr', name: 'Français'),
  TVLanguage(code: 'es', name: 'Español'),
  TVLanguage(code: 'pt', name: 'Português'),
  TVLanguage(code: 'de', name: 'Deutsch'),
  TVLanguage(code: 'ar', name: 'العربية'),
  TVLanguage(code: 'sw', name: 'Kiswahili'),
];

String deviceLanguageCode() {
  final code =
      WidgetsBinding.instance.platformDispatcher.locale
          .languageCode;
  final supported = supportedLanguages
      .map((language) => language.code)
      .toSet();
  return supported.contains(code) ? code : 'en';
}

String currentLanguageCode() {
  final store = TrueVoiceStore.instance;
  if (store.languageCode.isNotEmpty) {
    return store.languageCode;
  }
  return deviceLanguageCode();
}

/// Master translation dictionary. Add new keys here
/// and they will translate everywhere automatically.
const Map<String, Map<String, String>> _tvTranslations = {
  'en': {
    // nav
    'home': 'Home',
    'discover': 'Discover',
    'community': 'Community',
    'bookings': 'Bookings',
    'profile': 'Profile',
    'messages': 'Messages',
    'groups': 'Groups',
    // actions
    'translate': 'Translate',
    'original': 'Original',
    'share': 'Share',
    'post': 'Post',
    'comment': 'Comment',
    'reply': 'Reply',
    'send': 'Send',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'search': 'Search',
    'connect': 'Connect',
    'connected': 'Connected',
    'request_sent': 'Request Sent',
    'accept': 'Accept',
    'deny': 'Deny',
    'approve': 'Approve',
    'join_group': 'Join Group',
    'request_to_join': 'Request to Join',
    'book': 'Book',
    'book_service': 'Book a Service',
    'book_appointment': 'Book Appointment',
    'request_appointment': 'Request Appointment',
    'select_service': 'Select service',
    'select_date': 'Choose a date',
    'select_time': 'Choose a time',
    'date': 'Date',
    'time': 'Time',
    'location': 'Location',
    'opening_hours': 'Opening hours',
    'contact': 'Contact',
    'services': 'Services',
    'working_hours': 'Working hours',
    'about': 'About TrueVoice',
    // sections
    'what_do_you_need': 'What do you need?',
    'find_professional': 'Find a Professional',
    'find_facility': 'Find a Facility',
    'professionals': 'Professionals',
    'facilities': 'Facilities',
    'recommended': 'Recommended for you',
    'healthcare_professionals': 'Healthcare professionals',
    'healthcare_facilities': 'Healthcare facilities',
    'freelance': 'Freelance Services',
    'search_results': 'Search results',
    'comments': 'Comments',
    'write_comment': 'Write a comment…',
    'no_comments': 'No comments yet',
    'no_results': 'No results found',
    'add_reaction': 'Add reaction',
    'reactions': 'Reactions',
    // about
    'about_text':
           
        "TrueVoice is a health community app for everyone in healthcare — patients, doctors, nurses, pharmacists, dentists, therapists, students, caregivers and anyone else. It informs. It connects. It does not diagnose.\n\nTrueVoice brings healthcare professionals, facilities and services into one trusted space — from general practitioners to audiologists, speech therapists, physiotherapists, psychologists, dietitians and more.\n\nKey features include:\n• Community feed with posts, comments and reactions\n• Groups for professionals, students and caregivers\n• Direct messages with text and voice notes\n• Professional directory with verified badges\n• Facility directory with booking\n• Freelance health services marketplace\n• Multi-language support\n• Ask TrueVoice AI for help navigating the app\n\nVerification: healthcare professionals can submit their license for verification and receive a blue tick once approved.\n\nYour privacy matters. All data stays on your device in this prototype.",
  },
  'fr': {
    'home': 'Accueil',
    'discover': 'Découvrir',
    'community': 'Communauté',
    'bookings': 'Rendez-vous',
    'profile': 'Profil',
    'messages': 'Messages',
    'groups': 'Groupes',
    'translate': 'Traduire',
    'original': 'Original',
    'share': 'Partager',
    'post': 'Publier',
    'comment': 'Commenter',
    'reply': 'Répondre',
    'send': 'Envoyer',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'edit': 'Modifier',
    'search': 'Rechercher',
    'connect': 'Se connecter',
    'connected': 'Connecté',
    'request_sent': 'Demande envoyée',
    'accept': 'Accepter',
    'deny': 'Refuser',
    'approve': 'Approuver',
    'join_group': 'Rejoindre le groupe',
    'request_to_join': 'Demander à rejoindre',
    'book': 'Réserver',
    'book_service': 'Réserver un service',
    'book_appointment': 'Prendre rendez-vous',
    'request_appointment': 'Demander un rendez-vous',
    'select_service': 'Choisir un service',
    'select_date': 'Choisir une date',
    'select_time': 'Choisir une heure',
    'date': 'Date',
    'time': 'Heure',
    'location': 'Lieu',
    'opening_hours': "Heures d'ouverture",
    'contact': 'Contact',
    'services': 'Services',
    'working_hours': 'Heures de travail',
    'about': 'À propos de TrueVoice',
    'what_do_you_need': 'De quoi avez-vous besoin ?',
    'find_professional': 'Trouver un professionnel',
    'find_facility': 'Trouver un établissement',
    'professionals': 'Professionnels',
    'facilities': 'Établissements',
    'recommended': 'Recommandé pour vous',
    'healthcare_professionals': 'Professionnels de santé',
    'healthcare_facilities': 'Établissements de santé',
    'freelance': 'Services indépendants',
    'search_results': 'Résultats de recherche',
    'comments': 'Commentaires',
    'write_comment': 'Écrire un commentaire…',
    'no_comments': 'Pas encore de commentaires',
    'no_results': 'Aucun résultat',
    'add_reaction': 'Ajouter une réaction',
    'reactions': 'Réactions',
    'about_text':
          
        "TrueVoice est une application communautaire de santé pour tous ceux qui travaillent dans la santé — patients, médecins, infirmiers, pharmaciens, dentistes, thérapeutes, étudiants, aidants et bien d'autres. Elle informe. Elle connecte. Elle ne pose pas de diagnostic.\n\nTrueVoice réunit les professionnels, les établissements et les services de santé dans un espace de confiance — des médecins généralistes aux audiologistes, orthophonistes, physiothérapeutes, psychologues, diététiciens et plus encore.\n\nFonctionnalités principales :\n• Fil communautaire avec publications, commentaires et réactions\n• Groupes pour professionnels, étudiants et aidants\n• Messages directs avec texte et notes vocales\n• Annuaire de professionnels avec badges vérifiés\n• Annuaire d'établissements avec réservation\n• Marché de services de santé indépendants\n• Prise en charge multilingue\n• Ask TrueVoice AI pour naviguer dans l'application\n\nVérification : les professionnels de santé peuvent soumettre leur licence pour vérification et recevoir un badge bleu une fois approuvés.\n\nVotre vie privée compte. Toutes les données restent sur votre appareil dans ce prototype.",
  },
  'es': {
    'home': 'Inicio',
    'discover': 'Descubrir',
    'community': 'Comunidad',
    'bookings': 'Citas',
    'profile': 'Perfil',
    'messages': 'Mensajes',
    'groups': 'Grupos',
    'translate': 'Traducir',
    'original': 'Original',
    'share': 'Compartir',
    'post': 'Publicar',
    'comment': 'Comentar',
    'reply': 'Responder',
    'send': 'Enviar',
    'cancel': 'Cancelar',
    'save': 'Guardar',
    'delete': 'Eliminar',
    'edit': 'Editar',
    'search': 'Buscar',
    'connect': 'Conectar',
    'connected': 'Conectado',
    'request_sent': 'Solicitud enviada',
    'accept': 'Aceptar',
    'deny': 'Rechazar',
    'approve': 'Aprobar',
    'join_group': 'Unirse al grupo',
    'request_to_join': 'Solicitar unirse',
    'book': 'Reservar',
    'book_service': 'Reservar un servicio',
    'book_appointment': 'Reservar cita',
    'request_appointment': 'Solicitar cita',
    'select_service': 'Elegir servicio',
    'select_date': 'Elegir fecha',
    'select_time': 'Elegir hora',
    'date': 'Fecha',
    'time': 'Hora',
    'location': 'Ubicación',
    'opening_hours': 'Horario',
    'contact': 'Contacto',
    'services': 'Servicios',
    'working_hours': 'Horario laboral',
    'about': 'Acerca de TrueVoice',
    'what_do_you_need': '¿Qué necesitas?',
    'find_professional': 'Buscar profesional',
    'find_facility': 'Buscar centro',
    'professionals': 'Profesionales',
    'facilities': 'Centros',
    'recommended': 'Recomendado para ti',
    'healthcare_professionals': 'Profesionales de salud',
    'healthcare_facilities': 'Centros de salud',
    'freelance': 'Servicios independientes',
    'search_results': 'Resultados',
    'comments': 'Comentarios',
    'write_comment': 'Escribe un comentario…',
    'no_comments': 'Sin comentarios aún',
    'no_results': 'Sin resultados',
    'add_reaction': 'Añadir reacción',
    'reactions': 'Reacciones',
    'about_text':
           
      "TrueVoice es una aplicación comunitaria de salud para todos los que trabajan en salud — pacientes, médicos, enfermeros, farmacéuticos, dentistas, terapeutas, estudiantes, cuidadores y más. Informa. Conecta. No diagnostica.\n\nTrueVoice reúne a profesionales, centros y servicios de salud en un espacio de confianza — desde médicos generales hasta audiólogos, logopedas, fisioterapeutas, psicólogos, dietistas y más.\n\nCaracterísticas:\n• Feed comunitario con publicaciones, comentarios y reacciones\n• Grupos para profesionales, estudiantes y cuidadores\n• Mensajes directos con texto y notas de voz\n• Directorio de profesionales con insignias verificadas\n• Directorio de centros con reservas\n• Mercado de servicios independientes\n• Soporte multilingüe\n• Ask TrueVoice AI para orientarte\n\nVerificación: los profesionales pueden enviar su licencia para verificación y recibir una insignia azul.\n\nTu privacidad importa. Los datos permanecen en tu dispositivo.",
  },
  'pt': {
    'home': 'Início',
    'discover': 'Descobrir',
    'community': 'Comunidade',
    'bookings': 'Consultas',
    'profile': 'Perfil',
    'messages': 'Mensagens',
    'groups': 'Grupos',
    'translate': 'Traduzir',
    'original': 'Original',
    'share': 'Partilhar',
    'post': 'Publicar',
    'comment': 'Comentar',
    'reply': 'Responder',
    'send': 'Enviar',
    'cancel': 'Cancelar',
    'save': 'Guardar',
    'delete': 'Eliminar',
    'edit': 'Editar',
    'search': 'Pesquisar',
    'connect': 'Conectar',
    'connected': 'Conectado',
    'request_sent': 'Pedido enviado',
    'accept': 'Aceitar',
    'deny': 'Recusar',
    'approve': 'Aprovar',
    'join_group': 'Entrar no grupo',
    'request_to_join': 'Pedir para entrar',
    'book': 'Reservar',
    'book_service': 'Reservar serviço',
    'book_appointment': 'Marcar consulta',
    'request_appointment': 'Pedir consulta',
    'select_service': 'Escolher serviço',
    'select_date': 'Escolher data',
    'select_time': 'Escolher hora',
    'date': 'Data',
    'time': 'Hora',
    'location': 'Local',
    'opening_hours': 'Horário',
    'contact': 'Contacto',
    'services': 'Serviços',
    'working_hours': 'Horário de trabalho',
    'about': 'Sobre o TrueVoice',
    'what_do_you_need': 'Do que precisa?',
    'find_professional': 'Encontrar profissional',
    'find_facility': 'Encontrar unidade',
    'professionals': 'Profissionais',
    'facilities': 'Unidades',
    'recommended': 'Recomendado para si',
    'healthcare_professionals': 'Profissionais de saúde',
    'healthcare_facilities': 'Unidades de saúde',
    'freelance': 'Serviços independentes',
    'search_results': 'Resultados',
    'comments': 'Comentários',
    'write_comment': 'Escrever comentário…',
    'no_comments': 'Sem comentários',
    'no_results': 'Sem resultados',
    'add_reaction': 'Adicionar reação',
    'reactions': 'Reações',
    'about_text':
           
        "TrueVoice é uma aplicação comunitária de saúde para todos os que trabalham na saúde — pacientes, médicos, enfermeiros, farmacêuticos, dentistas, terapeutas, estudantes, cuidadores e mais. Informa. Conecta. Não diagnostica.\n\nTrueVoice reúne profissionais, unidades e serviços de saúde num espaço de confiança — de médicos gerais a audiologistas, terapeutas da fala, fisioterapeutas, psicólogos, nutricionistas e mais.\n\nFuncionalidades:\n• Feed comunitário com publicações, comentários e reações\n• Grupos para profissionais, estudantes e cuidadores\n• Mensagens diretas com texto e notas de voz\n• Diretório de profissionais com selos verificados\n• Diretório de unidades com marcação\n• Mercado de serviços independentes\n• Suporte multilingue\n• Ask TrueVoice AI para orientação\n\nVerificação: profissionais de saúde podem submeter a licença para verificação e receber um selo azul.\n\nA sua privacidade importa. Os dados ficam no seu dispositivo.",
  },
  'de': {
    'home': 'Start',
    'discover': 'Entdecken',
    'community': 'Community',
    'bookings': 'Termine',
    'profile': 'Profil',
    'messages': 'Nachrichten',
    'groups': 'Gruppen',
    'translate': 'Übersetzen',
    'original': 'Original',
    'share': 'Teilen',
    'post': 'Posten',
    'comment': 'Kommentieren',
    'reply': 'Antworten',
    'send': 'Senden',
    'cancel': 'Abbrechen',
    'save': 'Speichern',
    'delete': 'Löschen',
    'edit': 'Bearbeiten',
    'search': 'Suchen',
    'connect': 'Verbinden',
    'connected': 'Verbunden',
    'request_sent': 'Anfrage gesendet',
    'accept': 'Annehmen',
    'deny': 'Ablehnen',
    'approve': 'Genehmigen',
    'join_group': 'Gruppe beitreten',
    'request_to_join': 'Beitritt anfragen',
    'book': 'Buchen',
    'book_service': 'Service buchen',
    'book_appointment': 'Termin buchen',
    'request_appointment': 'Termin anfragen',
    'select_service': 'Service wählen',
    'select_date': 'Datum wählen',
    'select_time': 'Uhrzeit wählen',
    'date': 'Datum',
    'time': 'Uhrzeit',
    'location': 'Ort',
    'opening_hours': 'Öffnungszeiten',
    'contact': 'Kontakt',
    'services': 'Services',
    'working_hours': 'Arbeitszeiten',
    'about': 'Über TrueVoice',
    'what_do_you_need': 'Was brauchst du?',
    'find_professional': 'Facharzt finden',
    'find_facility': 'Einrichtung finden',
    'professionals': 'Fachleute',
    'facilities': 'Einrichtungen',
    'recommended': 'Für dich empfohlen',
    'healthcare_professionals': 'Gesundheitsfachleute',
    'healthcare_facilities': 'Gesundheitseinrichtungen',
    'freelance': 'Freiberufliche Dienste',
    'search_results': 'Suchergebnisse',
    'comments': 'Kommentare',
    'write_comment': 'Kommentar schreiben…',
    'no_comments': 'Noch keine Kommentare',
    'no_results': 'Keine Ergebnisse',
    'add_reaction': 'Reaktion hinzufügen',
    'reactions': 'Reaktionen',
    'about_text':
            
        'TrueVoice ist eine Gesundheits-Community-App für alle im Gesundheitswesen — Patienten, Ärzte, Krankenpfleger, Apotheker, Zahnärzte, Therapeuten, Studierende, Pflegende und mehr. Sie informiert. Sie verbindet. Sie diagnostiziert nicht.\n\nTrueVoice bringt Gesundheitsfachleute, Einrichtungen und Dienste an einem vertrauenswürdigen Ort zusammen — von Hausärzten bis zu Audiologen, Logopäden, Physiotherapeuten, Psychologen, Ernährungsberatern und mehr.\n\nFunktionen:\n• Community-Feed mit Beiträgen, Kommentaren und Reaktionen\n• Gruppen für Fachleute, Studierende und Pflegende\n• Direktnachrichten mit Text und Sprachnotizen\n• Verzeichnis für Fachleute mit verifizierten Abzeichen\n• Verzeichnis für Einrichtungen mit Buchung\n• Marktplatz für freiberufliche Gesundheitsdienste\n• Mehrsprachige Unterstützung\n• Ask TrueVoice AI zur Orientierung\n\nVerifizierung: Fachleute können ihre Lizenz zur Überprüfung einreichen und erhalten ein blaues Häkchen.\n\nDeine Privatsphäre zählt. Alle Daten bleiben auf deinem Gerät.',
  },
  'ar': {
    'home': 'الرئيسية',
    'discover': 'اكتشف',
    'community': 'المجتمع',
    'bookings': 'المواعيد',
    'profile': 'الملف الشخصي',
    'messages': 'الرسائل',
    'groups': 'المجموعات',
    'translate': 'ترجمة',
    'original': 'الأصل',
    'share': 'مشاركة',
    'post': 'نشر',
    'comment': 'تعليق',
    'reply': 'رد',
    'send': 'إرسال',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'delete': 'حذف',
    'edit': 'تعديل',
    'search': 'بحث',
    'connect': 'اتصال',
    'connected': 'متصل',
    'request_sent': 'تم إرسال الطلب',
    'accept': 'قبول',
    'deny': 'رفض',
    'approve': 'موافقة',
    'join_group': 'الانضمام للمجموعة',
    'request_to_join': 'طلب الانضمام',
    'book': 'حجز',
    'book_service': 'احجز خدمة',
    'book_appointment': 'احجز موعدًا',
    'request_appointment': 'اطلب موعدًا',
    'select_service': 'اختر الخدمة',
    'select_date': 'اختر التاريخ',
    'select_time': 'اختر الوقت',
    'date': 'التاريخ',
    'time': 'الوقت',
    'location': 'الموقع',
    'opening_hours': 'ساعات العمل',
    'contact': 'اتصال',
    'services': 'الخدمات',
    'working_hours': 'ساعات العمل',
    'about': 'حول TrueVoice',
    'what_do_you_need': 'ماذا تحتاج؟',
    'find_professional': 'ابحث عن مختص',
    'find_facility': 'ابحث عن منشأة',
    'professionals': 'المختصون',
    'facilities': 'المنشآت',
    'recommended': 'مقترح لك',
    'healthcare_professionals': 'المختصون الصحيون',
    'healthcare_facilities': 'المنشآت الصحية',
    'freelance': 'الخدمات المستقلة',
    'search_results': 'نتائج البحث',
    'comments': 'التعليقات',
    'write_comment': 'اكتب تعليقًا…',
    'no_comments': 'لا توجد تعليقات بعد',
    'no_results': 'لا نتائج',
    'add_reaction': 'أضف تفاعلاً',
    'reactions': 'التفاعلات',
    'about_text':
           
        'TrueVoice تطبيق مجتمعي صحي لكل العاملين في مجال الصحة — المرضى والأطباء والممرضين والصيادلة وأطباء الأسنان والمعالجين والطلاب ومقدمي الرعاية وغيرهم. يُعلم. يربط. لا يشخّص.\n\nيجمع TrueVoice المختصين والمنشآت والخدمات الصحية في مساحة موثوقة — من الأطباء العامين إلى أخصائيي السمع والنطق والعلاج الطبيعي وعلماء النفس وأخصائيي التغذية والمزيد.\n\nالميزات:\n• موجز مجتمعي مع منشورات وتعليقات وتفاعلات\n• مجموعات للمختصين والطلاب ومقدمي الرعاية\n• رسائل مباشرة بالنص والملاحظات الصوتية\n• دليل المختصين مع شارات موثقة\n• دليل المنشآت مع الحجز\n• سوق للخدمات الصحية المستقلة\n• دعم متعدد اللغات\n• Ask TrueVoice AI للمساعدة في التنقل\n\nالتحقق: يمكن للمختصين تقديم ترخيصهم للتحقق والحصول على علامة زرقاء.\n\nخصوصيتك تهمنا. تبقى البيانات على جهازك.',
  },
  'sw': {
    'home': 'Nyumbani',
    'discover': 'Gundua',
    'community': 'Jamii',
    'bookings': 'Miadi',
    'profile': 'Wasifu',
    'messages': 'Ujumbe',
    'groups': 'Vikundi',
    'translate': 'Tafsiri',
    'original': 'Asili',
    'share': 'Shiriki',
    'post': 'Chapisha',
    'comment': 'Toa maoni',
    'reply': 'Jibu',
    'send': 'Tuma',
    'cancel': 'Ghairi',
    'save': 'Hifadhi',
    'delete': 'Futa',
    'edit': 'Hariri',
    'search': 'Tafuta',
    'connect': 'Ungana',
    'connected': 'Umeunganishwa',
    'request_sent': 'Ombi limetumwa',
    'accept': 'Kubali',
    'deny': 'Kataa',
    'approve': 'Idhinisha',
    'join_group': 'Jiunge na kikundi',
    'request_to_join': 'Omba kujiunga',
    'book': 'Weka miadi',
    'book_service': 'Weka huduma',
    'book_appointment': 'Weka miadi',
    'request_appointment': 'Omba miadi',
    'select_service': 'Chagua huduma',
    'select_date': 'Chagua tarehe',
    'select_time': 'Chagua saa',
    'date': 'Tarehe',
    'time': 'Saa',
    'location': 'Mahali',
    'opening_hours': 'Saa za kufungua',
    'contact': 'Wasiliana',
    'services': 'Huduma',
    'working_hours': 'Saa za kazi',
    'about': 'Kuhusu TrueVoice',
    'what_do_you_need': 'Unahitaji nini?',
    'find_professional': 'Tafuta mtaalamu',
    'find_facility': 'Tafuta kituo',
    'professionals': 'Wataalamu',
    'facilities': 'Vituo',
    'recommended': 'Inapendekezwa kwako',
    'healthcare_professionals': 'Wataalamu wa afya',
    'healthcare_facilities': 'Vituo vya afya',
    'freelance': 'Huduma huru',
    'search_results': 'Matokeo ya utafutaji',
    'comments': 'Maoni',
    'write_comment': 'Andika maoni…',
    'no_comments': 'Hakuna maoni bado',
    'no_results': 'Hakuna matokeo',
    'add_reaction': 'Ongeza mwitikio',
    'reactions': 'Mivitikio',
    'about_text':
           
        'TrueVoice ni programu ya jamii ya afya kwa kila mtu katika sekta ya afya — wagonjwa, madaktari, wauguzi, wafamasia, madaktari wa meno, wataalamu wa tiba, wanafunzi, walezi na wengine. Inafahamisha. Inaunganisha. Haitambui magonjwa.\n\nTrueVoice inaleta wataalamu, vituo na huduma za afya mahali pamoja pa kuaminika — kutoka kwa madaktari wa jumla hadi wataalamu wa masikio, wataalamu wa usemi, wataalamu wa physiotherapy, wanasaikolojia, wataalamu wa lishe na zaidi.\n\nVipengele:\n• Mlisho wa jamii na machapisho, maoni na mivitikio\n• Vikundi kwa wataalamu, wanafunzi na walezi\n• Ujumbe wa moja kwa moja kwa maandishi na sauti\n• Orodha ya wataalamu na alama za uthibitisho\n• Orodha ya vituo na uwezo wa kuweka miadi\n• Soko la huduma huru za afya\n• Msaada wa lugha nyingi\n• Ask TrueVoice AI kwa mwongozo\n\nUthibitisho: wataalamu wanaweza kuwasilisha leseni yao kwa uthibitisho na kupokea alama ya bluu.\n\nFaragha yako ni muhimu. Data inabaki kwenye kifaa chako.',
  },
};

String tvText(String key) {
  final language = currentLanguageCode();
  return _tvTranslations[language]?[key] ??
      _tvTranslations['en']![key] ??
      key;
}

// ============================================================
// APP
// ============================================================

class TrueVoiceApp extends StatelessWidget {
  const TrueVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF007F86);

    return AnimatedBuilder(
      animation: TrueVoiceStore.instance,
      builder: (context, child) {
        final language = currentLanguageCode();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TrueVoice',
          locale: Locale(language),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLanguages
              .map((l) => Locale(l.code))
              .toList(),
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7FAFA),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(16),
                ),
                borderSide: BorderSide.none,
              ),
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
          ),
                 home: const AuthGate(),
        );
      },
    );
  }
}

// ============================================================
// HOME NAVIGATION
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 2;

  final pages = const [
    HomePage(),
    DiscoverPage(),
    CommunityPage(),
    BookingsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: TrueVoiceStore.instance,
      builder: (context, c) {
        return Scaffold(
          body: IndexedStack(index: index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) =>
                setState(() => index = v),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: tvText('home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: const Icon(Icons.explore),
                label: tvText('discover'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups),
                label: tvText('community'),
              ),
              NavigationDestination(
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
                selectedIcon: const Icon(
                  Icons.calendar_month,
                ),
                label: tvText('bookings'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: tvText('profile'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// HOME PAGE
// ============================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TrueVoice',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Your gateway to healthcare',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationsPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.notifications_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            readOnly: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DiscoverPage(),
                ),
              );
            },
            decoration: InputDecoration(
              hintText: tvText('search'),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 22),
          SectionTitle(title: tvText('what_do_you_need')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ActionCard(
                  icon: Icons.medical_services_outlined,
                  title: tvText('find_professional'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfessionalDirectoryPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionCard(
                  icon: Icons.local_hospital_outlined,
                  title: tvText('find_facility'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const FacilityDirectoryPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ActionCard(
                  icon: Icons.calendar_month_outlined,
                  title: tvText('book_appointment'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const BookAppointmentPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionCard(
                  icon: Icons.groups_outlined,
                  title: tvText('community'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GroupsPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionTitle(title: tvText('professionals')),
          const SizedBox(height: 12),
          ...professionals.take(3).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProfessionalTile(professional: p),
                ),
              ),
          const SizedBox(height: 18),
          SectionTitle(title: tvText('recommended')),
          const SizedBox(height: 12),
          ...store.recommendedPosts().map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PostCard(post: post),
                ),
              ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TrueVoice informs.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text('TrueVoice connects.'),
                Text('TrueVoice does not diagnose.'),
              ],
            ),
          ),
                  ],
        ),
      ),
    );
  }
}

// ============================================================
// DISCOVER  (search now works properly, results shown at top)
// ============================================================

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _controller = TextEditingController();
  String search = '';

    final categories = const [
    'Doctors',
    'Nurses',
    'Pharmacists',
    'Dentists',
    'Audiologists',
    'Speech & Language Therapists',
    'Physiotherapists',
    'Occupational Therapists',
    'Psychologists',
    'Dietitians',
    'Midwives',
    'Radiographers',
    'Lab Scientists',
    'Optometrists',
  ];

  final facilityTypes = const [
    'Hospitals & Clinics',
    'Pharmacies',
    'Laboratories',
    'Imaging Centres',
  ];

    String professionFromCategory(String category) {
    switch (category) {
      case 'Doctors':
        return 'General Practitioner';
      case 'Nurses':
        return 'Registered Nurse';
      case 'Pharmacists':
        return 'Pharmacist';
      case 'Dentists':
        return 'Dentist';
      case 'Audiologists':
        return 'Audiologist';
      case 'Speech & Language Therapists':
        return 'Speech & Language Therapist';
      case 'Physiotherapists':
        return 'Physiotherapist';
      case 'Occupational Therapists':
        return 'Occupational Therapist';
      case 'Psychologists':
        return 'Psychologist';
      case 'Dietitians':
        return 'Dietitian';
      case 'Midwives':
        return 'Midwife';
      case 'Radiographers':
        return 'Radiographer';
      case 'Lab Scientists':
        return 'Laboratory Scientist';
      case 'Optometrists':
        return 'Optometrist';
      default:
        return category;
    }
  }

  List<Professional> get professionalResults {
    if (search.isEmpty) return [];
    final q = search.toLowerCase();
        return professionals.where((p) {
      if (verifiedOnly && !p.verified) return false;
      return p.name.toLowerCase().contains(q) ||
          p.profession.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q) ||
          p.bio.toLowerCase().contains(q);
    }).toList();
  }

  List<Facility> get facilityResults {
    if (search.isEmpty) return [];
    final q = search.toLowerCase();
    return facilities.where((f) {
      return f.name.toLowerCase().contains(q) ||
          f.type.toLowerCase().contains(q) ||
          f.location.toLowerCase().contains(q) ||
          f.address.toLowerCase().contains(q);
    }).toList();
  }

  List<CommunityPost> get postResults {
    if (search.isEmpty) return [];
    final q = search.toLowerCase();
    return TrueVoiceStore.instance.posts.where((p) {
      return p.content.toLowerCase().contains(q) ||
          p.name.toLowerCase().contains(q) ||
          p.topics.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  List<Group> get groupResults {
    if (search.isEmpty) return [];
    final q = search.toLowerCase();
    return TrueVoiceStore.instance.groups.where((g) {
      return g.name.toLowerCase().contains(q) ||
          g.description.toLowerCase().contains(q) ||
          g.category.toLowerCase().contains(q);
    }).toList();
  }

  List<FreelanceService> get freelanceResults {
    if (search.isEmpty) return [];
    final q = search.toLowerCase();
    return TrueVoiceStore.instance.freelanceServices.where((f) {
      return f.title.toLowerCase().contains(q) ||
          f.description.toLowerCase().contains(q) ||
          f.category.toLowerCase().contains(q) ||
          f.providerName.toLowerCase().contains(q) ||
          f.location.toLowerCase().contains(q);
    }).toList();
  }

  bool verifiedOnly = false;
  bool get hasResults =>
      professionalResults.isNotEmpty ||
      facilityResults.isNotEmpty ||
      postResults.isNotEmpty ||
      groupResults.isNotEmpty ||
      freelanceResults.isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            tvText('discover'),
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
                    TextField(
            controller: _controller,
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              hintText: tvText('search'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => search = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Verified only'),
                selected: verifiedOnly,
                avatar: verifiedOnly
                    ? const Icon(Icons.verified, size: 16)
                    : null,
                onSelected: (v) =>
                    setState(() => verifiedOnly = v),
              ),
            ],
          ),

          // ---------- SEARCH RESULTS FIRST (fixes "goes under" bug)
          if (search.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionTitle(title: tvText('search_results')),
            const SizedBox(height: 12),
            if (!hasResults)
              EmptyState(
                icon: Icons.search_off,
                title: tvText('no_results'),
              ),
            if (professionalResults.isNotEmpty) ...[
              const _MiniHeader(icon: Icons.person_outline, label: 'Professionals'),
              ...professionalResults.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProfessionalTile(professional: p),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (facilityResults.isNotEmpty) ...[
              const _MiniHeader(
                  icon: Icons.local_hospital_outlined,
                  label: 'Facilities'),
              ...facilityResults.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FacilityTile(facility: f),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (freelanceResults.isNotEmpty) ...[
              const _MiniHeader(
                  icon: Icons.work_outline, label: 'Freelance'),
              ...freelanceResults.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FreelanceTile(service: f),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (groupResults.isNotEmpty) ...[
              const _MiniHeader(
                  icon: Icons.groups_outlined, label: 'Groups'),
              ...groupResults.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _GroupTile(group: g),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (postResults.isNotEmpty) ...[
              const _MiniHeader(
                  icon: Icons.article_outlined, label: 'Posts'),
              ...postResults.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PostCard(post: p),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],

          // ---------- CATEGORY CHIPS (only show when not searching)
          if (search.isEmpty) ...[
            SectionTitle(title: tvText('healthcare_professionals')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((c) {
                return ActionChip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(c),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfessionalDirectoryPage(
                          filter: professionFromCategory(c),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            SectionTitle(title: tvText('healthcare_facilities')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: facilityTypes.map((t) {
                return ActionChip(
                  avatar: const Icon(
                      Icons.local_hospital_outlined,
                      size: 18),
                  label: Text(t),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FacilityDirectoryPage(filter: t),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            SectionTitle(title: tvText('freelance')),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:
                    TrueVoiceStore.instance.freelanceServices.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final f = TrueVoiceStore
                      .instance.freelanceServices[i];
                  return SizedBox(
                    width: 260,
                    child: _FreelanceTile(service: f),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),
            SectionTitle(title: tvText('groups')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GroupsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.groups_outlined),
              label: Text(tvText('groups')),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _MiniHeader extends StatelessWidget {
  const _MiniHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMMUNITY
// ============================================================

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return AnimatedBuilder(
      animation: store,
            builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(tvText('community')),
                floating: true,
                actions: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GroupsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.groups_outlined),
                  ),
                  IconButton(
                    onPressed: () =>
                        showCreatePostDialog(context),
                    icon: const Icon(Icons.add_box_outlined),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    14,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                        ],
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your health community',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Learn. Connect. Share. Discover healthcare professionals and real experiences.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final visiblePosts = store.posts
                          .where((p) => p.groupId == null)
                          .toList();
                      if (index >= visiblePosts.length) {
                        return null;
                      }
                      final post = visiblePosts[index];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 14),
                        child: _PostCard(post: post),
                      );
                    },
                    childCount: store.posts
                        .where((p) => p.groupId == null)
                        .length,
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

// ============================================================
// POST CARD  (reactions on comments, tap-to-search chips)
// ============================================================

class _PostCard extends StatefulWidget {
  const _PostCard({required this.post});
  final CommunityPost post;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool translated = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final store = TrueVoiceStore.instance;
    final isOwnPost = post.name == store.userName;

    final translatedText = translateDemoPost(
      post.content,
      currentLanguageCode(),
    );

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(
                          userName: post.name,
                          profession: post.profession,
                        ),
                      ),
                    );
                  },
                  child: Avatar(name: post.name, radius: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                                            Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (professionals.any((p) =>
                              p.name == post.name &&
                              p.verified))
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                size: 15,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '${post.profession} • ${post.time}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showEditPostDialog(context, post);
                    } else if (value == 'delete') {
                      confirmDeletePost(context, post);
                    } else if (value == 'comments') {
                      post.commentsEnabled =
                          !post.commentsEnabled;
                      store.updatePost(post);
                    } else if (value == 'save') {
                      store.toggleSave(post);
                    } else if (value == 'report') {
                      showMessage(
                        context,
                        'Post reported. Thank you for helping keep TrueVoice safe.',
                      );
                    }
                  },
                  itemBuilder: (context) {
                    if (isOwnPost) {
                      return [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit post'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete post'),
                        ),
                        PopupMenuItem(
                          value: 'comments',
                          child: Text(
                            post.commentsEnabled
                                ? 'Turn off comments'
                                : 'Turn on comments',
                          ),
                        ),
                      ];
                    }
                    return [
                      PopupMenuItem(
                        value: 'save',
                        child: Text(
                          post.saved
                              ? 'Remove from saved'
                              : 'Save post',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Report post'),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (post.content.isNotEmpty)
              Text(
                translated ? translatedText : post.content,
                style: const TextStyle(fontSize: 15),
              ),
            if (post.content.isNotEmpty &&
                translatedText != post.content)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(
                      () => translated = !translated,
                    );
                  },
                  icon: Icon(
                    translated
                        ? Icons.language
                        : Icons.translate,
                    size: 18,
                  ),
                  label: Text(
                    translated
                        ? tvText('original')
                        : tvText('translate'),
                  ),
                ),
              ),
            if (post.mediaPath != null) ...[
              const SizedBox(height: 12),
              MediaAttachment(post: post),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: post.topics
                  .map(
                    (topic) => ActionChip(
                      label: Text(topic),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicSearchPage(
                              topic: topic,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const Divider(height: 24),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => store.toggleLike(post),
                  icon: Icon(
                    post.liked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: post.liked
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                        : null,
                  ),
                  label: Text('${post.likes}'),
                ),
                TextButton.icon(
                  onPressed: post.commentsEnabled
                      ? () =>
                          showCommentsSheet(context, post)
                      : null,
                  icon: const Icon(Icons.comment_outlined),
                  label: Text('${post.comments.length}'),
                ),
                TextButton.icon(
                  onPressed: () {
                    showMessage(context, 'Post shared.');
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: Text(tvText('share')),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => store.toggleSave(post),
                  icon: Icon(
                    post.saved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOCAL DEMO TRANSLATION
// ============================================================

String translateDemoPost(String text, String language) {
  if (language == 'en') return text;

  final translations = <String, Map<String, String>>{
    'fr': {
      'Stroke awareness matters. Knowing the warning signs and seeking emergency care quickly can make a major difference. Health education should empower people to act early.':
          'La sensibilisation aux AVC est importante. Connaître les signes d\'alerte et rechercher rapidement des soins d\'urgence peut faire une grande différence. L\'éducation à la santé doit aider les personnes à agir rapidement.',
      'Mental health conversations should not only happen during a crisis. Asking for support early is a strength, not a weakness.':
          'Les conversations sur la santé mentale ne devraient pas avoir lieu uniquement pendant une crise. Demander de l\'aide tôt est une force, pas une faiblesse.',
    },
    'es': {
      'Mental health conversations should not only happen during a crisis. Asking for support early is a strength, not a weakness.':
          'Las conversaciones sobre salud mental no deberían ocurrir únicamente durante una crisis. Pedir apoyo a tiempo es una fortaleza, no una debilidad.',
    },
    'pt': {
      'Mental health conversations should not only happen during a crisis. Asking for support early is a strength, not a weakness.':
          'As conversas sobre saúde mental não devem acontecer apenas durante uma crise. Pedir apoio cedo é uma força, não uma fraqueza.',
    },
  };
  return translations[language]?[text] ?? text;
}

// ============================================================
// TOPIC SEARCH PAGE  (tapping a topic chip opens this)
// ============================================================

class TopicSearchPage extends StatelessWidget {
  const TopicSearchPage({super.key, required this.topic});
  final String topic;

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;
    final q = topic.toLowerCase();
    final matchedPosts = store.posts.where((p) {
      return p.topics.any((t) => t.toLowerCase() == q) ||
          p.content.toLowerCase().contains(q);
    }).toList();
    final matchedPros = professionals.where((p) {
      return p.profession.toLowerCase().contains(q) ||
          p.bio.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('#$topic')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (matchedPros.isNotEmpty) ...[
            SectionTitle(title: tvText('professionals')),
            const SizedBox(height: 8),
            ...matchedPros.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ProfessionalTile(professional: p),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (matchedPosts.isNotEmpty) ...[
            SectionTitle(title: tvText('community')),
            const SizedBox(height: 8),
            ...matchedPosts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostCard(post: p),
              ),
            ),
          ],
          if (matchedPosts.isEmpty && matchedPros.isEmpty)
            EmptyState(
              icon: Icons.search_off,
              title: tvText('no_results'),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// EMOJI PICKER (reactions)
// ============================================================

const List<String> kReactionEmojis = [
  '❤️', '👍', '😂', '😮', '😢', '🙏',
  '🔥', '👏', '💯', '🎉', '😍', '🤔',
];

Future<String?> showEmojiPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tvText('add_reaction'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: kReactionEmojis.map((e) {
                return InkWell(
                  onTap: () => Navigator.pop(context, e),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    },
  );
}

// ============================================================
// CREATE POST
// ============================================================

Future<void> showCreatePostDialog(
  BuildContext context, {
  String? groupId,
}) async {
  final controller = TextEditingController();
  final store = TrueVoiceStore.instance;
  String? mediaPath;
  String? mediaType;
  String selectedTopic = 'General Health';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickPhoto() async {
            final file = await store.picker.pickImage(
              source: ImageSource.gallery,
            );
            if (file != null) {
              setModalState(() {
                mediaPath = file.path;
                mediaType = 'image';
              });
            }
          }

          Future<void> pickVideo() async {
            final file = await store.picker.pickVideo(
              source: ImageSource.gallery,
            );
            if (file != null) {
              setModalState(() {
                mediaPath = file.path;
                mediaType = 'video';
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create a post',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Share something with the community...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTopic,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                    ),
                                        items: const [
                      'General Health',
                      'Speech Therapy',
                      'Audiology',
                      'Mental Health',
                      'Nursing',
                      'Pharmacy',
                      'Dentistry',
                      'Nutrition',
                      'Physiotherapy',
                      'Occupational Therapy',
                      'Midwifery',
                      'Public Health',
                      'Students',
                      'Caregiving',
                      'Research',
                      'General',
                    ]
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setModalState(() => selectedTopic = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: pickPhoto,
                        icon: const Icon(Icons.photo_outlined),
                        label: const Text('Photo'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: pickVideo,
                        icon: const Icon(
                            Icons.video_library_outlined),
                        label: const Text('Video'),
                      ),
                    ],
                  ),
                  if (mediaPath != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        mediaType == 'image'
                            ? 'Photo selected'
                            : 'Video selected',
                      ),
                    ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty && mediaPath == null) {
                          showMessage(
                            context,
                            'Add text, a photo or a video.',
                          );
                          return;
                        }
                        final post = CommunityPost(
                          id: store.newId(),
                          name: store.userName,
                          profession: store.userProfession,
                          time: 'Just now',
                          content: text,
                          likes: 0,
                          comments: [],
                          topics: [selectedTopic],
                          mediaPath: mediaPath,
                          mediaType: mediaType,
                          groupId: groupId,
                        );
                                                store.addPost(post);
                        Future.microtask(() {
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        });
                      },
                      child: Text(tvText('post')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================
// COMMENTS  (with replies + reactions)
// ============================================================

void showCommentsSheet(
  BuildContext context,
  CommunityPost post,
) {
  final controller = TextEditingController();
  final store = TrueVoiceStore.instance;
  String? replyToId;
  String? replyToName;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return AnimatedBuilder(
            animation: store,
            builder: (context, child) {
              final topLevel = post.comments
                  .where((c) => c.parentId == null)
                  .toList();

              Widget buildComment(Comment c, {bool isReply = false}) {
                final replies = post.comments
                    .where((x) => x.parentId == c.id)
                    .toList();
                return Padding(
                  padding: EdgeInsets.only(
                    left: isReply ? 36 : 0,
                    top: 4,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                                                    GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfilePage(
                                    userName: c.author,
                                    profession: 'Community member',
                                  ),
                                ),
                              );
                            },
                            child: Avatar(
                              name: c.author,
                              radius: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      c.author,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      c.time,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                                Text(c.content),
                                if (c.reactions.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(
                                            top: 4),
                                    child: Wrap(
                                      spacing: 6,
                                      children: c.reactions
                                          .entries
                                          .map(
                                            (e) => Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration:
                                                  BoxDecoration(
                                                color: Theme.of(
                                                        context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(10),
                                              ),
                                              child: Text(
                                                '${e.key} ${e.value}',
                                                style:
                                                    const TextStyle(
                                                        fontSize: 12),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final emoji =
                                            await showEmojiPicker(
                                                context);
                                        if (emoji != null) {
                                          store.reactToComment(
                                            post,
                                            c.id,
                                            emoji,
                                          );
                                        }
                                      },
                                      child: const Text(
                                        'React',
                                        style: TextStyle(
                                            fontSize: 12),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setModalState(() {
                                          replyToId = c.id;
                                          replyToName = c.author;
                                        });
                                      },
                                      child: Text(
                                        tvText('reply'),
                                        style: const TextStyle(
                                            fontSize: 12),
                                      ),
                                    ),
                                    if (c.isOwnComment)
                                      TextButton(
                                        onPressed: () =>
                                            store.deleteComment(
                                          post,
                                          c.id,
                                        ),
                                        child: Text(
                                          tvText('delete'),
                                          style:
                                              const TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ...replies.map(
                        (r) => buildComment(r, isReply: true),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                          20,
                ),
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height * .7,
                  child: Column(
                    children: [
                      Text(
                        tvText('comments'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                                fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: topLevel.isEmpty
                            ? EmptyState(
                                icon:
                                    Icons.comment_outlined,
                                title: tvText('no_comments'),
                              )
                            : ListView.builder(
                                itemCount: topLevel.length,
                                itemBuilder:
                                    (context, index) =>
                                        buildComment(
                                            topLevel[index]),
                              ),
                      ),
                      if (replyToId != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Replying to $replyToName',
                                  style:
                                      const TextStyle(
                                    fontStyle:
                                        FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                    Icons.close, size: 18),
                                onPressed: () {
                                  setModalState(() {
                                    replyToId = null;
                                    replyToName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                                            Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText:
                                    tvText('write_comment'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () async {
                              final file = await store.picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (file != null) {
                                final text =
                                    controller.text.trim();
                                final attachPath = file.path;
                                store.addComment(
                                  post,
                                  text.isEmpty
                                      ? '📷 Photo'
                                      : '$text 📷',
                                  parentId: replyToId,
                                );
                                controller.clear();
                                setModalState(() {
                                  replyToId = null;
                                  replyToName = null;
                                });
                                // Note: the image is referenced by path
                                // but a full implementation would store it
                                // on the Comment object. Kept minimal here.
                                if (context.mounted) {
                                  showMessage(
                                    context,
                                    'Photo added to comment.',
                                  );
                                }
                                // ignore: unused_local_variable
                                final _ = attachPath;
                              }
                            },
                            icon: const Icon(Icons.photo_outlined),
                          ),
                          const SizedBox(width: 4),
                          IconButton.filled(
                            onPressed: () {
                              final text =
                                  controller.text.trim();
                              if (text.isNotEmpty) {
                                store.addComment(
                                  post,
                                  text,
                                  parentId: replyToId,
                                );
                                controller.clear();
                                setModalState(() {
                                  replyToId = null;
                                  replyToName = null;
                                });
                              }
                            },
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
   );
}

void showEditPostDialog(
  BuildContext context,
  CommunityPost post,
) {
  final controller =
      TextEditingController(text: post.content);
  final store = TrueVoiceStore.instance;

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Post content',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tvText('cancel')),
          ),
          FilledButton(
            onPressed: () {
              post.content = controller.text.trim();
              store.updatePost(post);
              Navigator.pop(context);
            },
            child: Text(tvText('save')),
          ),
        ],
      );
    },
    );
}

void confirmDeletePost(
  BuildContext context,
  CommunityPost post,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This will permanently remove the post from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tvText('cancel')),
          ),
          FilledButton(
            onPressed: () {
              TrueVoiceStore.instance.deletePost(post.id);
              Navigator.pop(context);
            },
            child: Text(tvText('delete')),
          ),
        ],
      );
    },
  );
}

// ============================================================
// GROUPS
// ============================================================

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(tvText('groups')),
        actions: [
          IconButton(
            onPressed: () =>
                showCreateGroupDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: store.groups.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final group = store.groups[index];
              return _GroupTile(group: group);
            },
          );
        },
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            group.verificationRequired
                ? Icons.verified_user_outlined
                : Icons.groups_outlined,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${group.members.length} members • ${group.category}',
        ),
                trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            final store = TrueVoiceStore.instance;
            final isAdmin = group.adminName == store.userName;
            final isMember = group.members.contains(store.userName);

            if (value == 'open') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailPage(group: group),
                ),
              );
            } else if (value == 'leave' && isMember && !isAdmin) {
              confirmLeaveGroup(context, group);
            } else if (value == 'delete' && isAdmin) {
              confirmDeleteGroup(context, group);
            }
          },
          itemBuilder: (context) {
            final store = TrueVoiceStore.instance;
            final isAdmin = group.adminName == store.userName;
            final isMember = group.members.contains(store.userName);

            return [
              const PopupMenuItem(
                value: 'open',
                child: Text('Open'),
              ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete group',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (isMember && !isAdmin)
                const PopupMenuItem(
                  value: 'leave',
                  child: Text(
                    'Leave group',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ];
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDetailPage(group: group),
            ),
          );
        },
      ),
    );
  }
}

void showCreateGroupDialog(BuildContext context) {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final rulesController = TextEditingController();
  bool verificationRequired = false;
  String category = 'General';

  showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create a group'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                    ),
                    items: const [
                      'General',
                      'Professional',
                      'Students',
                      'Support',
                      'Caregivers',
                    ]
                        .map((item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => category = v);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rulesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Group rules',
                      hintText: 'Set your own group rules...',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require verification'),
                    subtitle: const Text(
                      'Admins approve members before they join.',
                    ),
                    value: verificationRequired,
                    onChanged: (v) =>
                        setState(() => verificationRequired = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tvText('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  TrueVoiceStore.instance.createGroup(
                    Group(
                      id: TrueVoiceStore.instance.newId(),
                      name: nameController.text.trim(),
                      description:
                          descriptionController.text.trim(),
                      category: category,
                      rules: rulesController.text.trim().isEmpty
                          ? 'Be respectful. No harassment. Protect personal information.'
                          : rulesController.text.trim(),
                      adminName:
                          TrueVoiceStore.instance.userName,
                      verificationRequired: verificationRequired,
                      members: [
                        TrueVoiceStore.instance.userName,
                      ],
                      pendingMembers: [],
                    ),
                  );
                                                      Future.microtask(() {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
                child: const Text('Create'),
              ),
            ],
          );
                },
      );
    },
  );
}

class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({super.key, required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Posts'),
              Tab(text: 'Chat'),
              Tab(text: 'About'),
            ],
          ),
        ),
        body: AnimatedBuilder(
          animation: store,
          builder: (context, child) {
            final isMember =
                group.members.contains(store.userName);
            return TabBarView(
              children: [
                _GroupPostsTab(group: group, isMember: isMember),
                _GroupChatTab(group: group, isMember: isMember),
                _GroupAboutTab(group: group, isMember: isMember),
              ],
            );
          },
        ),
      ),
    );
  }
}

// -------- POSTS TAB --------

class _GroupPostsTab extends StatelessWidget {
  const _GroupPostsTab({
    required this.group,
    required this.isMember,
  });
  final Group group;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    if (!isMember) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Join the group to see posts',
      );
    }

    final posts = store.postsForGroup(group.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: posts.isEmpty
          ? const EmptyState(
              icon: Icons.article_outlined,
              title: 'No posts yet. Be the first!',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PostCard(post: posts[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreatePostDialog(
          context,
          groupId: group.id,
        ),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

// -------- CHAT TAB --------

class _GroupChatTab extends StatefulWidget {
  const _GroupChatTab({
    required this.group,
    required this.isMember,
  });
  final Group group;
  final bool isMember;

  @override
  State<_GroupChatTab> createState() => _GroupChatTabState();
}

class _GroupChatTabState extends State<_GroupChatTab> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMember) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Join the group to see messages',
      );
    }

    final store = TrueVoiceStore.instance;
    final msgs = widget.group.messages;

    return Column(
      children: [
        Expanded(
          child: msgs.isEmpty
              ? const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages yet. Say hello!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final isMe = m.author == store.userName;
                                       return GestureDetector(
                      onLongPress: () {
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete message?'),
                            content: const Text(
                              'This will remove the message from the group.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  store.removeGroupMessage(
                                    widget.group,
                                    m.id,
                                  );
                                  Navigator.pop(dialogContext);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            Avatar(name: m.author, radius: 14),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    m.author,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                                                if (m.audioPath != null &&
                                    m.content == '📷 Photo' &&
                                    File(m.audioPath!)
                                        .existsSync())
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    child: Image.file(
                                      File(m.audioPath!),
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Text(
                                        '(image not available)',
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: Text(m.content),
                                  ),
                                if (m.reactions.isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 3),
                                    child: Wrap(
                                      spacing: 4,
                                      children: m.reactions.entries
                                          .map(
                                            (e) => Text(
                                              '${e.key} ${e.value}',
                                              style: const TextStyle(
                                                  fontSize: 11),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                TextButton(
                                  onPressed: () async {
                                    final emoji =
                                        await showEmojiPicker(
                                            context);
                                    if (emoji != null) {
                                      m.reactions[emoji] =
                                          (m.reactions[emoji] ??
                                                  0) +
                                              1;
                                      store.save();
                                      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                                      store.notifyListeners();
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(30, 20),
                                    tapTargetSize:
                                        MaterialTapTargetSize
                                            .shrinkWrap,
                                  ),
                                  child: const Text(
                                    'React',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () async {
                    final file = await store.picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (file != null) {
                      store.addGroupMessage(
                        widget.group,
                        GroupMessage(
                          id: store.newId(),
                          author: store.userName,
                          content: '📷 Photo',
                          time: 'Just now',
                          isAudio: false,
                          audioPath: file.path,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.photo_outlined),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  onPressed: () {
                    final t = controller.text.trim();
                    if (t.isEmpty) return;
                    store.addGroupMessage(
                      widget.group,
                      GroupMessage(
                        id: store.newId(),
                        author: store.userName,
                        content: t,
                        time: 'Just now',
                      ),
                    );
                    controller.clear();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// -------- ABOUT TAB --------

class _GroupAboutTab extends StatelessWidget {
  const _GroupAboutTab({
    required this.group,
    required this.isMember,
  });
  final Group group;
  final bool isMember;

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;
    final isPending =
        group.pendingMembers.contains(store.userName);
    final isAdmin = group.adminName == store.userName;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CircleAvatar(
          radius: 40,
          child: Icon(
            group.verificationRequired
                ? Icons.verified_user_outlined
                : Icons.groups_outlined,
            size: 40,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          group.name,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(group.description, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (!isMember && !isPending)
          FilledButton(
            onPressed: () {
              store.joinGroup(group);
              showMessage(
                context,
                group.verificationRequired
                    ? 'Membership request sent for verification.'
                    : 'You joined the group.',
              );
            },
            child: Text(
              group.verificationRequired
                  ? tvText('request_to_join')
                  : tvText('join_group'),
            ),
          ),
        if (isPending)
          const Card(
            child: ListTile(
              leading: Icon(Icons.hourglass_top),
              title: Text('Verification pending'),
            ),
          ),
        if (isMember)
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('You are a member'),
            ),
          ),
        const SizedBox(height: 20),
        SectionTitle(title: 'Group rules'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(group.rules),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${group.members.length} members',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (isAdmin && group.pendingMembers.isNotEmpty) ...[
          const SizedBox(height: 20),
          SectionTitle(title: 'Pending members'),
          const SizedBox(height: 8),
          ...group.pendingMembers.map(
            (name) => ListTile(
              leading: Avatar(name: name, radius: 20),
              title: Text(name),
              trailing: FilledButton(
                onPressed: () =>
                    store.approveMember(group, name),
                child: Text(tvText('approve')),
              ),
            ),
          ),
        ],
                const SizedBox(height: 30),
        if (group.adminName == store.userName)
          OutlinedButton.icon(
            onPressed: () => confirmDeleteGroup(context, group),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Group'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
        if (group.adminName != store.userName &&
            group.members.contains(store.userName))
          OutlinedButton.icon(
            onPressed: () {
              confirmLeaveGroup(context, group);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Leave Group'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
            

// ============================================================
// BOOKINGS
// ============================================================

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(tvText('bookings')),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookAppointmentPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          if (store.appointments.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No appointments yet',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: store.appointments.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = store.appointments[i];
              return Card(
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(
                    child:
                        Icon(Icons.calendar_month_outlined),
                  ),
                  title: Text(
                    a.professional,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${a.service}\n${formatDate(a.date)} • ${a.time.format(context)}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    a.status,
                    style: TextStyle(
                      color: a.status == 'Cancelled'
                          ? Colors.red
                          : Theme.of(context)
                              .colorScheme
                              .primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentViewPage(
                          appointment: a,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BookAppointmentPage extends StatelessWidget {
  const BookAppointmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tvText('book_appointment'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: professionals
            .map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ProfessionalTile(
                  professional: p,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailsPage(
                          professional: p,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class AppointmentDetailsPage extends StatefulWidget {
  const AppointmentDetailsPage({
    super.key,
    required this.professional,
  });
  final Professional professional;

  @override
  State<AppointmentDetailsPage> createState() =>
      _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState
    extends State<AppointmentDetailsPage> {
  Service? selectedService;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    final wh = widget.professional.workingHours;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ProfessionalTile(professional: widget.professional),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(tvText('working_hours')),
              subtitle: Text(wh.label),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tvText('select_service'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.professional.services.map(
            (s) => Card(
              child: ListTile(
                leading: Icon(
                  selectedService == s
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedService == s
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(s.name),
                subtitle: Text(
                  s.price == 0
                      ? 'Price to be confirmed'
                      : 'USD ${s.price.toStringAsFixed(0)}',
                ),
                onTap: () =>
                    setState(() => selectedService = s),
              ),
            ),
          ),
          const SizedBox(height: 15),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.calendar_month),
            title: Text(tvText('date')),
            subtitle: Text(
              selectedDate == null
                  ? tvText('select_date')
                  : formatDate(selectedDate!),
            ),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now()
                    .add(const Duration(days: 365)),
                initialDate: DateTime.now(),
              );
              if (d != null) setState(() => selectedDate = d);
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: const Icon(Icons.access_time),
            title: Text(tvText('time')),
            subtitle: Text(
              selectedTime == null
                  ? tvText('select_time')
                  : selectedTime!.format(context),
            ),
                        onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: wh.startHour,
                  minute: 0,
                ),
              );
              if (t != null) {
                setState(() => selectedTime = t);
              }
            },
          ),
          const SizedBox(height: 25),
          FilledButton(
            onPressed: confirmBooking,
            child: Text(tvText('request_appointment')),
          ),
        ],
      ),
    );
  }

  void confirmBooking() {
    if (selectedService == null ||
        selectedDate == null ||
        selectedTime == null) {
      showMessage(
        context,
        'Please select a service, date and time.',
      );
      return;
    }

    // Validate against working hours
    final wh = widget.professional.workingHours;
    if (!wh.isWithin(selectedDate!, selectedTime!)) {
      showMessage(
        context,
        'This time is outside ${widget.professional.name}\'s working hours (${wh.label}).',
      );
      return;
    }

    TrueVoiceStore.instance.addAppointment(
      Appointment(
        id: TrueVoiceStore.instance.newId(),
        professional: widget.professional.name,
        profession: widget.professional.profession,
        service: selectedService!.name,
        date: selectedDate!,
        time: selectedTime!,
        status: 'Pending',
      ),
    );

    showMessage(
      context,
      'Appointment request sent. Waiting for professional approval.',
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }
}

// ============================================================
// APPOINTMENT VIEW
// ============================================================

class AppointmentViewPage extends StatelessWidget {
  const AppointmentViewPage({
    super.key,
    required this.appointment,
  });
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;
    final isPending = appointment.status == 'Pending';
    final isAccepted = appointment.status == 'Accepted';
    final isRejected = appointment.status == 'Rejected';
    final isCancelled = appointment.status == 'Cancelled';

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          InfoCard(
            title: appointment.professional,
            subtitle: appointment.profession,
            icon: Icons.person_outline,
          ),
          InfoCard(
            title: appointment.service,
            subtitle: 'Service',
            icon: Icons.medical_services_outlined,
          ),
          InfoCard(
            title: formatDate(appointment.date),
            subtitle: appointment.time.format(context),
            icon: Icons.calendar_month_outlined,
          ),
          InfoCard(
            title: appointment.status,
            subtitle: 'Appointment status',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 20),
          if (isPending) ...[
            const Text(
              'Professional Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                store.updateAppointmentStatus(
                  appointment,
                  'Accepted',
                );
                showMessage(context, 'Appointment accepted');
              },
              icon: const Icon(Icons.check),
              label: const Text('Accept Appointment'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                store.updateAppointmentStatus(
                  appointment,
                  'Rejected',
                );
                showMessage(context, 'Appointment rejected');
              },
              icon: const Icon(Icons.close),
              label: const Text('Reject Appointment'),
            ),
          ],
          if (isAccepted)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle),
                title: Text(
                  'Appointment Accepted',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'The professional has accepted this appointment.',
                ),
              ),
            ),
          if (isRejected)
            const Card(
              child: ListTile(
                leading: Icon(Icons.cancel),
                title: Text(
                  'Appointment Rejected',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'The professional has rejected this appointment.',
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (!isCancelled && !isRejected)
            FilledButton.tonal(
              onPressed: () {
                store.cancelAppointment(appointment);
                Navigator.pop(context);
              },
              child: const Text('Cancel Appointment'),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFESSIONAL DIRECTORY
// ============================================================

class ProfessionalDirectoryPage extends StatefulWidget {
  const ProfessionalDirectoryPage({
    super.key,
    this.filter,
  });
  final String? filter;

  @override
  State<ProfessionalDirectoryPage> createState() =>
      _ProfessionalDirectoryPageState();
}

class _ProfessionalDirectoryPageState
    extends State<ProfessionalDirectoryPage> {
  final _searchController = TextEditingController();
  String _search = '';
  double? _userLat;
  double? _userLon;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.filter == null
        ? professionals
        : professionals
            .where((p) => p.profession == widget.filter)
            .toList();

        var filtered = _search.isEmpty
        ? base
        : base.where((p) {
            final q = _search.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.profession.toLowerCase().contains(q) ||
                p.location.toLowerCase().contains(q) ||
                p.bio.toLowerCase().contains(q);
          }).toList();

    // If we have user location, sort professionals by distance
    // (using known city coordinates as a rough proxy)
    if (_userLat != null && _userLon != null) {
      final cityCoords = <String, List<double>>{
        'Accra': [5.6037, -0.1870],
        'Kumasi': [6.6885, -1.6244],
        'Ho': [6.6009, 0.4713],
        'Tema': [5.6698, -0.0166],
        'London': [51.5074, -0.1278],
        'Toronto': [43.6532, -79.3832],
        'Madrid': [40.4168, -3.7038],
        'Nairobi': [-1.2921, 36.8219],
        'Mumbai': [19.0760, 72.8777],
        'São Paulo': [-23.5505, -46.6333],
        'Cairo': [30.0444, 31.2357],
        'Lagos': [6.4281, 3.4219],
        'New York': [40.7128, -74.0060],
      };

      double distFor(Professional p) {
        for (final key in cityCoords.keys) {
          if (p.location.contains(key)) {
            final c = cityCoords[key]!;
            return distanceKm(
              _userLat!,
              _userLon!,
              c[0],
              c[1],
            );
          }
        }
        return 999999;
      }

      filtered.sort((a, b) => distFor(a).compareTo(distFor(b)));
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.filter ?? tvText('professionals')),
      ),
            body: Column(
        children: [
          if (_userLat == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final pos = await getUserLocation();
                  if (pos == null) {
                    if (context.mounted) {
                      showMessage(
                        context,
                        'Location permission required.',
                      );
                    }
                    return;
                  }
                  setState(() {
                    _userLat = pos.latitude;
                    _userLon = pos.longitude;
                  });
                  if (context.mounted) {
                    showMessage(
                      context,
                      'Sorted by distance from you.',
                    );
                  }
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Near me'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  const Text('Sorted by distance'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _userLat = null;
                        _userLon = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: tvText('search'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.person_search_outlined,
                    title: 'No professionals found',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        ProfessionalTile(
                      professional: filtered[i],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfessionalProfilePage extends StatelessWidget {
  const ProfessionalProfilePage({
    super.key,
    required this.professional,
  });
  final Professional professional;

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;
    final connected =
        store.connections.contains(professional.name);
    final requestSent =
        store.sentRequests.contains(professional.name);
    final incoming =
        store.incomingRequests.contains(professional.name);

    return Scaffold(
      appBar: AppBar(title: const Text('Professional')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Avatar(name: professional.name, radius: 45),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                professional.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (professional.verified)
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(Icons.verified, size: 20),
                ),
            ],
          ),
          Center(child: Text(professional.profession)),
          Center(
            child: Text(
              professional.location,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 18),
          Text(professional.bio),
          const SizedBox(height: 20),
          // Connect / request states
          if (connected)
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check),
              label: Text(tvText('connected')),
            )
          else if (requestSent)
            OutlinedButton.icon(
              onPressed: () {
                store.cancelConnectionRequest(
                  professional.name,
                );
                showMessage(context, 'Request cancelled.');
              },
              icon: const Icon(Icons.hourglass_top),
              label: Text(tvText('request_sent')),
            )
          else if (incoming)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      store.approveConnection(
                        professional.name,
                      );
                      showMessage(context, 'Connection accepted.');
                    },
                    child: Text(tvText('accept')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      store.denyConnection(
                        professional.name,
                      );
                      showMessage(context, 'Request declined.');
                    },
                    child: Text(tvText('deny')),
                  ),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: () {
                store.sendConnectionRequest(
                  professional.name,
                );
                showMessage(
                  context,
                  'Connection request sent.',
                );
              },
              child: Text(tvText('connect')),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          personName: professional.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined),
                  label: Text(tvText('messages')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailsPage(
                          professional: professional,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(tvText('book')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(tvText('working_hours')),
              subtitle: Text(professional.workingHours.label),
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(title: tvText('services')),
          const SizedBox(height: 10),
          ...professional.services.map(
            (s) => Card(
              child: ListTile(
                leading:
                    const Icon(Icons.medical_services_outlined),
                title: Text(s.name),
                subtitle: Text(
                  s.price == 0
                      ? 'Price to be confirmed'
                      : 'USD ${s.price.toStringAsFixed(0)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showServiceDialog(
                  context,
                  professional.name,
                  s,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FACILITIES
// ============================================================

class FacilityDirectoryPage extends StatefulWidget {
  const FacilityDirectoryPage({
    super.key,
    this.filter,
  });
  final String? filter;

  @override
  State<FacilityDirectoryPage> createState() =>
      _FacilityDirectoryPageState();
}

class _FacilityDirectoryPageState
    extends State<FacilityDirectoryPage> {
    final _searchController = TextEditingController();
  String _search = '';
  double? _userLat;
    // ignore: unused_field
  double? _userLon;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Facility> filtered;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = facilities.where((f) {
        return f.name.toLowerCase().contains(q) ||
            f.type.toLowerCase().contains(q) ||
            f.location.toLowerCase().contains(q);
      }).toList();
    } else if (widget.filter != null) {
      filtered = facilities
          .where((f) => f.type == widget.filter)
          .toList();
    } else {
      filtered = facilities;
    }

    final freelanceMatches = _search.isEmpty
        ? <FreelanceService>[]
        : TrueVoiceStore.instance.freelanceServices.where((f) {
            final q = _search.toLowerCase();
            return f.title.toLowerCase().contains(q) ||
                f.category.toLowerCase().contains(q) ||
                f.providerName.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filter ?? tvText('facilities')),
      ),
      body: Column(
        children: [
                    if (_userLat == null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: OutlinedButton.icon(
                onPressed: () async {
                  final pos = await getUserLocation();
                  if (pos == null) {
                    if (context.mounted) {
                      showMessage(
                        context,
                        'Location permission required.',
                      );
                    }
                    return;
                  }
                  setState(() {
                    _userLat = pos.latitude;
                    _userLon = pos.longitude;
                  });
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Near me'),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  const Text('Sorted by distance'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _userLat = null;
                        _userLon = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: tvText('search'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (filtered.isNotEmpty) ...[
                  if (freelanceMatches.isNotEmpty) ...[
                    SectionTitle(title: tvText('facilities')),
                    const SizedBox(height: 8),
                  ],
                  ...filtered.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FacilityTile(facility: f),
                    ),
                  ),
                ],
                if (freelanceMatches.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionTitle(title: tvText('freelance')),
                  const SizedBox(height: 8),
                  ...freelanceMatches.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FreelanceTile(service: f),
                    ),
                  ),
                ],
                if (filtered.isEmpty && freelanceMatches.isEmpty)
                  const EmptyState(
                    icon: Icons.local_hospital_outlined,
                    title: 'No facilities found',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({required this.facility});
  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.local_hospital_outlined),
        ),
        title: Text(
          facility.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${facility.type}\n${facility.location}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FacilityProfilePage(
                facility: facility,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FreelanceTile extends StatelessWidget {
  const _FreelanceTile({required this.service});
  final FreelanceService service;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showFreelanceDetail(context, service);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(name: service.providerName, radius: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          service.providerName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                service.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(service.category),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Text(
                    'USD ${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                service.location,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class FacilityProfilePage extends StatelessWidget {
  const FacilityProfilePage({
    super.key,
    required this.facility,
  });
  final Facility facility;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facility')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 42,
            child: Icon(
              Icons.local_hospital_outlined,
              size: 42,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            facility.name,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Center(child: Text(facility.type)),
          const SizedBox(height: 20),
          InfoCard(
            title: tvText('location'),
            subtitle: facility.address,
            icon: Icons.location_on_outlined,
            onTap: () => showInfoDialog(
              context,
              tvText('location'),
              facility.address,
            ),
          ),
          InfoCard(
            title: tvText('opening_hours'),
            subtitle: facility.hours,
            icon: Icons.access_time,
            onTap: () => showInfoDialog(
              context,
              tvText('opening_hours'),
              facility.hours,
            ),
          ),
          InfoCard(
            title: tvText('contact'),
            subtitle: facility.phone,
            icon: Icons.phone_outlined,
            onTap: () => showInfoDialog(
              context,
              tvText('contact'),
              '${facility.phone}\n${facility.email}',
            
            ),
          ),

                    FilledButton.tonalIcon(
            onPressed: () {
              // Placeholder — will link to Maps later
              showMessage(
                context,
                'Opening directions to ${facility.address}...',
              );
            },
            icon: const Icon(Icons.directions_outlined),
            label: const Text('Get Directions'),
          ),

          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: () =>
                showFacilityBookingDialog(context, facility),
            icon: const Icon(Icons.calendar_month),
            label: Text(tvText('book_service')),
          ),
          const SizedBox(height: 20),
          SectionTitle(title: tvText('services')),
          const SizedBox(height: 10),
          ...facility.services.map(
            (s) => Card(
              child: ListTile(
                title: Text(s.name),
                subtitle: Text(
                  s.price == 0
                      ? 'Price to be confirmed'
                      : 'USD ${s.price.toStringAsFixed(0)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showServiceDialog(
                  context,
                  facility.name,
                  s,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MESSAGES
// ============================================================

class ChatMessage {
  ChatMessage.text(this.content)
      : audioPath = null,
        imagePath = null,
        reactions = {};
  ChatMessage.audio(this.audioPath)
      : content = null,
        imagePath = null,
        reactions = {};
  ChatMessage.image(this.imagePath)
      : content = null,
        audioPath = null,
        reactions = {};

  final String? content;
  final String? audioPath;
  final String? imagePath;
  final Map<String, int> reactions;

  bool get isAudio => audioPath != null;
  bool get isImage => imagePath != null;
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const people = [
      'Dr. Sarah Mensah',
      'Michael Addo',
      'Ama Boateng',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tvText('messages'))),
      body: ListView(
        children: people
            .map(
              (name) => ListTile(
                                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(
                          userName: name,
                          profession: 'Community member',
                        ),
                      ),
                    );
                  },
                  child: Avatar(name: name, radius: 22),
                ),
                title: Text(name),
                subtitle: const Text('Start a conversation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        personName: name,
                      ),
                    ),
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.personName});
  final String personName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final AudioRecorder recorder = AudioRecorder();
  final List<ChatMessage> messages = [
    ChatMessage.text('Hello! Welcome to TrueVoice.'),
  ];
  bool isRecording = false;

  @override
  void dispose() {
    controller.dispose();
    recorder.dispose();
    super.dispose();
  }

  Future<void> toggleRecording() async {
    if (isRecording) {
      final path = await recorder.stop();
      setState(() => isRecording = false);
      if (path != null && File(path).existsSync()) {
        setState(() =>
            messages.add(ChatMessage.audio(path)));
      }
      return;
    }
    try {
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          showMessage(
            context,
            'Microphone permission is required to send an audio message.',
          );
        }
        return;
      }
      final path =
          '${Directory.systemTemp.path}/truevoice_audio_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await recorder.start(const RecordConfig(), path: path);
      setState(() => isRecording = true);
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Unable to start audio recording.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.personName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final m = messages[index];
                                return Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onLongPress: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete message?'),
                          content: const Text(
                            'This will remove the message from your chat.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  messages.removeAt(index);
                                });
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                                            if (m.isAudio)
                        AudioMessageBubble(path: m.audioPath!)
                      else if (m.isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(m.imagePath!),
                            width: 220,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Text(
                              '(image not available)',
                            ),
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                          child: Text(m.content ?? ''),
                        ),
                      if (m.reactions.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: m.reactions.entries
                              .map(
                                (e) => Text(
                                  '${e.key} ${e.value}',
                                  style: const TextStyle(
                                      fontSize: 12),
                                ),
                              )
                              .toList(),
                        ),
                      TextButton(
                        onPressed: () async {
                          final emoji =
                              await showEmojiPicker(context);
                          if (emoji != null) {
                            setState(() {
                              m.reactions[emoji] =
                                  (m.reactions[emoji] ?? 0) + 1;
                            });
                          }
                        },
                        child: const Text(
                          'React',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
          if (isRecording)
            Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color:
                    Theme.of(context).colorScheme.errorContainer,
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Recording audio… tap the microphone to send.',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await recorder.cancel();
                      setState(() => isRecording = false);
                    },
                    child: Text(tvText('cancel')),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                                IconButton(
                  onPressed: toggleRecording,
                  style: IconButton.styleFrom(
                    backgroundColor: isRecording
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                  ),
                  icon: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color:
                        isRecording ? Colors.white : null,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () async {
                    final file = await TrueVoiceStore.instance.picker
                        .pickImage(
                      source: ImageSource.gallery,
                    );
                    if (file != null) {
                      setState(() {
                        messages.add(ChatMessage.image(file.path));
                      });
                    }
                  },
                  icon: const Icon(Icons.photo_outlined),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    final t = controller.text.trim();
                    if (t.isNotEmpty) {
                      setState(() =>
                          messages.add(ChatMessage.text(t)));
                      controller.clear();
                    }
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AudioMessageBubble extends StatefulWidget {
  const AudioMessageBubble({
    super.key,
    required this.path,
  });
  final String path;

  @override
  State<AudioMessageBubble> createState() =>
      _AudioMessageBubbleState();
}

class _AudioMessageBubbleState
    extends State<AudioMessageBubble> {
  final AudioPlayer player = AudioPlayer();
  bool playing = false;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> togglePlayback() async {
    if (playing) {
      await player.pause();
      setState(() => playing = false);
      return;
    }
    if (!File(widget.path).existsSync()) {
      showMessage(
        context,
        'This audio file is no longer available.',
      );
      return;
    }
    await player.play(DeviceFileSource(widget.path));
    setState(() => playing = true);
    player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: togglePlayback,
            icon: Icon(
              playing ? Icons.pause : Icons.play_arrow,
            ),
          ),
          const Text('Voice message'),
          const SizedBox(width: 5),
          const Icon(Icons.graphic_eq),
        ],
      ),
    );
  }
}

// ============================================================
// NOTIFICATIONS
// ============================================================

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.favorite_outline),
            ),
            title: Text('Your community is active'),
            subtitle: Text(
              'People are interacting with healthcare content.',
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.groups_outlined),
            ),
            title: Text('Explore groups'),
            subtitle: Text(
              'Find communities that match your interests.',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ProfileAvatar(
                  path: store.profileImagePath,
                  name: store.userName,
                  radius: 48,
                ),
              ),
              const SizedBox(height: 12),
                            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      store.userName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (store.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                ],
              ),
                            Text(
                store.userProfession,
                textAlign: TextAlign.center,
              ),
              Text(
                store.userLocation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                  children: [
                    _StatBlock(
                      label: 'Posts',
                      value: store.posts
                          .where((p) =>
                              p.name == store.userName)
                          .length
                          .toString(),
                    ),
                    _StatBlock(
                      label: 'Connections',
                      value: store.connections.length.toString(),
                    ),
                    _StatBlock(
                      label: 'Bookings',
                      value:
                          store.appointments.length.toString(),
                    ),
                    _StatBlock(
                      label: 'Saved',
                      value:
                          store.savedPostIds.length.toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    showEditProfileDialog(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
              ),

              const SizedBox(height: 20),
              ProfileMenuTile(
                icon: Icons.message_outlined,
                title: tvText('messages'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MessagesPage(),
                    ),
                  );
                },
              ),
                            ProfileMenuTile(
                icon: Icons.auto_awesome,
                title: 'Ask TrueVoice AI',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AIAssistantPage(),
                    ),
                  );
                },
              ),

                            ProfileMenuTile(
                icon: Icons.verified_user_outlined,
                title: store.isVerified
                    ? 'Verified Professional'
                    : 'Become Verified',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BecomeVerifiedPage(),
                    ),
                  );
                },
              ),

                            if (TrueVoiceStore
                  .instance.pendingVerifications
                  .any((v) => v.status == 'Pending'))
                ProfileMenuTile(
                  icon: Icons.how_to_reg_outlined,
                  title: 'Pending Verifications',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const PendingVerificationsPage(),
                      ),
                    );
                  },
                ),
              
              ProfileMenuTile(
                icon: Icons.photo_library_outlined,
                title: 'My Gallery',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProfileGalleryPage(),
                    ),
                  );
                },
              ),

              ProfileMenuTile(
                icon: Icons.bookmark_outline,
                title: 'Saved Posts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavedPostsPage(),
                    ),
                  );
                },
              ),
              ProfileMenuTile(
                icon: Icons.people_outline,
                title: 'Connections',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectionsPage(),
                    ),
                  );
                },
              ),
              ProfileMenuTile(
                icon: Icons.groups_outlined,
                title: 'My Groups',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GroupsPage(),
                    ),
                  );
                },
              ),
              ProfileMenuTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
              ),
              ProfileMenuTile(
                icon: Icons.lock_outline,
                title: 'Privacy & Security',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPage(),
                    ),
                  );
                },
              ),
              ProfileMenuTile(
                icon: Icons.payments_outlined,
                title: 'Payments',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentsPage(),
                    ),
                  );
                },
              ),
              ProfileMenuTile(
                icon: Icons.info_outline,
                title: tvText('about'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'TrueVoice',
                  applicationVersion: 'Prototype',
                  applicationLegalese: tvText('about_text'),
                ),
              ),
                            ProfileMenuTile(
                icon: Icons.logout,
                title: 'Log out',
                onTap: () => logout(context),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// EDIT PROFILE
// ============================================================

void showEditProfileDialog(BuildContext context) {
  final store = TrueVoiceStore.instance;
  final nameController =
      TextEditingController(text: store.userName);
  final professionController =
      TextEditingController(text: store.userProfession);
  final locationController =
      TextEditingController(text: store.userLocation);
  final bioController =
      TextEditingController(text: store.userBio);

  showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> choosePicture() async {
            final file = await store.picker.pickImage(
              source: ImageSource.gallery,
            );
            if (file != null) {
              store.setProfileImage(file.path);
              setState(() {});
            }
          }

          return AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  ProfileAvatar(
                    path: store.profileImagePath,
                    name: store.userName,
                    radius: 42,
                  ),
                  TextButton.icon(
                    onPressed: choosePicture,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Change picture'),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: professionController,
                    decoration: const InputDecoration(
                      labelText: 'Profession',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tvText('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  store.updateProfile(
                    name: nameController.text.trim(),
                    profession:
                        professionController.text.trim(),
                    location:
                        locationController.text.trim(),
                    bio: bioController.text.trim(),
                  );
                                    Future.microtask(() {
                    if (context.mounted) Navigator.pop(context);
                  });
                },
                child: Text(tvText('save')),
              ),
            ],
          );
                },
      );
    },
  );
}

// ============================================================
// SAVED / CONNECTIONS
// ============================================================

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Posts')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final saved =
              store.posts.where((p) => p.saved).toList();
          if (saved.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_outline,
              title: 'No saved posts',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: saved.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _PostCard(post: saved[i]),
          );
        },
      ),
    );
  }
}

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (store.incomingRequests.isNotEmpty) ...[
                SectionTitle(title: 'Requests'),
                const SizedBox(height: 8),
                ...store.incomingRequests.map(
                  (name) => Card(
                    child: ListTile(
                      leading: Avatar(name: name, radius: 22),
                      title: Text(name),
                      subtitle: const Text(
                          'wants to connect with you'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                                                    IconButton(
                            onPressed: () =>
                                store.approveConnection(name),
                            icon: const Icon(Icons.check),
                          ),
                          IconButton(
                            onPressed: () =>
                                store.denyConnection(name),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (store.sentRequests.isNotEmpty) ...[
                SectionTitle(title: 'Sent requests'),
                const SizedBox(height: 8),
                ...store.sentRequests.map(
                  (name) => Card(
                    child: ListTile(
                      leading: Avatar(name: name, radius: 22),
                      title: Text(name),
                      subtitle: const Text('Waiting for approval'),
                      trailing: TextButton(
                        onPressed: () =>
                            store.cancelConnectionRequest(name),
                        child: Text(tvText('cancel')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SectionTitle(title: 'Your connections'),
              const SizedBox(height: 8),
              if (store.connections.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No connections yet',
                )
              else
                ...store.connections.map(
                  (name) => ListTile(
                    leading: Avatar(name: name, radius: 22),
                    title: Text(name),
                    trailing: const Icon(Icons.check_circle),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text(
                  'Receive TrueVoice notifications',
                ),
                value: store.notificationsEnabled,
                onChanged: store.setNotifications,
              ),
              SwitchListTile(
                title: const Text('Show online status'),
                value: store.showOnlineStatus,
                onChanged: store.setOnlineStatus,
              ),
              SwitchListTile(
                title: const Text('Allow messages'),
                subtitle: const Text(
                  'Allow connected users to message you',
                ),
                value: store.allowMessages,
                onChanged: store.setAllowMessages,
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(selectedLanguageName()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLanguageDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Payments'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PaymentsPage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

String selectedLanguageName() {
  final code = currentLanguageCode();
  return supportedLanguages
      .firstWhere(
        (l) => l.code == code,
        orElse: () => supportedLanguages.first,
      )
      .name;
}

void showLanguageDialog(BuildContext context) {
  final store = TrueVoiceStore.instance;

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('App language'),
        content: SingleChildScrollView(
          child: RadioGroup<String>(
            groupValue: currentLanguageCode(),
            onChanged: (value) {
              if (value == null) return;
              store.setLanguage(value);
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: supportedLanguages
                  .map(
                    (language) => RadioListTile<String>(
                      value: language.code,
                      title: Text(language.name),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    },
  );
}

// ============================================================
// PRIVACY
// ============================================================

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Private profile'),
                subtitle: const Text(
                  'Limit who can see your profile',
                ),
                value: store.privateProfile,
                onChanged: store.setPrivateProfile,
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Blocked users'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BlockedUsersPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export my data'),
                subtitle: const Text(
                  'Create a copy of your TrueVoice data',
                ),
                onTap: () => showDataExport(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          if (store.blockedUsers.isEmpty) {
            return const EmptyState(
              icon: Icons.block,
              title: 'No blocked users',
            );
          }
          return ListView(
            children: store.blockedUsers
                .map(
                  (name) => ListTile(
                    title: Text(name),
                    trailing: TextButton(
                      onPressed: () => store.unblock(name),
                      child: const Text('Unblock'),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

void showDataExport(BuildContext context) {
  final store = TrueVoiceStore.instance;

  final data = jsonEncode({
    'profile': {
      'name': store.userName,
      'profession': store.userProfession,
      'location': store.userLocation,
      'bio': store.userBio,
    },
    'posts': store.posts.map((e) => e.toMap()).toList(),
    'groups': store.groups.map((e) => e.toMap()).toList(),
    'appointments':
        store.appointments.map((e) => e.toMap()).toList(),
    'connections': store.connections.toList(),
  });

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Your data'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(data),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: data),
              );
              if (context.mounted) {
                showMessage(
                  context,
                  'Data copied to clipboard.',
                );
              }
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

// ============================================================
// PAYMENTS
// ============================================================

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final List<String> methods = ['No payment method added'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...methods.map(
            (m) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.credit_card_outlined,
                ),
                title: Text(m),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              setState(() {
                methods
                  ..clear()
                  ..add('Demo payment method');
              });
              showMessage(
                context,
                'Demo payment method added.',
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Real payment processing will be connected in the production version.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
  });
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfessionalTile extends StatelessWidget {
  const ProfessionalTile({
    super.key,
    required this.professional,
    this.onTap,
  });
  final Professional professional;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Avatar(name: professional.name, radius: 25),
        title: Row(
          children: [
            Flexible(
              child: Text(
                professional.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (professional.verified)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.verified, size: 17),
              ),
          ],
        ),
        subtitle: Text(
          '${professional.profession}\n${professional.location}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfessionalProfilePage(
                    professional: professional,
                  ),
                ),
              );
            },
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.radius,
  });
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isEmpty ? '?' : name[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: radius * .65,
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.path,
    required this.name,
    required this.radius,
  });
  final String? path;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p != null && p.isNotEmpty && File(p).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(p),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              Avatar(name: name, radius: radius),
        ),
      );
    }
    return Avatar(name: name, radius: radius);
  }
}

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
  });
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class MediaAttachment extends StatelessWidget {
  const MediaAttachment({super.key, required this.post});
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final path = post.mediaPath;
    if (path == null) return const SizedBox.shrink();

    if (post.mediaType == 'image' && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(path),
          height: 240,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.video_file_outlined, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Video attachment\n${File(path).uri.pathSegments.last}',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIALOGS & HELPERS
// ============================================================

void showServiceDialog(
  BuildContext context,
  String provider,
  Service service,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.name,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Provider: $provider'),
            const SizedBox(height: 5),
            Text(
              service.price == 0
                  ? 'Price to be confirmed'
                  : 'Price: USD ${service.price.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  showMessage(
                    context,
                    'You can book this service from the appointment section.',
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showFacilityBookingDialog(
  BuildContext context,
  Facility facility,
) {
  if (facility.services.isEmpty) return;
  Service selected = facility.services.first;

  showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Book at ${facility.name}'),
            content: DropdownButtonFormField<Service>(
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: 'Service',
              ),
              items: facility.services
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => selected = v);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tvText('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  final now = DateTime.now();
                  TrueVoiceStore.instance.addAppointment(
                    Appointment(
                      id: TrueVoiceStore.instance.newId(),
                      professional: facility.name,
                      profession: facility.type,
                      service: selected.name,
                      date:
                          now.add(const Duration(days: 1)),
                      time: const TimeOfDay(
                        hour: 9,
                        minute: 0,
                      ),
                      status: 'Pending',
                      facility: facility.name,
                    ),
                  );
                  Navigator.pop(context);
                  showMessage(
                    context,
                    'Facility service booking request created.',
                  );
                },
                child: Text(tvText('book')),
              ),
            ],
          );
        },
      );
    },
  );
}

void showInfoDialog(
  BuildContext context,
  String title,
  String content,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message)),
    );
}

String formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

// ============================================================
// ============================================================
// AI ASSISTANT (mock — offline, pre-written answers)
// ============================================================

class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  final List<_AIMessage> messages = [
    _AIMessage(
      text:
          'Hi! I\'m TrueVoice AI. Ask me anything about the app, health topics, or finding a professional.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(_AIMessage(text: text, isUser: true));
      messages.add(
        _AIMessage(
          text: _aiReply(text),
          isUser: false,
        ),
      );
    });
    controller.clear();
    _scrollDown();
  }

  String _aiReply(String input) {
    final q = input.toLowerCase();

    if (RegExp(r'\b(hi|hello|hey|good morning|good evening)\b')
        .hasMatch(q)) {
      return 'Hi there! I\'m here to help you navigate TrueVoice and understand health topics.\n\n'
          'Try asking me:\n'
          '• How do I book an appointment?\n'
          '• Find a nurse near me\n'
          '• What is TrueVoice?\n'
          '• How do I join a group?';
    }

    if (q.contains('book') || q.contains('appointment')) {
      return 'To book an appointment:\n\n'
          '1. Tap the "Bookings" tab at the bottom, or "Book Appointment" on Home.\n'
          '2. Choose a professional from the list.\n'
          '3. Select a service, date, and time.\n'
          '4. Times must fall within their working hours.\n'
          '5. Tap "Request Appointment".';
    }

    if ((q.contains('find') && q.contains('professional')) ||
        q.contains('find a doctor') ||
        q.contains('find a nurse') ||
        q.contains('find a therapist')) {
      return 'Finding a professional:\n\n'
          '• Home → "Find a Professional"\n'
          '• Or Discover → tap a category\n'
          '• Or search by name, profession, or location.\n\n'
          'Available: Doctors, Nurses, Pharmacists, Dentists, Audiologists, Speech Therapists, Physiotherapists, Psychologists, Dietitians.';
    }

    if (q.contains('facility') ||
        q.contains('hospital') ||
        q.contains('clinic') ||
        q.contains('pharmacy') ||
        q.contains('lab')) {
      return 'Finding a facility:\n\n'
          '• Home → "Find a Facility"\n'
          '• Or Discover → Healthcare facilities\n'
          '• Filter: Hospitals, Pharmacies, Labs, Imaging\n\n'
          'Tap any facility to see location, hours and services.';
    }

    if (q.contains('freelance') || q.contains('home visit')) {
      return 'Freelance services on TrueVoice:\n\n'
          '• Home nursing\n'
          '• Physiotherapy at home\n'
          '• Counselling\n'
          '• Health consultations\n\n'
          'Find them in Discover → Freelance Services.';
    }

    if (q.contains('group') || q.contains('community')) {
      return 'Groups in TrueVoice:\n\n'
          '• Community tab → tap the groups icon\n'
          '• Or Profile → My Groups\n\n'
          'Each group has: Posts, Chat, and About tabs.';
    }

    if (q.contains('post') ||
        q.contains('comment') ||
        q.contains('react')) {
      return 'Posts & comments:\n\n'
          '• Create a post: Community tab → + icon\n'
          '• Add photo or video when posting\n'
          '• Comment: tap comment icon\n'
          '• Reply: tap "Reply" under a comment\n'
          '• React: tap "React" and pick emoji';
    }

    if (q.contains('message') ||
        q.contains('chat') ||
        q.contains('voice')) {
      return 'Messaging:\n\n'
          '• Profile → Messages → tap a person\n'
          '• Send text, photos or voice notes\n'
          '• Long-press a message to delete it';
    }

    if (q.contains('connect') || q.contains('request')) {
      return 'Connecting:\n\n'
          '• Open any profile → tap "Connect"\n'
          '• When accepted, you become connections\n'
          '• You can then message each other\n\n'
          'Manage in Profile → Connections.';
    }

    if (q.contains('verif') ||
        q.contains('badge') ||
        q.contains('license')) {
      return 'Verification:\n\n'
          '• Profile → "Become Verified"\n'
          '• Submit name, profession, license, issuer, country\n'
          '• Admin reviews the request\n'
          '• Once approved: blue tick appears';
    }

    if (q.contains('language')) {
      return 'Language:\n\n'
          '• Profile → Settings → Language\n'
          '• Supported: English, French, Spanish, Portuguese, German, Arabic, Swahili';
    }

    if (q.contains('blood pressure') || q.contains('hypertension')) {
      return 'High blood pressure:\n\n'
          '• Often no symptoms\n'
          '• Reduce salt, manage stress, exercise\n'
          '• Take prescribed medication\n\n'
          'I can\'t diagnose. Book a doctor on TrueVoice for advice.';
    }

    if (q.contains('diabetes') || q.contains('sugar')) {
      return 'Diabetes:\n\n'
          '• Type 1 (autoimmune) and Type 2 (lifestyle)\n'
          '• Symptoms: thirst, fatigue, blurred vision\n'
          '• Managed with diet, exercise, medication\n\n'
          'See a doctor for diagnosis.';
    }

    if (q.contains('malaria')) {
      return 'Malaria:\n\n'
          '• Spread by mosquito bites\n'
          '• Symptoms: fever, chills, headache\n'
          '• Seek medical care urgently\n'
          '• Prevent with treated nets and repellents';
    }

    if (q.contains('speech') || q.contains('stutter')) {
      return 'Speech & language therapy:\n\n'
          '• Helps with speech, language, fluency, swallowing\n'
          '• Early intervention matters\n\n'
          'Find a therapist: Discover → Speech & Language Therapists.';
    }

    if (q.contains('hearing') || q.contains('ear')) {
      return 'Hearing health:\n\n'
          '• Hearing loss often develops gradually\n'
          '• Get checked regularly\n\n'
          'Find an audiologist: Discover → Audiologists.';
    }

    if (q.contains('mental') ||
        q.contains('depress') ||
        q.contains('anxiety') ||
        q.contains('stress')) {
      return 'Mental health:\n\n'
          '• Mental health is health\n'
          '• Asking for help is a strength\n\n'
          'Find a psychologist via Home → Find a Professional.\n\n'
          'In crisis? Contact emergency services.';
    }

    if (q.contains('diet') ||
        q.contains('nutrition') ||
        q.contains('weight')) {
      return 'Nutrition:\n\n'
          '• Small, consistent changes beat drastic diets\n'
          '• Focus on vegetables, fruit, whole grains, water\n'
          '• Limit sugary drinks and processed foods\n\n'
          'Find a dietitian: Discover → Dietitians.';
    }

    if (q.contains('medication') ||
        q.contains('medicine') ||
        q.contains('pill')) {
      return 'Medication tips:\n\n'
          '• Take as prescribed\n'
          '• Finish antibiotic courses\n'
          '• Check interactions with a pharmacist';
    }

    if (q.contains('health') ||
        q.contains('symptom') ||
        q.contains('pain') ||
        q.contains('sick')) {
      return 'I can share general health info, but I can\'t diagnose.\n\n'
          'For symptoms, speak to a professional:\n'
          '• Home → Find a Professional\n'
          '• Severe symptoms? Seek emergency care.\n\n'
          'Try asking about "diabetes", "hearing health", "mental health", etc.';
    }

    if (q.contains('truevoice') ||
        q.contains('about') ||
        q.contains('what is')) {
      return 'TrueVoice is a health community app for patients, professionals, students and caregivers worldwide.\n\n'
          'It informs. It connects. It does not diagnose.\n\n'
          'Features: community feed, groups, direct messages, professional & facility directories, freelance services, multi-language, verification.';
    }

    return 'I\'m not sure about that yet.\n\n'
        'Try asking:\n'
        '• How do I book?\n'
        '• Find a nurse\n'
        '• What is diabetes?\n'
        '• How do I join a group?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask TrueVoice AI'),
      ),
      body: Column(
        children: [
          if (messages.length <= 1)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  _AIChip(
                    text: 'How do I book?',
                    onSend: (t) {
                      controller.text = t;
                      send();
                    },
                  ),
                  _AIChip(
                    text: 'Find a doctor',
                    onSend: (t) {
                      controller.text = t;
                      send();
                    },
                  ),
                  _AIChip(
                    text: 'What is TrueVoice?',
                    onSend: (t) {
                      controller.text = t;
                      send();
                    },
                  ),
                  _AIChip(
                    text: 'Mental health tips',
                    onSend: (t) {
                      controller.text = t;
                      send();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                return Align(
                  alignment: m.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width *
                              0.78,
                    ),
                    decoration: BoxDecoration(
                      color: m.isUser
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask anything…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIMessage {
  _AIMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _AIChip extends StatelessWidget {
  const _AIChip({
    required this.text,
    required this.onSend,
  });
  final String text;
  final void Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text),
        onPressed: () => onSend(text),
      ),
    );
  }
}



// ============================================================
// VERIFICATION
// ============================================================

class VerificationRequest {
  VerificationRequest({
    required this.id,
    required this.fullName,
    required this.profession,
    required this.licenseNumber,
    required this.issuingBody,
    required this.country,
    this.licenseImagePath,
    this.status = 'Pending',
        DateTime? submittedAt,
  }) : submittedAt = submittedAt ?? DateTime.now();

  final String id;
  final String fullName;
  final String profession;
  final String licenseNumber;
  final String issuingBody;
  final String country;
  final String? licenseImagePath;
  String status;
  final DateTime submittedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'profession': profession,
        'licenseNumber': licenseNumber,
        'issuingBody': issuingBody,
        'country': country,
        'licenseImagePath': licenseImagePath,
        'status': status,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory VerificationRequest.fromMap(Map<String, dynamic> map) {
    return VerificationRequest(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      profession: map['profession'] as String,
      licenseNumber: map['licenseNumber'] as String,
      issuingBody: map['issuingBody'] as String,
      country: map['country'] as String,
      licenseImagePath: map['licenseImagePath'] as String?,
      status: map['status'] as String? ?? 'Pending',
      submittedAt: DateTime.parse(
        map['submittedAt'] as String,
      ),
    );
  }
}

// ============================================================
// VERIFICATION SCREEN
// ============================================================

const List<String> kHealthProfessions = [
  'General Practitioner',
  'Specialist Doctor',
  'Surgeon',
  'Registered Nurse',
  'Midwife',
  'Pharmacist',
  'Pharmacy Technician',
  'Dentist',
  'Dental Hygienist',
  'Audiologist',
  'Speech & Language Therapist',
  'Physiotherapist',
  'Occupational Therapist',
  'Psychologist',
  'Psychiatrist',
  'Counsellor',
  'Dietitian',
  'Nutritionist',
  'Radiographer',
  'Laboratory Scientist',
  'Optometrist',
  'Optician',
  'Paramedic',
  'Public Health Officer',
  'Health Educator',
  'Community Health Worker',
  'Healthcare Student',
  'Other',
];

const List<String> kCountries = [
  'Ghana', 'Nigeria', 'Kenya', 'South Africa', 'Egypt',
  'United States', 'United Kingdom', 'Canada', 'Germany',
  'France', 'Spain', 'Portugal', 'Brazil', 'India',
  'China', 'Japan', 'Australia', 'Other',
];

class BecomeVerifiedPage extends StatefulWidget {
  const BecomeVerifiedPage({super.key});

  @override
  State<BecomeVerifiedPage> createState() => _BecomeVerifiedPageState();
}

class _BecomeVerifiedPageState extends State<BecomeVerifiedPage> {
  final fullNameController = TextEditingController();
  final licenseController = TextEditingController();
  final bodyController = TextEditingController();

  String profession = kHealthProfessions.first;
  String country = kCountries.first;
  String? licenseImagePath;

  @override
  void initState() {
    super.initState();
    fullNameController.text = TrueVoiceStore.instance.userName;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    licenseController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> pickLicenseImage() async {
    final file = await TrueVoiceStore.instance.picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      setState(() => licenseImagePath = file.path);
    }
  }

  void submit() {
    if (fullNameController.text.trim().isEmpty ||
        licenseController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      showMessage(
        context,
        'Please fill all fields.',
      );
      return;
    }

    final store = TrueVoiceStore.instance;
    final request = VerificationRequest(
      id: store.newId(),
      fullName: fullNameController.text.trim(),
      profession: profession,
      licenseNumber: licenseController.text.trim(),
      issuingBody: bodyController.text.trim(),
      country: country,
      licenseImagePath: licenseImagePath,
    );
    store.submitVerification(request);

    showMessage(
      context,
      'Verification request submitted. You will be notified once reviewed.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Become Verified')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final existing = store.myVerificationRequest;

          if (existing != null) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Icon(
                  existing.status == 'Approved'
                      ? Icons.verified
                      : existing.status == 'Rejected'
                          ? Icons.cancel
                          : Icons.hourglass_top,
                  size: 60,
                  color: existing.status == 'Approved'
                      ? Colors.green
                      : existing.status == 'Rejected'
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  existing.status == 'Approved'
                      ? 'You are verified!'
                      : existing.status == 'Rejected'
                          ? 'Verification rejected'
                          : 'Verification pending',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                InfoCard(
                  title: 'Name',
                  subtitle: existing.fullName,
                  icon: Icons.person_outline,
                ),
                InfoCard(
                  title: 'Profession',
                  subtitle: existing.profession,
                  icon: Icons.work_outline,
                ),
                InfoCard(
                  title: 'License number',
                  subtitle: existing.licenseNumber,
                  icon: Icons.badge_outlined,
                ),
                InfoCard(
                  title: 'Issuing body',
                  subtitle: existing.issuingBody,
                  icon: Icons.account_balance_outlined,
                ),
                InfoCard(
                  title: 'Country',
                  subtitle: existing.country,
                  icon: Icons.public,
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Submit your professional credentials for review. Once approved, you will receive a blue verified badge on your profile and posts.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full name (as on license)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: profession,
                decoration: const InputDecoration(
                  labelText: 'Profession',
                ),
                items: kHealthProfessions
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => profession = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: licenseController,
                decoration: const InputDecoration(
                  labelText: 'License / registration number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Issuing body',
                  hintText: 'e.g. Medical and Dental Council',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: country,
                decoration: const InputDecoration(
                  labelText: 'Country',
                ),
                items: kCountries
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => country = v);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: pickLicenseImage,
                icon: const Icon(Icons.photo_outlined),
                label: Text(
                  licenseImagePath == null
                      ? 'Upload license photo (optional)'
                      : 'License photo selected',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: submit,
                child: const Text('Submit for Verification'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================
// ADMIN: PENDING VERIFICATIONS
// ============================================================

class PendingVerificationsPage extends StatelessWidget {
  const PendingVerificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Verifications')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, child) {
          final pending = store.pendingVerifications
              .where((v) => v.status == 'Pending')
              .toList();

          if (pending.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_user_outlined,
              title: 'No pending verifications',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final v = pending[i];
              return Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(v.profession),
                      const SizedBox(height: 8),
                      Text('License: ${v.licenseNumber}'),
                      Text('Issuer: ${v.issuingBody}'),
                      Text('Country: ${v.country}'),
                      if (v.licenseImagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(v.licenseImagePath!),
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                store.approveVerification(v.id);
                                showMessage(
                                  context,
                                  'Approved.',
                                );
                              },
                              child: const Text('Approve'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                store.rejectVerification(v.id);
                                showMessage(
                                  context,
                                  'Rejected.',
                                );
                              },
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// ============================================================
// GROUP CONFIRM DIALOGS
// ============================================================

void confirmDeleteGroup(BuildContext context, Group group) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete group?'),
        content: Text(
          'This will permanently delete "${group.name}" and all its posts and messages. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              TrueVoiceStore.instance.deleteGroup(group);
              Navigator.pop(dialogContext);
              showMessage(context, 'Group deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

void confirmLeaveGroup(BuildContext context, Group group) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Leave group?'),
        content: Text(
          'You will no longer see posts or messages from "${group.name}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              TrueVoiceStore.instance.leaveGroup(group);
              Navigator.pop(dialogContext);
              showMessage(context, 'You left the group.');
            },
            child: const Text('Leave'),
          ),
        ],
      );
    },
  );
}


// ============================================================
// FREELANCE DETAIL
// ============================================================

void showFreelanceDetail(
  BuildContext context,
  FreelanceService service,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name: service.providerName, radius: 25),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        service.providerName,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(service.description),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: Text(service.category),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  'USD ${service.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16),
                const SizedBox(width: 4),
                Text(
                  service.location,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        personName: service.providerName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.message_outlined),
                label: const Text('Message Provider'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(service.mapsUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    if (context.mounted) {
                      showMessage(
                        context,
                        'Could not open maps.',
                      );
                    }
                  }
                },
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Get Directions'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showMessage(
                    context,
                    'Booking request will be added in the next update.',
                  );
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Request Booking'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ============================================================
// PROFILE GALLERY
// ============================================================

class ProfileGalleryPage extends StatelessWidget {
  const ProfileGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;
    final photoPosts = store.posts
        .where((p) =>
            p.name == store.userName &&
            p.mediaPath != null &&
            File(p.mediaPath!).existsSync())
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Gallery')),
      body: photoPosts.isEmpty
          ? const EmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No photos yet',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: photoPosts.length,
              itemBuilder: (context, i) {
                final p = photoPosts[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _GalleryViewer(
                          posts: photoPosts,
                          index: i,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(p.mediaPath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                            Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _GalleryViewer extends StatelessWidget {
  const _GalleryViewer({
    required this.posts,
    required this.index,
  });
  final List<CommunityPost> posts;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${index + 1} / ${posts.length}'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(posts[index].mediaPath!),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// NOTIFICATIONS MODEL + STORE
// ============================================================

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.icon = Icons.notifications_outlined,
    this.type = 'general',
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final String type;
  bool read;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'time': time,
        'type': type,
        'read': read,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      time: map['time'] as String,
      type: map['type'] as String? ?? 'general',
      read: map['read'] as bool? ?? false,
      icon: Icons.notifications_outlined,
    );
  }
}

List<AppNotification> demoNotifications() {
  return [
    AppNotification(
      id: 'n1',
      title: 'Welcome to TrueVoice',
      body:
          'Thanks for joining. Explore professionals, join a group, and start connecting with the community.',
      time: 'Just now',
      type: 'welcome',
      icon: Icons.waving_hand_outlined,
    ),
    AppNotification(
      id: 'n2',
      title: 'Dr. Sarah Mensah posted',
      body:
          'Stroke awareness matters. Knowing the warning signs and seeking emergency care quickly can make a major difference.',
      time: '15m',
      type: 'post',
      icon: Icons.article_outlined,
    ),
    AppNotification(
      id: 'n3',
      title: 'New professional near you',
      body:
          'Nurse Akua Mensah (Registered Nurse) is now on TrueVoice.',
      time: '1h',
      type: 'professional',
      icon: Icons.person_add_outlined,
    ),
    AppNotification(
      id: 'n4',
      title: 'Group activity',
      body:
          'Heart Cancer Heroes has 12 new messages this week.',
      time: '3h',
      type: 'group',
      icon: Icons.groups_outlined,
    ),
    AppNotification(
      id: 'n5',
      title: 'Appointment reminder',
      body:
          'You have no upcoming appointments. Browse professionals to book one.',
      time: '1d',
      type: 'booking',
      icon: Icons.calendar_month_outlined,
    ),
  ];
}

// ============================================================
// ONBOARDING
// ============================================================

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_OnboardSlide> slides = const [
    _OnboardSlide(
      icon: Icons.health_and_safety_outlined,
      title: 'Welcome to TrueVoice',
      body:
          'A health community for patients, professionals, students and caregivers — worldwide.',
      color: Color(0xFF007F86),
    ),
    _OnboardSlide(
      icon: Icons.forum_outlined,
      title: 'Connect & share',
      body:
          'Join groups, post to the community, chat with professionals, and share voice notes.',
      color: Color(0xFF2E7D8F),
    ),
    _OnboardSlide(
      icon: Icons.verified_user_outlined,
      title: 'Trusted health',
      body:
          'Verified professionals, booked appointments, and reliable health information — all in one place.',
      color: Color(0xFF3A8FA0),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    TrueVoiceStore.instance.completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            s.icon,
                            size: 96,
                            color: s.color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        height: 8,
                        width: _page == i ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        _page == slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide {
  const _OnboardSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

// ============================================================
// LOCATION UTILITIES
// ============================================================

Future<Position?> getUserLocation() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  } catch (_) {
    return null;
  }
}

double distanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const r = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_toRad(lat1)) *
          cos(_toRad(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * 3.1415926535897932 / 180.0;

// ================================1============================
// USER PROFILE PAGE
// ============================================================

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({
    super.key,
    required this.userName,
    required this.profession,
  });
  final String userName;
  final String profession;

  @override
  Widget build(BuildContext context) {
    final store = TrueVoiceStore.instance;
    final userPosts =
        store.posts.where((p) => p.name == userName).toList();

    // Check if this user is a verified professional
    final pro = professionals
        .where((p) => p.name == userName)
        .cast<Professional?>()
        .firstWhere((p) => true, orElse: () => null);

    final isVerified = pro?.verified ?? false;
    final location = pro?.location ?? 'Worldwide';
    final bio = pro?.bio ??
        'Member of TrueVoice — health community.';

    final totalLikes =
        userPosts.fold<int>(0, (total, p) => total + p.likes);

    return Scaffold(
      appBar: AppBar(title: Text(userName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Avatar(name: userName, radius: 45),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  userName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (isVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
            ],
          ),
          Center(child: Text(profession)),
          Center(
            child: Text(
              location,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Stats card
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _StatBlock(
                  label: 'Posts',
                  value: userPosts.length.toString(),
                ),
                _StatBlock(
                  label: 'Likes',
                  value: totalLikes.toString(),
                ),
                _StatBlock(
                  label: 'Verified',
                  value: isVerified ? 'Yes' : 'No',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (store.connections.contains(userName)) {
                      showMessage(
                        context,
                        'Already connected.',
                      );
                      return;
                    }
                    if (store.sentRequests
                        .contains(userName)) {
                      showMessage(
                        context,
                        'Request already sent.',
                      );
                      return;
                    }
                    store.sendConnectionRequest(userName);
                    showMessage(
                      context,
                      'Connection request sent.',
                    );
                  },
                  icon: Icon(
                    store.connections.contains(userName)
                        ? Icons.check
                        : Icons.person_add_outlined,
                  ),
                  label: Text(
                    store.connections.contains(userName)
                        ? 'Connected'
                        : 'Connect',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          personName: userName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Activity
          SectionTitle(title: 'Activity (${userPosts.length})'),
          const SizedBox(height: 10),
          if (userPosts.isEmpty)
            EmptyState(
              icon: Icons.article_outlined,
              title: '$userName hasn\'t posted yet',
            )
          else
            ...userPosts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PostCard(post: p),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// AUTH GATE — decides login vs app
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // Logged in — go to onboarding or app
          return TrueVoiceStore.instance.hasSeenOnboarding
              ? const HomeScreen()
              : const OnboardingPage();
        }
        // Not logged in
        return const LoginPage();
      },
    );
  }
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage(context, 'Please fill all fields.');
      return;
    }

    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // AuthGate will auto-navigate on success
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showMessage(context, _authError(e.code));
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      showMessage(context, 'Enter your email first.');
      return;
    }
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: email);
      if (mounted) {
        showMessage(context, 'Reset link sent to your email.');
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not send reset email.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              Icon(
                Icons.health_and_safety_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to TrueVoice',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => showPassword = !showPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: resetPassword,
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: loading ? null : login,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignupPage(),
                        ),
                      );
                    },
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIGNUP PAGE
// ============================================================

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showMessage(context, 'Please fill all fields.');
      return;
    }
    if (password.length < 6) {
      showMessage(context, 'Password must be at least 6 characters.');
      return;
    }

    setState(() => loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
      // Save user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'profession': 'Community member',
        'location': 'Worldwide',
        'bio': '',
        'verified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // AuthGate will auto-navigate
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showMessage(context, _authError(e.code));
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Something went wrong.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create your account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join the TrueVoice community',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                decoration: InputDecoration(
                  labelText: 'Password (min 6 characters)',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => showPassword = !showPassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: loading ? null : signup,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AUTH HELPERS
// ============================================================

String _authError(String code) {
  switch (code) {
    case 'user-not-found':
      return 'No account found with this email.';
    case 'wrong-password':
      return 'Incorrect password.';
    case 'invalid-email':
      return 'Invalid email address.';
    case 'email-already-in-use':
      return 'This email is already registered.';
    case 'weak-password':
      return 'Password is too weak.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'network-request-failed':
      return 'Network error. Check your connection.';
    default:
      return 'Authentication failed. Try again.';
  }
}

// ============================================================
// LOGOUT
// ============================================================

Future<void> logout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text(
        'You will need to sign in again to use TrueVoice.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await FirebaseAuth.instance.signOut();
  }
}