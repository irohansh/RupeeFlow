import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../repositories/transaction_repository.dart';
import 'add_credit_screen.dart'; // reuse _CategorySelector, _SectionLabel

class AddDebitScreen extends ConsumerStatefulWidget {
  const AddDebitScreen({super.key});

  @override
  ConsumerState<AddDebitScreen> createState() => _AddDebitScreenState();
}

class _AddDebitScreenState extends ConsumerState<AddDebitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  String _type = AppConstants.debit; // debit or cash
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(transactionRepositoryProvider).createTransaction(
            amount: double.parse(_amountController.text.replaceAll(',', '')),
            type: _type,
            category: _selectedCategory,
            date: _selectedDate,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debit added successfully!'),
            backgroundColor: AppColors.debit,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Add Debit'),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.debit,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction type toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'debit',
                        label: Text('Bank/Card'),
                        icon: Icon(Icons.credit_card, size: 16)),
                    ButtonSegment(
                        value: 'cash',
                        label: Text('Cash'),
                        icon: Icon(Icons.money, size: 16)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.debit.withOpacity(0.15),
                    selectedForegroundColor: AppColors.debit,
                  ),
                ),
                const SizedBox(height: 24),
                // Amount
                _SectionLabel('Amount (₹)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.debit),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.debit),
                    hintText: '0',
                    hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 28),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount is required';
                    final amt = double.tryParse(v.replaceAll(',', ''));
                    if (amt == null || amt <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _SectionLabel('Category'),
                const SizedBox(height: 8),
                _CategorySelector(
                  selected: _selectedCategory,
                  onSelect: (c) => setState(() => _selectedCategory = c),
                ),
                const SizedBox(height: 24),
                _SectionLabel('Date'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 15),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionLabel('Notes (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.debit),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Debit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
