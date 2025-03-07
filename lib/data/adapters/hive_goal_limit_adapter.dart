import 'package:hive/hive.dart';
import 'dart:typed_data';
import '../models/hive_goal_limit.dart';

class HiveGoalLimitAdapter extends TypeAdapter<HiveGoalLimit> {
  @override
  final int typeId = 0;

  @override
  HiveGoalLimit read(BinaryReader reader) {
    final appName = reader.readString();
    final packageName = reader.readString();

    // Read appIcon (could be null)
    final hasAppIcon = reader.readBool();
    Uint8List? appIcon;
    if (hasAppIcon) {
      final length = reader.readInt();
      appIcon = reader.readByteList(length);
    }

    final limitInMinutes = reader.readInt();
    final currentUsage = reader.readInt();
    final category = reader.readString();
    final isLimitReached = reader.readBool();

    return HiveGoalLimit(
      appName: appName,
      packageName: packageName,
      appIcon: appIcon,
      limitInMinutes: limitInMinutes,
      currentUsage: currentUsage,
      category: category,
      isLimitReached: isLimitReached,
    );
  }

  @override
  void write(BinaryWriter writer, HiveGoalLimit obj) {
    writer.writeString(obj.appName);
    writer.writeString(obj.packageName);

    // Write appIcon (could be null)
    writer.writeBool(obj.appIcon != null);
    if (obj.appIcon != null) {
      writer.writeInt(obj.appIcon!.length);
      writer.writeByteList(obj.appIcon!);
    }

    writer.writeInt(obj.limitInMinutes);
    writer.writeInt(obj.currentUsage);
    writer.writeString(obj.category);
    writer.writeBool(obj.isLimitReached);
  }
}