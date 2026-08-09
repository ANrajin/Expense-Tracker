import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/asset.dart';
import 'assets_provider.dart';
import 'wealth_form_parts.dart';

/// Add/edit asset screen. Pass [asset] to edit an existing one; omit it to
/// create a new asset.
class AssetFormScreen extends ConsumerStatefulWidget {
  const AssetFormScreen({super.key, this.asset});

  final Asset? asset;

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  late String _kind;
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.asset != null;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _kind = asset?.kind ?? 'cash';
    _nameController = TextEditingController(text: asset?.name ?? '');
    _amountController = TextEditingController(
      text: asset != null ? trimAmount(asset.amount) : '',
    );
    _noteController = TextEditingController(text: asset?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _parsedAmount => double.tryParse(_amountController.text);

  bool get _canSave => isValidAssetInput(
        name: _nameController.text,
        amount: _parsedAmount,
      );

  Future<void> _save() async {
    if (!_canSave) return;
    final notifier = ref.read(assetsProvider.notifier);
    final ok = _isEditing
        ? await notifier.updateAsset(
            widget.asset!.id,
            name: _nameController.text,
            kind: _kind,
            amount: _parsedAmount!,
            note: _noteController.text,
          )
        : await notifier.addAsset(
            name: _nameController.text,
            kind: _kind,
            amount: _parsedAmount!,
            note: _noteController.text,
          );
    if (ok && mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete asset',
      message:
          'Delete "${widget.asset!.name}"? This is permanent — there is no undo.',
    );
    if (!confirmed || !mounted) return;
    await ref.read(assetsProvider.notifier).deleteAsset(widget.asset!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: _isEditing ? 'Edit Asset' : 'Add Asset',
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
                        hint: 'Wallet, City Bank, bKash…',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Kind'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kind in assetKinds)
                          ChoicePill(
                            label: assetKindLabel(kind),
                            selected: kind == _kind,
                            accent: colors.primary,
                            soft: colors.primarySoft,
                            onTap: () => setState(() => _kind = kind),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Amount (৳)'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      decoration: formInputDecoration(colors, hint: '0'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This balance only changes when you edit it — recording an '
                      'income or expense never adjusts it.',
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
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
                      DeleteButton(label: 'Delete Asset', onPressed: _delete),
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
