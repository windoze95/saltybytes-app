import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';

/// Resolves a universal link to a public recipe page (`saltybytes.ai/r/<id>`)
/// into the normal preview flow. The link carries only the extraction-cache
/// id, so this screen trades it for the recipe's source URL and then replaces
/// itself with `/preview?u=<url>`.
class SharedLinkResolverScreen extends ConsumerStatefulWidget {
  const SharedLinkResolverScreen({super.key, required this.canonicalId});

  final String canonicalId;

  @override
  ConsumerState<SharedLinkResolverScreen> createState() =>
      _SharedLinkResolverScreenState();
}

class _SharedLinkResolverScreenState
    extends ConsumerState<SharedLinkResolverScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    setState(() => _error = null);
    try {
      final response = await ref
          .read(apiClientProvider)
          .get(ApiEndpoints.canonicalSource(widget.canonicalId));
      final sourceUrl = (response.data as Map)['source_url'] as String?;
      if (sourceUrl == null || sourceUrl.isEmpty) {
        throw Exception('This recipe link has nothing to open.');
      }
      if (!mounted) return;
      context.go('/preview?u=${Uri.encodeQueryComponent(sourceUrl)}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: _error == null
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Opening shared recipe…'),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "We couldn't open that shared recipe.",
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _resolve,
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to my recipes'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
