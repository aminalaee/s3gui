import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:minio/models.dart';
import 'package:s3gui/pages/settings.dart';
import 'package:s3gui/pages/objects.dart';
import 'package:s3gui/client.dart';
import 'package:s3gui/s3.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _s3 = S3();
  final _searchController = TextEditingController();
  final _newBucketController = TextEditingController();
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Client().init();
    await _s3.listBuckets();
    if (mounted) setState(() => _loading = false);
    _showErrorIfAny();
  }

  void _showErrorIfAny() {
    if (_s3.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s3.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _s3.clearError();
    }
  }

  void _showCreateBucketDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Bucket'),
        content: TextField(
          controller: _newBucketController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Bucket name',
            hintText: 'my-new-bucket',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _newBucketController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              await _s3.createBucket(name);
              _showErrorIfAny();
              await _s3.listBuckets();
              _newBucketController.clear();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBucket(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(ctx).colorScheme.error, size: 36),
        title: const Text('Delete Bucket'),
        content: Text(
            'Are you sure you want to delete "$name"?\n\nThe bucket must be empty.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _s3.deleteBucket(name);
    _showErrorIfAny();
    await _s3.listBuckets();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buckets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      SettingsPage(onToggleTheme: widget.onToggleTheme)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBucketDialog,
        tooltip: 'Create Bucket',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search buckets...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: Observer(builder: (_) {
                    final filtered = _searchQuery.isEmpty
                        ? _s3.buckets
                        : _s3.buckets
                            .where((b) => b.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()))
                            .toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No buckets found'
                                  : 'No matching buckets',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (_, i) => _buildBucketCard(filtered[i]),
                    );
                  }),
                ),
              ],
            ),
    );
  }

  Widget _buildBucketCard(Bucket bucket) {
    final theme = Theme.of(context);
    final dateStr = bucket.creationDate != null
        ? '${bucket.creationDate!.year}-${bucket.creationDate!.month.toString().padLeft(2, '0')}-${bucket.creationDate!.day.toString().padLeft(2, '0')}'
        : null;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.inventory_2_outlined,
              color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(bucket.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: dateStr != null ? Text('Created at $dateStr') : null,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          tooltip: 'Delete bucket',
          onPressed: () => _deleteBucket(bucket.name),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ObjectsPage(
              bucket: bucket.name,
              prefix: '',
              onToggleTheme: widget.onToggleTheme,
            ),
          ),
        ),
      ),
    );
  }
}
