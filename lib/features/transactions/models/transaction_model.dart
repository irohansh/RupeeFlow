import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    required String userId,
    required double amount,
    required String type, // credit, debit, cash, sms_imported
    required String category,
    required DateTime date,
    String? notes,
    String? bankName,
    String? smsId, // for dedup
    @Default(false) bool isDeleted,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel.fromJson({
      'id': doc.id,
      ...data,
      'date': (data['date'] as Timestamp).toDate().toIso8601String(),
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'updatedAt': data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate().toIso8601String()
          : null,
    });
  }

  const TransactionModel._();

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'amount': amount,
        'type': type,
        'category': category,
        'date': Timestamp.fromDate(date),
        'notes': notes,
        'bankName': bankName,
        'smsId': smsId,
        'isDeleted': isDeleted,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  bool get isCredit => type == 'credit' || type == 'sms_imported';
  bool get isDebit => type == 'debit';
  bool get isCash => type == 'cash';
}
