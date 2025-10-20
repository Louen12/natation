import 'package:flutter/material.dart';

class ExercisePill extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  final bool completed;

  const ExercisePill({
    super.key,
    required this.title,
    this.onTap,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = completed
        ? theme.colorScheme.primary.withOpacity(0.12)
        : theme.colorScheme.surfaceVariant;

    final iconBoxColor = completed
        ? theme.colorScheme.primary.withOpacity(0.20)
        : theme.colorScheme.onSurface.withOpacity(0.15);

    final trailingIcon = completed ? Icons.check_circle : Icons.chevron_right;

    final leadingIcon = completed ? Icons.check : Icons.fitness_center;

    final leadingIconColor = completed
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.75);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(leadingIcon, size: 20, color: leadingIconColor),
              ),
              const SizedBox(width: 12),
              // Titre
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationThickness: completed ? 2 : 1,
                  ),
                ),
              ),
              Icon(
                trailingIcon,
                color: completed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
