import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/loan_model.dart';

class LoanRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  LoanRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.loansCollection);

  Future<LoanModel> createLoan({
    required String type,
    required String personName,
    required String phoneNumber,
    required double amount,
    required DateTime dueDate,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final loan = LoanModel(
      id: id,
      userId: _uid,
      type: type,
      personName: personName,
      phoneNumber: phoneNumber,
      amount: amount,
      amountPaid: 0,
      dueDate: dueDate,
      status: AppConstants.pending,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _collection.doc(id).set(loan.toFirestore());
    return loan;
  }

  Stream<List<LoanModel>> watchLoans() {
    return _collection
        .where('userId', isEqualTo: _uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LoanModel.fromFirestore(doc)).toList());
  }

  Stream<List<LoanModel>> watchLoansByType(String type) {
    return _collection
        .where('userId', isEqualTo: _uid)
        .where('type', isEqualTo: type)
        .where('isDeleted', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => LoanModel.fromFirestore(doc)).toList());
  }

  Future<void> recordPayment(String loanId, double paymentAmount) async {
    final doc = await _collection.doc(loanId).get();
    final loan = LoanModel.fromFirestore(doc);
    final newPaid = (loan.amountPaid + paymentAmount).clamp(0, loan.amount);
    final newStatus =
        newPaid >= loan.amount ? AppConstants.completed : loan.computedStatus;
    await _collection.doc(loanId).update({
      'amountPaid': newPaid,
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLoan(LoanModel loan) async {
    await _collection.doc(loan.id).update({
      ...loan.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLoan(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Summary: total lent, total borrowed, pending
  Stream<Map<String, double>> watchLoanSummary() {
    return watchLoans().map((loans) {
      double lent = 0, borrowed = 0, pendingReceivables = 0, pendingPayables = 0;
      for (final loan in loans) {
        if (loan.isLent) {
          lent += loan.amount;
          pendingReceivables += loan.remainingAmount;
        } else {
          borrowed += loan.amount;
          pendingPayables += loan.remainingAmount;
        }
      }
      return {
        'lent': lent,
        'borrowed': borrowed,
        'pendingReceivables': pendingReceivables,
        'pendingPayables': pendingPayables,
      };
    });
  }
}

final loanRepositoryProvider =
    Provider<LoanRepository>((ref) => LoanRepository());
