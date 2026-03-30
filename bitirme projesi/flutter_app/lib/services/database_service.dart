import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/scan_history.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ScanHistorySchema],
      directory: dir.path,
    );
  }

  static Future<void> saveScan(ScanHistory scan) async {
    await isar.writeTxn(() async {
      await isar.scanHistorys.put(scan);
    });
  }

  static Future<List<ScanHistory>> getAllScans() async {
    return await isar.scanHistorys.where().sortByScanDateDesc().findAll();
  }

  static Future<void> deleteScan(int id) async {
    await isar.writeTxn(() async {
      await isar.scanHistorys.delete(id);
    });
  }
}
