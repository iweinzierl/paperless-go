import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperless_ngx_app/src/features/auth/presentation/controllers/auth_session_controller.dart';
import 'package:paperless_ngx_app/src/features/documents/domain/models/paperless_document.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/providers/documents_providers.dart';
import 'package:paperless_ngx_app/src/features/documents/presentation/widgets/paperless_document_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paperless-ngx'),
          actions: [
            IconButton(
              tooltip: 'Log out',
              onPressed: () => ref.read(authSessionProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recent uploads', icon: Icon(Icons.schedule_outlined)),
              Tab(text: 'Todos', icon: Icon(Icons.fact_check_outlined)),
            ],
          ),
        ),
        body: Column(
          children: [
            _HomeHero(
              title: 'Welcome back, ${session.displayName ?? session.username}',
              subtitle: 'Connected to ${session.serverUrl}',
            ),
            const Expanded(
              child: TabBarView(children: [_RecentUploadsTab(), _TodosTab()]),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Scan later'),
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, const Color(0xFF4C9CB5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentUploadsTab extends StatelessWidget {
  const _RecentUploadsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final recentUploads = ref.watch(recentUploadsProvider);

        return recentUploads.when(
          data: (documents) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                const _SectionHint(
                  title: 'Recent uploads',
                  description:
                      'The latest 20 documents uploaded to your paperless-ngx server.',
                ),
                const SizedBox(height: 12),
                if (documents.isEmpty)
                  const _EmptyStateCard(
                    title: 'No uploads yet',
                    description:
                        'Recent documents will appear here once your server has processed uploads.',
                  ),
                for (final document in documents) ...[
                  PaperlessDocumentCard(
                    document: document,
                    trailingLabel: _recentUploadTrailingLabel(document),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
          error: (error, stackTrace) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: const [
                _SectionHint(
                  title: 'Recent uploads',
                  description:
                      'The latest 20 documents uploaded to your paperless-ngx server.',
                ),
                SizedBox(height: 12),
                _EmptyStateCard(
                  title: 'Could not load recent uploads',
                  description:
                      'The home page reached your server, but document loading failed. Pull to refresh later.',
                ),
              ],
            );
          },
          loading: () {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: const [
                _SectionHint(
                  title: 'Recent uploads',
                  description:
                      'The latest 20 documents uploaded to your paperless-ngx server.',
                ),
                SizedBox(height: 12),
                _LoadingCard(),
              ],
            );
          },
        );
      },
    );
  }

  String _recentUploadTrailingLabel(PaperlessDocument document) {
    if (document.added != null && document.added!.isNotEmpty) {
      return 'Added';
    }

    return 'Recent';
  }
}

class _TodosTab extends StatelessWidget {
  const _TodosTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: const [
        _SectionHint(
          title: 'Verification queue',
          description:
              'Documents that need manual verification will appear here for quick review.',
        ),
        SizedBox(height: 12),
        _TodoPlaceholderCard(
          title: 'Unknown correspondent on grocery receipt',
          meta: 'Needs manual verification',
        ),
        SizedBox(height: 12),
        _TodoPlaceholderCard(
          title: 'Missing document type on electricity bill',
          meta: 'Suggested action available',
        ),
      ],
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _TodoPlaceholderCard extends StatelessWidget {
  const _TodoPlaceholderCard({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return _PlaceholderCard(
      leadingIcon: Icons.warning_amber_rounded,
      title: title,
      meta: meta,
      trailingLabel: 'Review',
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.leadingIcon,
    required this.title,
    required this.meta,
    required this.trailingLabel,
  });

  final IconData leadingIcon;
  final String title;
  final String meta;
  final String trailingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(leadingIcon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(meta, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Chip(label: Text(trailingLabel)),
          ],
        ),
      ),
    );
  }
}
