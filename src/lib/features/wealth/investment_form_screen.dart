import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/investment.dart';
import 'investments_provider.dart';
import 'wealth_form_parts.dart';

/// Add/edit investment screen. Pass [investment] to edit an existing one;
/// omit it to create a new investment.
class InvestmentFormScreen extends ConsumerStatefulWidget {
  const InvestmentFormScreen({super.key, this.investment});

  final Investment? investment;

  @override
  ConsumerState<InvestmentFormScreen> createState() =>
      _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends ConsumerState<InvestmentFormScreen> {
  late String _type;
  late final TextEditingController _nameController;
  late final TextEditingController _investedController;
  late final TextEditingController _currentController;
  late final TextEditingController _noteController;
  DateTime? _date;

  /// Until the user types a current value of their own, it tracks the amount
  /// invested — so a brand-new investment reads as break-even rather than
  /// as a -100% loss.
  bool _currentTouched = false;

  bool get _isEditing => widget.investment != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.investment;
    _type = inv?.type ?? 'stock';
    _nameController = TextEditingController(text: inv?.name ?? '');
    _investedController = TextEditingController(
      text: inv != null ? trimAmount(inv.investedAmount) : '',
    );
    _currentController = TextEditingController(
      text: inv != null ? trimAmount(inv.currentValue) : '',
    );
    _noteController = TextEditingController(text: inv?.note ?? '');
    _date = inv != null ? DateTime.parse(inv.date) : DateTime.now();
    _currentTouched = _isEditing;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _investedController.dispose();
    _currentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _parsedInvested => double.tryParse(_investedController.text);

  double? get _parsedCurrent => double.tryParse(_currentController.text);

  bool get _canSave => isValidInvestmentInput(
        name: _nameController.text,
        investedAmount: _parsedInvested,
        currentValue: _parsedCurrent,
        date: _date?.toIso8601String(),
      );

  void _onInvestedChanged(String value) {
    setState(() {
      if (!_currentTouched) _currentController.text = value;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final notifier = ref.read(investmentsProvider.notifier);
    final dateIso = toIsoDate(_date!);
    final ok = _isEditing
        ? await notifier.updateInvestment(
            widget.investment!.id,
            name: _nameController.text,
            type: _type,
            investedAmount: _parsedInvested!,
            currentValue: _parsedCurrent!,
            date: dateIso,
            note: _noteController.text,
          )
        : await notifier.addInvestment(
            name: _nameController.text,
            type: _type,
            investedAmount: _parsedInvested!,
            currentValue: _parsedCurrent!,
            date: dateIso,
            note: _noteController.text,
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete investment',
      message: 'Delete "${widget.investment!.name}"? This is permanent — '
          'there is no undo.',
    );
    if (!confirmed || !mounted) return;
    await ref
        .read(investmentsProvider.notifier)
        .deleteInvestment(widget.investment!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final preview = calculateGainLoss(
      investedAmount: _parsedInvested ?? 0,
      currentValue: _parsedCurrent ?? 0,
    );
    final showPreview = (_parsedInvested ?? 0) > 0 && _parsedCurrent != null;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: _isEditing ? 'Edit Investment' : 'Add Investment',
              canSave: _canSave,
              onSave: _save,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Name'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration: formInputDecoration(
                        colors,
                        hint: 'DSE portfolio, DPS at City Bank…',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Type'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in investmentTypes)
                          ChoicePill(
                            label: investmentTypeLabel(type),
                            selected: type == _type,
                            accent: colors.primary,
                            soft: colors.primarySoft,
                            onTap: () => setState(() => _type = type),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Amount invested (৳)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _investedController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _onInvestedChanged,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      decoration: formInputDecoration(colors, hint: '0'),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Current value (৳)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _currentController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() => _currentTouched = true),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      decoration: formInputDecoration(colors, hint: '0'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You update this by hand — the app never revalues an '
                      'investment on its own.',
                      style:
                          TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
                    if (showPreview) ...[
                      const SizedBox(height: 10),
                      _GainLossPreview(gainLoss: preview),
                    ],
                    const SizedBox(height: 18),
                    const FieldLabel('Invested on'),
                    const SizedBox(height: 6),
                    DateField(date: _date, onTap: _pickDate),
                    const SizedBox(height: 18),
                    const FieldLabel('Note (optional)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _noteController,
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
                      decoration:
                          formInputDecoration(colors, hint: 'Add a note'),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      DeleteButton(
                          label: 'Delete Investment', onPressed: _delete),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live gain/loss strip, so the computed figure is visible before saving.
class _GainLossPreview extends StatelessWidget {
  const _GainLossPreview({required this.gainLoss});

  final GainLoss gainLoss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isLoss = gainLoss.isLoss;
    final accent = isLoss ? colors.expense : colors.income;
    final background = isLoss ? colors.expenseSoft : colors.primarySoft;
    final sign = gainLoss.amount > 0 ? '+' : '';
    final percent = gainLoss.percent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isLoss
                ? Icons.trending_down_rounded
                : gainLoss.isGain
                    ? Icons.trending_up_rounded
                    : Icons.trending_flat_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Text(
            gainLoss.isGain
                ? 'Gain'
                : isLoss
                    ? 'Loss'
                    : 'Break-even',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const Spacer(),
          Text(
            percent == null
                ? '$sign${fmtBDT(gainLoss.amount)}'
                : '$sign${fmtBDT(gainLoss.amount)}  ($sign${percent.toStringAsFixed(1)}%)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
