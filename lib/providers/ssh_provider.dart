
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../models/ssh_model.dart';

class SSHProvider extends ChangeNotifier {
  SSHClient? _client;
  bool _isConnected = false;
  String? _lastError;
  SSHModel? _currentConnection;

  // Getters
  SSHClient? get client => _client;
  bool get isConnected => _isConnected;
  String? get lastError => _lastError;
  SSHModel? get currentConnection => _currentConnection;

  /// Connect to LG
  Future<bool> connect(SSHModel sshModel) async {
    try {
      print('Connecting to LG: ${sshModel.host}:${sshModel.port}');

      final socket = await SSHSocket.connect(
        sshModel.host,
        sshModel.port,
        timeout: const Duration(seconds: 10),
      );

      _client = SSHClient(
        socket,
        username: sshModel.username,
        onPasswordRequest: () => sshModel.passwordOrKey,
        keepAliveInterval: const Duration(seconds: 30),
      );

      // Test connection
      final result = await _client!.execute('echo "LG_CONNECTION_TEST"');

      if (result.exitCode == 0) {
        _isConnected = true;
        _currentConnection = sshModel;
        _lastError = null;
        await sshModel.saveToPreferences();

        print(' Connected to LG successfully');
        notifyListeners();
        return true;
      } else {
        throw Exception('Connection test failed');
      }

    } catch (e) {
      _lastError = 'Connection failed: $e';
      _isConnected = false;
      _client = null;
      print(' LG Connection failed: $e');
      notifyListeners();
      return false;
    }
  }

  /// Execute command
  Future<SSHSession?> execute(String command) async {
    if (!_isConnected || _client == null) {
      _lastError = 'Not connected to LG';
      return null;
    }

    try {
      print('Executing: $command');
      final result = await _client!.execute(command);
      return result;
    } catch (e) {
      _lastError = 'Command execution failed: $e';
      print(' Command failed: $e');
      return null;
    }
  }

  /// Upload file
  Future<bool> uploadFile(File file, String remotePath) async {
    if (!_isConnected || _client == null) {
      _lastError = 'Not connected to LG';
      return false;
    }

    try {
      print(' Uploading file: $remotePath');

      final sftp = await _client!.sftp();
      final remoteFile = await sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create |
        SftpFileOpenMode.truncate |
        SftpFileOpenMode.write,
      );

      await remoteFile.write(file.openRead().cast());
      await remoteFile.close();

      print(' File uploaded successfully: $remotePath');
      return true;
    } catch (e) {
      _lastError = 'File upload failed: $e';
      print(' Upload failed: $e');
      return false;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    if (_client != null) {
      _client!.close();
      _client = null;
    }

    _isConnected = false;
    _currentConnection = null;
    _lastError = null;

    print(' Disconnected from LG');
    notifyListeners();
  }
}
