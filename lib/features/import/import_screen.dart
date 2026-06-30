import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Import Recipe')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to add a recipe?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an import method below',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _ImportOptionCard(
                    icon: Icons.link,
                    title: 'From URL',
                    subtitle: 'Paste a recipe link',
                    color: theme.colorScheme.primary,
                    onTap: () => context.push('/import/url'),
                  ),
                  _ImportOptionCard(
                    icon: Icons.camera_alt,
                    title: 'From Photo',
                    subtitle: 'Scan a recipe image',
                    color: theme.colorScheme.secondary,
                    onTap: () => context.push('/import/photo'),
                  ),
                  _ImportOptionCard(
                    icon: Icons.play_circle_outline,
                    title: 'From Video',
                    subtitle: 'TikTok or Instagram',
                    color: theme.colorScheme.error,
                    onTap: () => context.push('/import/video'),
                  ),
                  _ImportOptionCard(
                    icon: Icons.text_snippet,
                    title: 'From Text',
                    subtitle: 'Paste recipe text',
                    color: theme.colorScheme.tertiary,
                    onTap: () => context.push('/import/text'),
                  ),
                  _ImportOptionCard(
                    icon: Icons.edit,
                    title: 'Manual Entry',
                    subtitle: 'Type it yourself',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    onTap: () => context.push('/import/manual'),
                  ),
                ]
                    .asMap()
                    .entries
                    .map(
                      (entry) => entry.value
                          .animate()
                          .fadeIn(
                            duration: 300.ms,
                            delay: (80 * entry.key).ms,
                          )
                          .slideY(
                            begin: 0.15,
                            end: 0,
                            duration: 300.ms,
                            delay: (80 * entry.key).ms,
                          ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportOptionCard extends StatelessWidget {
  const _ImportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
