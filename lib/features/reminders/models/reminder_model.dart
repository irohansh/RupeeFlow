import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'reminder_model.freezed.dart';
part 'reminder_model.g.dart';

@freezed
class ReminderModel with _$ReminderModel {
  const factory ReminderModel({
    required String id,
    required String userId,
    required String title,
    required String type, // due_date, payment, collection
    required DateTime dueDate,
    String? notes,
    String? linkedLoanId,
    @Default(false) bool isDone,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _ReminderModel;

  factory ReminderModel.fromJson(Map<String, dynamic> json) =>
      _$ReminderModelFromJson(json);

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel.fromJson({
      'id': doc.id,
      ...data,
      'dueDate': (data['dueDate'] as Timestamp).toDate().toIso8601String(),
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  const ReminderModel._();

  bool get isOverdue => !isDone && DateTime.now().isAfter(dueDate);
  bool get isDueToday {
    final now = DateTime.now();
    return !isDone &&
        dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'type': type,
        'dueDate': Timestamp.fromDate(dueDate),
        'notes': notes,
        'linkedLoanId': linkedLoanId,
        'isDone': isDone,
        'isDeleted': isDeleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };
}
