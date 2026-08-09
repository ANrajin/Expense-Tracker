import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A list row for the Wealth sections — assets, investments, and lending or
/// borrowing entries.
///
/// A sibling of [TransactionRow] rather than a generalisation of it: that one
/// takes a concrete `Transaction`, and prying its API open would put every
/// existing screen at risk for no gain. This one takes plain strings and colors
/// so each section can label its own rows.
class WealthRow extends StatelessWidget {
  const WealthRow({
    super.key,
    required this.title,
    required this.amountLabel,
    required this.accent,
    this.subtitle,
    this.metaLabel,
    this.metaColor,
    this.leadingInitial,
    this.leadingBg,
    this.trailingBadge,
    this.onTap,
  });

  final String title;
  final String amountLabel;
  final Color accent;
  final String? subtitle;
  final String? metaLabel;
  final Color? metaColor;
  final String? leadingInitial;
  final Color? leadingBg;

  /// Small pill shown after the title — "Settled", "Overdue", a kind label.
  final Widget? trailingBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initial = (leadingInitial?.isNotEmpty ?? false)
        ? leadingInitial![0].toUpperCase()
        : title.isNotEmpty
            ? title[0].toUpperCase()
            : '?';

    final row = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: leadingBg ?? colors.chipBg,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  if (trailingBadge != null) ...[
                    const SizedBox(width: 6),
                    trailingBadge!,
                  ],
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amountLabel,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            if (metaLabel != null)
              Text(
                metaLabel!,
                style: TextStyle(
                  fontSize: 11,
                  color: metaColor ?? colors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: row,
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// The small rounded pill used for status ("Settled", "Overdue") and for an
/// asset's kind or an investment's type.
class WealthBadge extends StatelessWidget {
  const WealthBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
