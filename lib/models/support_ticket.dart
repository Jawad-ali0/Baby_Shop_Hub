enum SupportTicketStatus { open, inProgress, resolved, closed }

enum SupportTicketPriority { low, medium, high, urgent }

class SupportTicket {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String subject;
  final String description;
  final SupportTicketStatus status;
  final SupportTicketPriority priority;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SupportMessage> messages;
  final String? assignedTo;
  final String? resolution;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.assignedTo,
    this.resolution,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: json['id'] as String,
    userId: json['userId'] as String,
    userEmail: json['userEmail'] as String,
    userName: json['userName'] as String,
    subject: json['subject'] as String,
    description: json['description'] as String,
    status: SupportTicketStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SupportTicketStatus.open,
    ),
    priority: SupportTicketPriority.values.firstWhere(
      (e) => e.name == json['priority'],
      orElse: () => SupportTicketPriority.medium,
    ),
    category: json['category'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    messages:
        (json['messages'] as List?)
            ?.map(
              (e) =>
                  SupportMessage.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        [],
    assignedTo: json['assignedTo'] as String?,
    resolution: json['resolution'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userEmail': userEmail,
    'userName': userName,
    'subject': subject,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'category': category,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'messages': messages.map((e) => e.toJson()).toList(),
    'assignedTo': assignedTo,
    'resolution': resolution,
  };

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? subject,
    String? description,
    SupportTicketStatus? status,
    SupportTicketPriority? priority,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SupportMessage>? messages,
    String? assignedTo,
    String? resolution,
  }) => SupportTicket(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    userEmail: userEmail ?? this.userEmail,
    userName: userName ?? this.userName,
    subject: subject ?? this.subject,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    messages: messages ?? this.messages,
    assignedTo: assignedTo ?? this.assignedTo,
    resolution: resolution ?? this.resolution,
  );

  String get statusDisplayName => status.name.toUpperCase();
  String get priorityDisplayName => priority.name.toUpperCase();
}

class SupportMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderEmail;
  final String message;
  final bool isFromSupport;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.message,
    required this.isFromSupport,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    id: json['id'] as String,
    ticketId: json['ticketId'] as String,
    senderId: json['senderId'] as String,
    senderName: json['senderName'] as String,
    senderEmail: json['senderEmail'] as String,
    message: json['message'] as String,
    isFromSupport: json['isFromSupport'] as bool,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticketId': ticketId,
    'senderId': senderId,
    'senderName': senderName,
    'senderEmail': senderEmail,
    'message': message,
    'isFromSupport': isFromSupport,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
