import "dart:async";
import "dart:io";

import "package:archive/archive.dart";
import "package:certimate/api/http.dart";
import "package:certimate/database/servers_dao.dart";
import "package:certimate/extension/index.dart";
import "package:certimate/web/index.dart" as web;
import "package:crypto/crypto.dart";
import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "local_certimate.g.dart";

@Riverpod(keepAlive: true)
LocalCertimateManager localCertimateManager(Ref ref) {
  final manager = LocalCertimateManager(
    dio: ref.read(dioProvider),
    serversDao: ref.read(serversDaoProvider),
  );
  ref.onDispose(manager.dispose);
  return manager;
}

class LocalCertimateManager {
  LocalCertimateManager({required this.dio, required this.serversDao});

  final Dio dio;
  final ServersDao serversDao;
  final Map<String, Future<ReleaseInfo>> _releaseInfoCache = {};
  Directory? _baseDir;

  void dispose() {}

  Future<LocalServerCreateResult> createLocalServer({
    required String host,
    required String displayName,
    required String username,
    required String password,
    required String localId,
  }) async {
    debugPrint("start local server ($displayName): $host");
    final serverDir = await _getServerDir(localId);
    final releaseInfo = await _getReleaseInfo();
    final binaryPath = _getBinaryPath(serverDir, releaseInfo.version);
    await _downloadBinary(releaseInfo, binaryPath);

    final listenHost = _getListenHost(host);
    final process = await _startProcess(
      binaryPath,
      listenHost,
      workingDirectory: serverDir.path,
      environment: {
        "CERTIMATE_ADMIN_USERNAME": username,
        "CERTIMATE_ADMIN_PASSWORD": password,
      },
    );
    try {
      await _waitForServerReady(host, process);
      return LocalServerCreateResult(
        version: releaseInfo.version,
        pid: process.pid.toString(),
      );
    } catch (e) {
      process.kill();
      rethrow;
    }
  }

  Future<void> ensureLocalServersStarted() async {
    if (kIsWeb || !RunPlatform.isDesktop) {
      return;
    }
    final servers = (await serversDao.getAll()).where(
      (item) => (item.localId).isNotEmpty,
    );
    for (final server in servers) {
      if (server.autoStart != true) {
        continue;
      }
      final isAlive = await _isPortActive(server.host);
      if (isAlive) {
        continue;
      }
      try {
        await _startExistingServer(server);
      } catch (e) {
        debugPrint("start local server ${server.id} failed: $e");
      }
    }
  }

  Future<bool> isLocalServerRunning(ServerModel server) {
    return _isPortActive(server.host);
  }

  Future<Directory?> getLocalServerDir(String localId) async {
    if (kIsWeb || !RunPlatform.isDesktop || localId.isEmpty) {
      return null;
    }
    return _getServerDir(localId);
  }

  Future<void> startLocalServer(ServerModel server) async {
    if (server.localId.isEmpty) {
      return;
    }
    if (await _isPortActive(server.host)) {
      return;
    }
    await _startExistingServer(server);
  }

  Future<void> restartLocalServer(ServerModel server) async {
    await stopLocalServer(server);
    await startLocalServer(server);
  }

  Future<void> stopLocalServer(ServerModel server) async {
    if (server.localId.isEmpty) {
      return;
    }
    // 获取最新的 pid
    final row = await serversDao.getRowById(server.id);
    final pidStr = row?.pid ?? "";
    bool stopped = false;
    final pid = int.tryParse(pidStr);
    if (pid != null) {
      try {
        Process.killPid(pid);
      } catch (_) {
        // ignore
      }

      for (int i = 0; i < 6; i++) {
        await Future.delayed(const Duration(seconds: 1));
        if (!await _isPortActive(server.host)) {
          stopped = true;
          break;
        }
      }
    }

    if (stopped) {
      await serversDao.updatePidById(server.id, null);
    }
  }

  Future<ReleaseInfo> getLatestReleaseInfo({bool forceRefresh = false}) {
    if (forceRefresh) {
      _releaseInfoCache.remove("latest");
    }
    return _getReleaseInfo();
  }

  Future<void> upgradeLocalServer(ServerModel server, String newVersion) async {
    if (kIsWeb || !RunPlatform.isDesktop || server.localId.isEmpty) {
      return;
    }
    final isRunning = await _isPortActive(server.host);
    if (isRunning) {
      await stopLocalServer(server);
    }
    await _startExistingServer(server.copyWith(version: newVersion));
  }

