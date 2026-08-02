import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/category.dart';
import 'categories_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final incomeCategories = categories.where((c) => c.isIncome).toList();
    final expenseCategories = categories.where((c) => c.isExpense).toList();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(title: 'Categories'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _SectionLabel('Income', colors: colors),
              for (final c in incomeCategories) _CategoryRow(category: c),
              const SizedBox(height: 18),
              _SectionLabel('Expense', colors: colors),
              for (final c in expenseCategories) _CategoryRow(category: c),
              const SizedBox(height: 18),
              const _AddCategoryCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final count = ref.watch(categoryTransactionCountProvider(category.id));
    final canDelete =
        canDeleteCategory(isDefault: category.isDefault, transactionCount: count);
    final dotColor = category.isIncome ? colors.income : colors.expense;
    final metaLabel =
        '${category.isDefault ? 'Default · ' : ''}$count transaction${count == 1 ? '' : 's'}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  metaLabel,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () =>
                ref.read(categoriesProvider.notifier).toggleActive(category.id),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.border),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              category.active ? 'Active' : 'Hidden',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: category.active ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
          if (canDelete)
            IconButton(
              onPressed: () => ref
                  .read(categoriesProvider.notifier)
                  .deleteCategory(category.id, transactionCount: count),
              icon: Icon(Icons.close_rounded, color: colors.expense, size: 18),
              padding: const EdgeInsets.only(left: 4),
              constraints: const BoxConstraints(),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}

class _AddCategoryCard extends ConsumerStatefulWidget {
  const _AddCategoryCard();

  @override
  ConsumerState<_AddCategoryCard> createState() => _AddCategoryCardState();
}

class _AddCategoryCardState extends ConsumerState<_AddCategoryCard> {
  final _controller = TextEditingController();
  String _type = 'expense';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(categoriesProvider.notifier).addCategory(_controller.text, _type);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canAdd = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Category',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.chipBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TypeToggleButton(
                    label: 'Expense',
                    selected: _type == 'expense',
                    selectedBg: colors.expenseSoft,
                    selectedColor: colors.expense,
                    onTap: () => setState(() => _type = 'expense'),
                  ),
                ),
                Expanded(
                  child: _TypeToggleButton(
                    label: 'Income',
                    selected: _type == 'income',
                    selectedBg: colors.primarySoft,
                    selectedColor: colors.income,
                    onTap: () => setState(() => _type = 'income'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => canAdd ? _submit() : null,
                  style: TextStyle(fontSize: 13.5, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Category name',
                    hintStyle: TextStyle(color: colors.textSecondary),
                    filled: true,
                    fillColor: colors.background,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: colors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: canAdd ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  disabledBackgroundColor: colors.primary.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeToggleButton extends StatelessWidget {
  const _TypeToggleButton({
    required this.label,
    required this.selected,
    required this.selectedBg,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedBg;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? selectedColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
