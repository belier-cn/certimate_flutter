import "package:certimate/database/database.dart";
import "package:drift/drift.dart" hide JsonKey;
import "package:freezed_annotation/freezed_annotation.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "servers_dao.freezed.dart";
part "servers_dao.g.dart";

@Riverpod(keepAlive: true)
ServersDao serversDao(Ref ref) {
  final db = ref.read(databaseProvider);
  return ServersDao(db);
}

@DriftAccessor(tables: [Servers])
class ServersDao extends DatabaseAccessor<AppDatabase> with _$ServersDaoMixin {
  ServersDao(super.db);

  Future<Server?> getRowById(int id) async {
    final query = select(servers)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<void> updatePidById(int id, String? pid) async {
    await updateById(id, ServersCompanion(pid: Value(pid)));
  }

  Future<void> updatePidAndVersionById(
    int id,
    String? pid,
    String? version,
  ) async {
    await updateById(
      id,
      ServersCompanion(pid: Value(pid), version: Value(version)),
    );
  }

  Future<List<ServerModel>> getAll({String displayName = ""}) async {
    final query = select(servers);
    if (displayName.isNotEmpty) {
      query.where((t) => t.displayName.contains(displayName));
    }
    return query.get().then(
      (list) => list.map((item) => item.toModel()).toList(),
    );
  }

  Future<ServerModel?> getById(int id) async {
    final query = select(servers)..where((t) => t.id.equals(id));
    return query.getSingleOrNull().then((value) => value?.toModel());
  }

  Future<ServerModel?> insert(ServersCompanion server) async {
    final data = await into(servers).insertReturningOrNull(server);
    return data?.toModel();
  }

  Future<ServerModel?> updateById(int id, ServersCompanion server) async {
    final count = await (update(
      servers,
    )..where((t) => t.id.equals(id))).write(server);
    if (count > 0) {
      return await getById(id);
    }
    return null;
  }

  Future<int> deleteById(int id) async {
    return (delete(servers)..where((t) => t.id.equals(id))).go();
  }
}

@freezed
abstract class ServerModel with _$ServerModel {
  factory ServerModel({
    required int id,
    required String displayName,
    required String host,
    required String userId,
    required String username,
    required String passwordId,
    required String token,
    required String localId,
    required DateTime createdAt,
    required String version,
    required bool autoStart,
  }) = _ServerModel;
}

extension ServerModelConvert on ServerModel {
  ServersCompanion toUpdateCompanion() {
    return ServersCompanion(
      displayName: Value(displayName),
      host: Value(host),
      userId: Value(userId),
      username: Value(username),
      token: Value(token),
      localId: Value(localId),
      version: Value(version),
    );
  }
}

extension ServerConvert on Server {
  ServerModel toModel() {
    return ServerModel(
      id: id,
      host: host,
      displayName: displayName,
      userId: userId,
      username: username,
      passwordId: passwordId,
      token: token,
      localId: localId ?? "",
      version: version ?? "",
      createdAt: createdAt,
      autoStart: autoStart ?? false,
    );
  }
}
