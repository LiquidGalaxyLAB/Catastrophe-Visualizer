import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SimpleKMLGenerator {

  static Future<File?> generateKML(String kmlContent, String fileName) async {
    try {
      if (Platform.isAndroid) {
        final permission = await _requestStoragePermission();
        if (!permission) {
          throw Exception('Storage permission denied');
        }
      }


      final directory = await _getBestSaveDirectory();
      final file = File('${directory.path}/$fileName.kml');


      await file.writeAsString(kmlContent);

      print('KML saved successfully: ${file.path}');
      return file;

    } catch (e) {
      print(' Failed to save KML: $e');
      return null;
    }
  }

  /// directory for saving files
  static Future<Directory> _getBestSaveDirectory() async {
    try {
      if (Platform.isAndroid) {

        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Create a KML folder in external storage
          final kmlDir = Directory('${externalDir.path}/KML_Files');
          if (!await kmlDir.exists()) {
            await kmlDir.create(recursive: true);
          }
          return kmlDir;
        }
      }

      // Fallback to documents directory
      return await getApplicationDocumentsDirectory();

    } catch (e) {

      return await getTemporaryDirectory();
    }
  }

  /// Request storage permissions for Android
  static Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // Check Android version
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+ (API 30+)
        // For scoped storage, we don't need MANAGE_EXTERNAL_STORAGE
        // if we're saving to app-specific directories
        return true;
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      print(' Permission request failed: $e');
      return false;
    }
  }

  /// Get all saved KML files
  static Future<List<File>> getSavedKMLFiles() async {
    try {
      final directory = await _getBestSaveDirectory();

      if (!await directory.exists()) {
        return [];
      }

      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.kml'))
          .toList();

      // Sort by modification date (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      return files;
    } catch (e) {
      print(' Failed to get saved KML files: $e');
      return [];
    }
  }

  /// Delete KML file
  static Future<bool> deleteKMLFile(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        print(' KML file deleted: ${file.path}');
        return true;
      }
      return false;
    } catch (e) {
      print(' Failed to delete KML file: $e');
      return false;
    }
  }

  /// Get file size in a readable format
  static String getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Open file location in file manager (Android only)
  static Future<bool> openFileLocation(File file) async {
    try {
      if (Platform.isAndroid) {
        // Try to open the directory containing the file
        final directory = file.parent;

        // This is a simple implementation - you might want to use
        // a package like 'open_file' for better file opening capabilities
        print(' File location: ${directory.path}');
        return true;
      }
      return false;
    } catch (e) {
      print(' Failed to open file location: $e');
      return false;
    }
  }
}

/// Simple dialog for KML download
class SimpleKMLDownloadDialog extends StatelessWidget {
  final String kmlContent;
  final String fileName;

  const SimpleKMLDownloadDialog({
    Key? key,
    required this.kmlContent,
    required this.fileName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.download, color: Colors.blue),
          SizedBox(width: 8),
          Text('Save KML File'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('File: $fileName.kml'),
          SizedBox(height: 8),
          Text(
            'Size: ${(kmlContent.length / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          SizedBox(height: 16),
          Text(
            'The file will be saved to your device storage and can be accessed by other apps.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Navigator.pop(context);

            // Show loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text('Saving KML file...'),
                  ],
                ),
                duration: Duration(seconds: 2),
              ),
            );

            // Save file
            final file = await SimpleKMLGenerator.generateKML(kmlContent, fileName);

            // Show result
            if (file != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(' KML saved: ${file.path}'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () => SimpleKMLGenerator.openFileLocation(file),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(' Failed to save KML file'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          icon: Icon(Icons.save),
          label: Text('Save'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
      ],
    );
  }
}

/// Widget to show saved KML files
class SavedKMLFilesDialog extends StatefulWidget {
  @override
  _SavedKMLFilesDialogState createState() => _SavedKMLFilesDialogState();
}

class _SavedKMLFilesDialogState extends State<SavedKMLFilesDialog> {
  List<File> _savedFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedFiles();
  }

  Future<void> _loadSavedFiles() async {
    final files = await SimpleKMLGenerator.getSavedKMLFiles();
    setState(() {
      _savedFiles = files;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Saved KML Files'),
      content: Container(
        width: double.maxFinite,
        height: 300,
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : _savedFiles.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No saved KML files'),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _savedFiles.length,
          itemBuilder: (context, index) {
            final file = _savedFiles[index];
            final fileName = file.path.split('/').last;
            final fileSize = SimpleKMLGenerator.getFileSize(file);
            final modifiedDate = file.lastModifiedSync();

            return ListTile(
              leading: Icon(Icons.description, color: Colors.blue),
              title: Text(fileName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Size: $fileSize'),
                  Text(
                    'Modified: ${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final success = await SimpleKMLGenerator.deleteKMLFile(file);
                  if (success) {
                    _loadSavedFiles(); // Refresh list
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('File deleted')),
                    );
                  }
                },
              ),
              onTap: () {
                SimpleKMLGenerator.openFileLocation(file);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
