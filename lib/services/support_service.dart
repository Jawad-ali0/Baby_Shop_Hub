import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/support_ticket.dart';

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

class SupportService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  List<SupportTicket> _tickets = [];
  bool _isLoading = false;
  String? _error;

  List<SupportTicket> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription<DatabaseEvent>? _ticketsSubscription;
  String? _currentUserId;

  void initialize(String userId) {
    _currentUserId = userId;
    _loadTickets();
  }

  void _loadTickets() {
    if (_currentUserId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    _ticketsSubscription = _db
        .child('support_tickets')
        .orderByChild('userId')
        .equalTo(_currentUserId)
        .onValue
        .listen(
          (event) {
            _isLoading = false;
            final data = event.snapshot.value as Map<dynamic, dynamic>?;

            if (data != null) {
              _tickets = data.entries
                  .map(
                    (entry) => SupportTicket.fromJson(
                      Map<String, dynamic>.from(entry.value as Map),
                    ),
                  )
                  .toList();
              // Sort by creation date, newest first
              _tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else {
              _tickets = [];
            }

            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            _error = error.toString();
            notifyListeners();
          },
        );
  }

  Future<String> createTicket({
    required String userId,
    required String userEmail,
    required String userName,
    required String subject,
    required String description,
    required String category,
    SupportTicketPriority priority = SupportTicketPriority.medium,
  }) async {
    try {
      final ticketId = _db.child('support_tickets').push().key!;
      final now = DateTime.now();

      final ticket = SupportTicket(
        id: ticketId,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        subject: subject,
        description: description,
        status: SupportTicketStatus.open,
        priority: priority,
        category: category,
        createdAt: now,
        updatedAt: now,
      );

      await _db.child('support_tickets').child(ticketId).set(ticket.toJson());
      return ticketId;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String message,
    required bool isFromSupport,
  }) async {
    try {
      final messageId = _db.child('support_messages').push().key!;
      final now = DateTime.now();

      final supportMessage = SupportMessage(
        id: messageId,
        ticketId: ticketId,
        senderId: senderId,
        senderName: senderName,
        senderEmail: senderEmail,
        message: message,
        isFromSupport: isFromSupport,
        createdAt: now,
      );

      await _db
          .child('support_messages')
          .child(messageId)
          .set(supportMessage.toJson());

      // Update ticket's updatedAt timestamp
      final ticketUpdates = <String, dynamic>{
        'updatedAt': now.millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      ticketUpdates.removeWhere((key, value) => value == null);

      await _db.child('support_tickets').child(ticketId).update(ticketUpdates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTicketStatus(
    String ticketId,
    SupportTicketStatus status,
  ) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('support_tickets').child(ticketId).update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> assignTicket(String ticketId, String assignedTo) async {
    try {
      final updates = <String, dynamic>{
        'assignedTo': assignedTo,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Ensure no null values are sent to Firebase
      updates.removeWhere((key, value) => value == null);

      await _db.child('support_tickets').child(ticketId).update(updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  SupportTicket? getTicketById(String ticketId) {
    try {
      return _tickets.firstWhere((ticket) => ticket.id == ticketId);
    } catch (e) {
      return null;
    }
  }

  List<SupportTicket> getTicketsByStatus(SupportTicketStatus status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  List<SupportTicket> getOpenTickets() {
    return _tickets
        .where(
          (ticket) =>
              ticket.status == SupportTicketStatus.open ||
              ticket.status == SupportTicketStatus.inProgress,
        )
        .toList();
  }

  // Additional method for support screen
  void loadUserTickets(String userId) {
    initialize(userId);
  }

  // Admin functions
  Future<void> loadAllTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ticketsSubscription?.cancel();
      _ticketsSubscription = _db
          .child('support_tickets')
          .onValue
          .listen(
            (event) {
              _isLoading = false;
              final data = event.snapshot.value as Map<dynamic, dynamic>?;

              if (data != null) {
                _tickets = data.entries
                    .map(
                      (entry) => SupportTicket.fromJson(
                        Map<String, dynamic>.from(entry.value as Map),
                      ),
                    )
                    .toList();
                // Sort by creation date, newest first
                _tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              } else {
                _tickets = [];
              }

              notifyListeners();
            },
            onError: (error) {
              _isLoading = false;
              _error = error.toString();
              notifyListeners();
            },
          );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ticketsSubscription?.cancel();
    super.dispose();
  }
}
