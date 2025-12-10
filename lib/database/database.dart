import "package:drift/drift.dart";
import "package:drift_flutter/drift_flutter.dart";
import "package:path_provider/path_provider.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "database.g.dart";

class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get displayName => text()();

  TextColumn get host => text()();

  TextColumn get userId => text()();

  TextColumn get username => text()();

  TextColumn get passwordId => text()();

  TextColumn get token => text()();

  DateTimeColumn get createdAt => dateTime()();
}

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  return AppDatabase();
}

@DriftDatabase(tables: [Servers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: "cert_database",
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse("sqlite3.wasm"),
        driftWorker: Uri.parse("drift_worker.dart.js"),
      ),
    );
  }
}
