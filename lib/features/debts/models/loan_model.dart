import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'loan_model.freezed.dart';
part 'loan_model.g.dart';

@freezed
class LoanModel with _$LoanModel {
  const factory LoanModel({
    required String id,
    required String userId,
    required String type, // lent, borrowed
    required String personName,
    required String phoneNumber,
    required double amount,
    required double amountPaid,
    required DateTime dueDate,
    required String status, // pending, completed, overdue
    String? notes,
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _LoanModel;

  factory LoanModel.fromJson(Map<String, dynamic> json) =>
      _$LoanModelFromJson(json);

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoanModel.fromJson({
      'id': doc.id,
      ...data,
      'dueDate': (data['dueDate'] as Timestamp).toDate().toIso8601String(),
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  const LoanModel._();

  double get remainingAmount => amount - amountPaid;
  bool get isFullyPaid => amountPaid >= amount;
  bool get isLent => type == 'lent';
  bool get isBorrowed => type == 'borrowed';

  String get computedStatus {
    if (isFullyPaid) return 'completed';
    if (DateTime.now().isAfter(dueDate)) return 'overdue';
    return 'pending';
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type,
        'personName': personName,
        'phoneNumber': phoneNumber,
        'amount': amount,
        'amountPaid': amountPaid,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': status,
        'notes': notes,
        'isDeleted': isDeleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };
}
