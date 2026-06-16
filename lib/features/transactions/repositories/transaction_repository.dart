import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  TransactionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.transactionsCollection);

  // ─── Create ───────────────────────────────────────────────────────────────

  Future<TransactionModel> createTransaction({
    required double amount,
    required String type,
    required String category,
    required DateTime date,
    String? notes,
    String? bankName,
    String? smsId,
  }) async {
    // SMS dedup check
    if (smsId != null) {
      final existing = await _collection
          .where('userId', isEqualTo: _uid)
          .where('smsId', isEqualTo: smsId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw Exception('Transaction already imported from this SMS');
      }
    }

    final id = _uuid.v4();
    final tx = TransactionModel(
      id: id,
      userId: _uid,
      amount: amount,
      type: type,
      category: category,
      date: date,
      notes: notes,
      bankName: bankName,
      smsId: smsId,
      createdAt: DateTime.now(),
    );
    await _collection.doc(id).set(tx.toFirestore());
    return tx;
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  Stream<List<TransactionModel>> watchTransactions() {
    return _collection
        .where('userId', isEqualTo: _uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Future<TransactionModel?> getTransaction(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(doc);
  }

  // ─── Update ───────────────────────────────────────────────────────────────

  Future<void> updateTransaction(TransactionModel tx) async {
    await _collection.doc(tx.id).update({
      ...tx.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Soft Delete ──────────────────────────────────────────────────────────

  Future<void> deleteTransaction(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Summary ──────────────────────────────────────────────────────────────

  Stream<Map<String, double>> watchSummary() {
    return watchTransactions().map((txs) {
      double totalCredit = 0;
      double totalDebit = 0;
      for (final tx in txs) {
        if (tx.isCredit) totalCredit += tx.amount;
        if (tx.isDebit || tx.isCash) totalDebit += tx.amount;
      }
      return {
        'credit': totalCredit,
        'debit': totalDebit,
        'balance': totalCredit - totalDebit,
      };
    });
  }

  // ─── Filters ──────────────────────────────────────────────────────────────

  Stream<List<TransactionModel>> watchTransactionsByType(String type) {
    return _collection
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: type)
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TransactionModel>> watchTransactionsByMonth(
      int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return _collection
        .where('userId', isEqualTo: _uid)
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }
}

final transactionRepositoryProvider =
    Provider<TransactionRepository>((ref) => TransactionRepository());