  Future<void> _startExistingServer(ServerModel server) async {
    final serverDir = await _getServerDir(server.localId);
    final version = server.version.trim();
    final binaryPath = _getBinaryPath(serverDir, version);
    if (!await File(binaryPath).exists()) {
      final releaseInfo = await _getReleaseInfo(version: version);
      await _downloadBinary(releaseInfo, binaryPath);
    }
    final host = server.host;
    final listenHost = _getListenHost(host);
    final process = await _startProcess(
      binaryPath,
      listenHost,
      workingDirectory: serverDir.path,
    );
    try {
      await _waitForServerReady(host, process);
      await serversDao.updatePidAndVersionById(
        server.id,
        process.pid.toString(),
        version,
      );
    } catch (e) {
      process.kill();
      rethrow;
    }
  }

  Future<bool> _isPortActive(String host) async {
    try {
      final uri = Uri.parse(host);
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(milliseconds: 800),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _waitForServerReady(
    String host,
    Process process, {
    Duration timeout = const Duration(minutes: 1),
    Duration interval = const Duration(milliseconds: 300),
  }) async {
    int? processExitCode;
    unawaited(process.exitCode.then((code) => processExitCode = code));

    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      if (processExitCode != null) {
        throw Exception(
          "Failed to start local service: process exited (exitCode=$processExitCode).",
        );
      }
      if (await _isPortActive(host)) {
        return;
      }
      await Future.delayed(interval);
    }
    throw Exception("Local service start timed out. Please try again later.");
  }

  Future<Process> _startProcess(
    String binaryPath,
    String listenHost, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    final executable = File(binaryPath);
    if (!executable.existsSync()) {
      throw Exception("certimate executable not found.");
    }
    try {
      if (!Platform.isWindows) {
        await Process.run("chmod", ["+x", executable.path]);
      }
    } catch (_) {}
    final args = ["serve", "--http=$listenHost"];
    final process = await Process.start(
      executable.path,
      args,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
      environment: environment,
    );
    unawaited(
      process.stdout.listen((event) {
        debugPrint("certimate stdout: ${String.fromCharCodes(event)}");
      }).asFuture(),
    );
    unawaited(
      process.stderr.listen((event) {
        debugPrint("certimate stderr: ${String.fromCharCodes(event)}");
      }).asFuture(),
    );
    return process;
  }

  Future<int> _findAvailablePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  Future<int> pickAvailablePort() {
    return _findAvailablePort();
  }

  Future<ReleaseInfo> _getReleaseInfo({String? version}) {
    final key = (version == null || version.isEmpty) ? "latest" : version;
    return _releaseInfoCache.putIfAbsent(
      key,
      () => _fetchReleaseInfo(version: version),
    );
  }

  Future<ReleaseInfo> _fetchReleaseInfo({String? version}) async {
    final response = await dio.get(
      version == null || version.isEmpty
          ? "https://api.github.com/repos/certimate-go/certimate/releases/latest"
          : "https://api.github.com/repos/certimate-go/certimate/releases/tags/$version",
    );

    final tag = response.data["tag_name"];
    if (tag is! String || tag.isEmpty) {
      throw Exception("Unable to fetch the latest certimate version.");
    }
    final abiMap = {
      "windows_x64": "windows_amd64",
      "windows_ia32": "windows_386",
      "windows_arm64": "windows_arm64",
      "macos_x64": "darwin_amd64",
      "macos_arm64": "darwin_arm64",
      "linux_x64": "linux_amd64",
      "linux_arm64": "linux_arm64",
      "linux_arm": "linux_armv7",
    };
    final arch = abiMap[web.getCurrentAbi()];
    if (arch?.isNotEmpty != true) {
      throw Exception(
        "Unsupported platform/architecture (abi=${web.getCurrentAbi()}).",
      );
    }
    final expectedName = "certimate_${tag}_$arch.zip";
    final checksumsName = "checksums.txt";
    final assets = response.data["assets"];
    final info = ReleaseInfo(
      version: tag,
      assetName: expectedName,
      downloadUrl: _findAssetFileUrl(assets, expectedName) ?? "",
      checksumsDownloadUrl: _findAssetFileUrl(assets, checksumsName) ?? "",
    );

    if (info.downloadUrl.isEmpty) {
      throw Exception(
        "No certimate package found for the current platform: $expectedName",
      );
    }

    if (info.checksumsDownloadUrl.isEmpty) {
      throw Exception(
        "No checksums.txt found for certimate release: $tag. Unable to verify download integrity.",
      );
    }

    return info;
  }

  String? _findAssetFileUrl(List assets, String fileName) {
    for (final item in assets) {
      if (item is! Map) continue;
      final name = item["name"];
      if (name is! String || name.isEmpty) continue;
      if (name != fileName) continue;
      final url = item["browser_download_url"];
      if (url is String && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  Future<void> _downloadBinary(ReleaseInfo info, String binaryPath) async {
    final baseDir = await _ensureBaseDir();
    final archiveDir = Directory(p.join(baseDir.path, "archive"));
    await archiveDir.create(recursive: true);
    final archivePath = p.join(archiveDir.path, info.assetName);
    final checksumsPath = p.join(
      archiveDir.path,
      "${p.basenameWithoutExtension(archivePath)}_checksums.txt",
    );
    final checksumsFile = File(checksumsPath);
    if (!await checksumsFile.exists()) {
      await dio.download(info.checksumsDownloadUrl, checksumsPath);
    }
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      await dio.download(info.downloadUrl, archivePath);
    }
    try {
      await _verifyArchiveSha256(info, archivePath, checksumsPath);
    } catch (_) {
      archiveFile.delete();
      checksumsFile.delete();
      rethrow;
    }
    await _extractBinary(archivePath, binaryPath);
  }

  Future<void> _verifyArchiveSha256(
    ReleaseInfo info,
    String archivePath,
    String checksumsPath,
  ) async {
    final expected = await _findExpectedSha256(
      checksumsPath: checksumsPath,
      assetName: info.assetName,
    );
    final actual = await _sha256OfFile(archivePath);
    if (actual.toLowerCase() != expected.toLowerCase()) {
      throw Exception(
        "Checksum verification failed for ${info.assetName}: expected $expected, got $actual.",
      );
    }
  }

  Future<String> _sha256OfFile(String filePath) async {
    final digest = await sha256.bind(File(filePath).openRead()).first;
    return digest.toString();
  }

  Future<String> _findExpectedSha256({
    required String checksumsPath,
    required String assetName,
  }) async {
    final content = await File(checksumsPath).readAsString();
    final target = p.basename(assetName);
    for (final rawLine in content.split(RegExp(r"\r?\n"))) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith("#")) {
        continue;
      }

      final match1 = RegExp(r"^([a-fA-F0-9]{64})\s+\*?(.+)$").firstMatch(line);
      if (match1 != null) {
        final sha = match1.group(1) ?? "";
        final name = (match1.group(2) ?? "").trim();
        if (p.basename(name) == target) {
          return sha;
        }
        continue;
      }

      final match2 = RegExp(
        r"^SHA256\s*\((.+)\)\s*=\s*([a-fA-F0-9]{64})$",
      ).firstMatch(line);
      if (match2 != null) {
        final name = (match2.group(1) ?? "").trim();
        final sha = match2.group(2) ?? "";
        if (p.basename(name) == target) {
          return sha;
        }
      }
    }

    throw Exception(
      "Unable to find sha256 for $assetName in checksums file: ${p.basename(checksumsPath)}.",
    );
  }

  Future<void> _extractBinary(String archivePath, String binaryPath) async {
    final bytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final outFile = File(binaryPath);
    final expected = "certimate${RunPlatform.isWindows ? '.exe' : ''}";
    bool found = false;
    for (final file in archive) {
      if (file.isFile) {
        final filename = file.name;
        if (filename != expected) continue;
        final data = file.content as List<int>;
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data, flush: true);
        found = true;
        break;
      }
    }
    if (!found) {
      throw Exception("Executable not found in the archive: $expected");
    }
  }

  Future<Directory> _ensureBaseDir() async {
    if (_baseDir != null) {
      return _baseDir!;
    }
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appSupport.path, "certimate_local"));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _baseDir = dir;
    return dir;
  }

  Future<Directory> _getServerDir(String localId) async {
    final baseDir = await _ensureBaseDir();
    final dir = Directory(p.join(baseDir.path, localId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _getBinaryPath(Directory serverDir, String version) {
    return p.join(
      serverDir.path,
      "certimate_$version${RunPlatform.isWindows ? '.exe' : ''}",
    );
  }

  String _getListenHost(String host) {
    final uri = Uri.tryParse(host);
    if (uri != null && uri.hasAuthority) {
      return uri.authority;
    }
    return host
        .replaceFirst(RegExp(r"^https?://"), "")
        .replaceAll(RegExp(r"/+$"), "");
  }
}

class ReleaseInfo {
  final String version;
  final String assetName;
  final String downloadUrl;
  final String checksumsDownloadUrl;

  ReleaseInfo({
    required this.version,
    required this.assetName,
    required this.downloadUrl,
    required this.checksumsDownloadUrl,
  });
}

class LocalServerCreateResult {
  final String version;
  final String pid;

  LocalServerCreateResult({required this.version, required this.pid});
}
