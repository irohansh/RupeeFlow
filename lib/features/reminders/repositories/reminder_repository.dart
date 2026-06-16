import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../models/reminder_model.dart';
import '../../notifications/notification_service.dart';

class ReminderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _uuid = const Uuid();

  ReminderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;
  CollectionReference get _col =>
      _firestore.collection(AppConstants.remindersCollection);

  Future<ReminderModel> createReminder({
    required String title,
    required String type,
    required DateTime dueDate,
    String? notes,
    String? linkedLoanId,
  }) async {
    final id = _uuid.v4();
    final reminder = ReminderModel(
      id: id,
      userId: _uid,
      title: title,
      type: type,
      dueDate: dueDate,
      notes: notes,
      linkedLoanId: linkedLoanId,
      createdAt: DateTime.now(),
    );
    await _col.doc(id).set(reminder.toFirestore());

    // Schedule local notification
    await NotificationService.instance.scheduleReminder(
      id: id.hashCode.abs(),
      title: 'RupeeFlow Reminder',
      body: title,
      scheduledDate: dueDate,
    );

    return reminder;
  }

  Stream<List<ReminderModel>> watchReminders() {
    return _col
        .where('userId', isEqualTo: _uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReminderModel.fromFirestore(d)).toList());
  }

  Future<void> markDone(String id) async {
    await _col.doc(id).update({
      'isDone': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.instance.cancelNotification(id.hashCode.abs());
  }

  Future<void> deleteReminder(String id) async {
    await _col.doc(id).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await NotificationService.instance.cancelNotification(id.hashCode.abs());
  }
}

final reminderRepositoryProvider =
    Provider<ReminderRepository>((ref) => ReminderRepository());
