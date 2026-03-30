import 'package:isar/isar.dart';

part 'scan_history.g.dart';

@collection
class ScanHistory {
  Id id = Isar.autoIncrement;

  late String imagePath;
  
  late String diseaseName;
  
  late double confidence;
  
  late DateTime scanDate;
}
