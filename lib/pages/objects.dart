import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minio/models.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:s3gui/utils/utils.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:s3gui/pages/settings.dart';
import 'package:s3gui/s3.dart';
import 'package:s3gui/utils/filesize.dart';

class ObjectsPage extends StatefulWidget {
  const ObjectsPage({
    super.key,
    required this.bucket,
    required this.prefix,
    required this.onToggleTheme,
  });

  final String bucket;
  final String prefix;
  final VoidCallback onToggleTheme;

  @override
  State<ObjectsPage> createState() => _ObjectsPageState();
}

class _ObjectsPageState extends State<ObjectsPage>
    with TickerProviderStateMixin {
  final _s3 = S3();
  final _newDirectoryController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentPrefix = '';
  bool _dragging = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _currentPrefix = _currentPrefix;
    _s3.listObjects(widget.bucket, _currentPrefix);
    _progressController = AnimationController(
      vsync: this,
      value: -1,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _newDirectoryController.dispose();
    _searchController.dispose();
    _progressController.dispose();
    super.dispose();
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

  Future<bool> _confirmDelete(String name, {bool isDirectory = false}) async {
    final type = isDirectory ? 'directory' : 'file';
    final extra =
        isDirectory ? '\n\nThis will delete all contents recursively.' : '';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(ctx).colorScheme.error, size: 36),
        title: Text('Delete $type'),
        content: Text('Are you sure you want to delete "$name"?$extra'),
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
    return result ?? false;
  }

  void _showCreateDirectoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Directory'),
        content: TextField(
          controller: _newDirectoryController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Directory name',
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
              final name = _newDirectoryController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              await _s3.createNewDirectory(
                  widget.bucket, _currentPrefix, name);
              if (_s3.error != null) {
                _showErrorIfAny();
              } else {
                await _s3.listObjects(widget.bucket, _currentPrefix);
              }
              _newDirectoryController.clear();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFileUpload() async {
    final pick = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (pick != null) {
      for (var file in pick.files) {
        final path = _currentPrefix + file.name;
        await _s3.uploadFile(widget.bucket, path, file, _progressController);
        if (_s3.error != null) {
          _showErrorIfAny();
          return;
        }
        await _s3.listObjects(widget.bucket, _currentPrefix);
      }
    }
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    setState(() => _dragging = false);
    for (final xFile in details.files) {
      final bytes = await xFile.readAsBytes();
      final file = PlatformFile(
        name: xFile.name,
        size: bytes.length,
        bytes: Uint8List.fromList(bytes),
      );
      final path = _currentPrefix + file.name;
      await _s3.uploadFile(widget.bucket, path, file, _progressController);
      if (_s3.error != null) {
        _showErrorIfAny();
        return;
      }
      await _s3.listObjects(widget.bucket, _currentPrefix);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showProgress =
        _progressController.value > 0 && _progressController.value != 1;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.bucket),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'New directory',
            onPressed: _showCreateDirectoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Upload files',
            onPressed: _handleFileUpload,
          ),
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
                    SettingsPage(onToggleTheme: widget.onToggleTheme),
              ),
            ),
          ),
        ],
      ),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: _handleDrop,
        child: Container(
          decoration: _dragging
              ? BoxDecoration(
                  border: Border.all(
                      color: theme.colorScheme.primary, width: 2),
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Breadcrumbs
              _buildBreadcrumbs(theme),
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search objects...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              // Upload progress
              if (showProgress)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressController.value,
                    ),
                  ),
                ),
              // Drop hint
              if (_dragging)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Drop files here to upload',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              // Object list
              Expanded(
                child: Observer(
                  builder: (_) {
                    final Widget child;
                    if (_s3.error != null) {
                      child = Center(
                        key: const ValueKey('error'),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48,
                                  color: theme.colorScheme.error),
                              const SizedBox(height: 12),
                              Text(_s3.error!,
                                  style: TextStyle(
                                      color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      );
                    } else if (_s3.loadingObjects) {
                      child = const Center(
                          key: ValueKey('loading'),
                          child: CircularProgressIndicator());
                    } else if (_s3.objectsResult != null) {
                      child = _buildObjectList(
                          _s3.objectsResult!, theme);
                    } else {
                      child = const Center(
                          key: ValueKey('loading'),
                          child: CircularProgressIndicator());
                    }
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: child,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPrefix(String prefix) {
    setState(() {
      _currentPrefix = prefix;
      _searchQuery = '';
      _searchController.clear();
    });
    _s3.listObjects(widget.bucket, _currentPrefix);
  }

  Widget _buildBreadcrumbs(ThemeData theme) {
    final parts = _currentPrefix.split('/').where((p) => p.isNotEmpty).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _navigateToPrefix(''),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(widget.bucket,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary)),
            ),
          ),
          for (var i = 0; i < parts.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.chevron_right,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
            if (i < parts.length - 1)
              InkWell(
                onTap: () => _navigateToPrefix(
                    '${parts.sublist(0, i + 1).join('/')}/'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(parts[i],
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary)),
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(parts[i],
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildObjectList(ListObjectsResult result, ThemeData theme) {
    final query = _searchQuery.toLowerCase();
    final filteredPrefixes = result.prefixes
        .where((p) =>
            query.isEmpty ||
            normalizePath(p, _currentPrefix).toLowerCase().contains(query))
        .toList();
    final filteredObjects = result.objects
        .where((o) =>
            o.size! > 0 &&
            (query.isEmpty ||
                normalizePath(o.key!, _currentPrefix)
                    .toLowerCase()
                    .contains(query)))
        .toList();
    final totalItems = filteredPrefixes.length + filteredObjects.length;

    if (totalItems == 0) {
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'This folder is empty'
                  : 'No matching objects',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Upload files or create a directory to get started',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      key: ValueKey('list-$_currentPrefix'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: totalItems,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (_, i) {
        if (i < filteredPrefixes.length) {
          return _buildPrefixCard(filteredPrefixes[i], theme);
        }
        return _buildObjectCard(
            filteredObjects[i - filteredPrefixes.length], theme);
      },
    );
  }

  Widget _buildPrefixCard(String prefix, ThemeData theme) {
    final name = normalizePath(prefix, _currentPrefix);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(Icons.folder_outlined,
              color: theme.colorScheme.onSecondaryContainer),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          tooltip: 'Delete directory',
          onPressed: () async {
            if (!await _confirmDelete(name, isDirectory: true)) return;
            await _s3.deleteDirectory(widget.bucket, _currentPrefix, name);
            _showErrorIfAny();
            await _s3.listObjects(widget.bucket, _currentPrefix);
          },
        ),
        onTap: () => _navigateToPrefix(prefix),
      ),
    );
  }

  Widget _buildObjectCard(Object object, ThemeData theme) {
    final name = normalizePath(object.key!, _currentPrefix);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.tertiaryContainer,
          child: Icon(Icons.description_outlined,
              color: theme.colorScheme.onTertiaryContainer),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${filesize(object.size!)}  ·  ${timeago.format(object.lastModified!)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert,
              color: theme.colorScheme.onSurfaceVariant),
          tooltip: 'Actions',
          onSelected: (item) async {
            if (item == 'download') {
              final url =
                  await _s3.getObjectURL(widget.bucket, object.key!);
              if (url != null) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
              _showErrorIfAny();
            } else if (item == 'copy') {
              final url =
                  await _s3.getObjectURL(widget.bucket, object.key!);
              if (url != null) {
                await Clipboard.setData(ClipboardData(text: url));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('URL copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
              _showErrorIfAny();
            } else if (item == 'delete') {
              if (!await _confirmDelete(name)) return;
              await _s3.deleteObject(widget.bucket, _currentPrefix, name);
              _showErrorIfAny();
              await _s3.listObjects(widget.bucket, _currentPrefix);
            }
          },
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download_outlined),
                title: Text('Download'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'copy',
              child: ListTile(
                leading: Icon(Icons.link),
                title: Text('Copy URL'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
