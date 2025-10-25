class SingleContentModel {
  int? id;
  String? title;
  String? canViewError;
  bool? authHasRead;
  bool? authHasAccess;
  bool? userHasAccess;
  String? fileType;
  String? volume;
  String? storage;
  String? downloadLink;
  String? file;
  int? studyTime;
  int? createdAt;
  String? description;
  String? summary;
  String? content;
  String? locale;
  List<Attachments>? attachments;
  int? attachmentsCount;
  int checkPreviousParts = 0;
  int? date;
  int? duration;
  bool? isFinished;
  bool? isStarted;
  bool? canJoin;
  String? link;
  String? sessionApi;
  String? zoomStartLink;
  String? assignmentStatus;
  bool? passed;

  SingleContentModel({
    this.id,
    this.title,
    this.canViewError,
    this.authHasRead,
    this.authHasAccess,
    this.userHasAccess,
    this.fileType,
    this.volume,
    this.storage,
    this.downloadLink,
    this.file,
    this.studyTime,
    this.createdAt,
    this.description,
    this.summary,
    this.content,
    this.locale,
    this.attachments,
    this.attachmentsCount,
    this.date,
    this.duration,
    this.isFinished,
    this.isStarted,
    this.canJoin,
    this.link,
    this.sessionApi,
    this.zoomStartLink,
    this.assignmentStatus,
    this.passed,
  });

  // ✅ `copyWith` لتحديث القيم بسهولة
  SingleContentModel copyWith({
    int? id,
    String? title,
    String? canViewError,
    bool? authHasRead,
    bool? authHasAccess,
    bool? userHasAccess,
    String? fileType,
    String? volume,
    String? storage,
    String? downloadLink,
    String? file,
    int? studyTime,
    int? createdAt,
    String? description,
    String? summary,
    String? content,
    String? locale,
    List<Attachments>? attachments,
    int? attachmentsCount,
    int? date,
    int? duration,
    bool? isFinished,
    bool? isStarted,
    bool? canJoin,
    String? link,
    String? sessionApi,
    String? zoomStartLink,
    String? assignmentStatus,
    bool? passed,
  }) {
    return SingleContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      canViewError: canViewError ?? this.canViewError,
      authHasRead: authHasRead ?? this.authHasRead,
      authHasAccess: authHasAccess ?? this.authHasAccess,
      userHasAccess: userHasAccess ?? this.userHasAccess,
      fileType: fileType ?? this.fileType,
      volume: volume ?? this.volume,
      storage: storage ?? this.storage,
      downloadLink: downloadLink ?? this.downloadLink,
      file: file ?? this.file,
      studyTime: studyTime ?? this.studyTime,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      locale: locale ?? this.locale,
      attachments: attachments ?? this.attachments,
      attachmentsCount: attachmentsCount ?? this.attachmentsCount,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      isFinished: isFinished ?? this.isFinished,
      isStarted: isStarted ?? this.isStarted,
      canJoin: canJoin ?? this.canJoin,
      link: link ?? this.link,
      sessionApi: sessionApi ?? this.sessionApi,
      zoomStartLink: zoomStartLink ?? this.zoomStartLink,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      passed: passed ?? this.passed,
    );
  }

  // ✅ تحويل JSON إلى كائن
  factory SingleContentModel.fromJson(Map<String, dynamic> json) {
    return SingleContentModel(
      id: json['id'],
      title: json['title'],
      canViewError: json['can_view_error'],
      authHasRead: json['auth_has_read'],
      authHasAccess: json['auth_has_access'],
      userHasAccess: json['user_has_access'],
      fileType: json['file_type'],
      volume: json['volume'],
      storage: json['storage'],
      downloadLink: json['download_link'],
      file: json['file'],
      studyTime: json['study_time'],
      createdAt: json['created_at'],
      description: json['description'],
      summary: json['summary'],
      content: json['content'],
      locale: json['locale'],
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((item) => Attachments.fromJson(item))
          .toList(),
      attachmentsCount: json['attachments_count'],
      date: json['date'],
      duration: json['duration'],
      isFinished: json['is_finished'],
      isStarted: json['is_started'],
      canJoin: json['can_join'],
      link: json['link'],
      sessionApi: json['session_api'],
      zoomStartLink: json['zoom_start_link'],
      assignmentStatus: json['assignmentStatus'],
      passed: json['passed'],
    );
  }

  // ✅ تحويل الكائن إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'can_view_error': canViewError,
      'auth_has_read': authHasRead,
      'auth_has_access': authHasAccess,
      'user_has_access': userHasAccess,
      'file_type': fileType,
      'volume': volume,
      'storage': storage,
      'download_link': downloadLink,
      'file': file,
      'study_time': studyTime,
      'created_at': createdAt,
      'description': description,
      'summary': summary,
      'content': content,
      'locale': locale,
      'attachments': attachments?.map((e) => e.toJson()).toList(),
      'attachments_count': attachmentsCount,
      'date': date,
      'duration': duration,
      'is_finished': isFinished,
      'is_started': isStarted,
      'can_join': canJoin,
      'link': link,
      'session_api': sessionApi,
      'zoom_start_link': zoomStartLink,
      'assignmentStatus': assignmentStatus,
      'passed': passed,
    };
  }
}


class Attachments {
  int? id;
  String? title;
  bool? authHasRead;
  String? status;
  int? order;
  int? downloadable;
  String? accessibility;
  String? description;
  String? storage;
  String? downloadLink;
  bool? authHasAccess;
  bool? userHasAccess;
  String? file;
  String? volume;
  String? fileType;
  bool? isVideo;
  var interactiveType;
  String? interactiveFileName;
  String? interactiveFilePath;
  int? createdAt;
  int? updatedAt;

  Attachments(
      {this.id,
      this.title,
      this.authHasRead,
      this.status,
      this.order,
      this.downloadable,
      this.accessibility,
      this.description,
      this.storage,
      this.downloadLink,
      this.authHasAccess,
      this.userHasAccess,
      this.file,
      this.volume,
      this.fileType,
      this.isVideo,
      this.interactiveType,
      this.interactiveFileName,
      this.interactiveFilePath,
      this.createdAt,
      this.updatedAt});

  Attachments.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    authHasRead = json['auth_has_read'];
    status = json['status'];
    order = json['order'];
    downloadable = json['downloadable'];
    accessibility = json['accessibility'];
    description = json['description'];
    storage = json['storage'];
    downloadLink = json['download_link'];
    authHasAccess = json['auth_has_access'];
    userHasAccess = json['user_has_access'];
    file = json['file'];
    volume = json['volume'];
    fileType = json['file_type'];
    isVideo = json['is_video'];
    interactiveType = json['interactive_type'];
    interactiveFileName = json['interactive_file_name'];
    interactiveFilePath = json['interactive_file_path'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['auth_has_read'] = authHasRead;
    data['status'] = status;
    data['order'] = order;
    data['downloadable'] = downloadable;
    data['accessibility'] = accessibility;
    data['description'] = description;
    data['storage'] = storage;
    data['download_link'] = downloadLink;
    data['auth_has_access'] = authHasAccess;
    data['user_has_access'] = userHasAccess;
    data['file'] = file;
    data['volume'] = volume;
    data['file_type'] = fileType;
    data['is_video'] = isVideo;
    data['interactive_type'] = interactiveType;
    data['interactive_file_name'] = interactiveFileName;
    data['interactive_file_path'] = interactiveFilePath;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}