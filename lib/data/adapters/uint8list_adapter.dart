import 'package:hive/hive.dart';
import 'dart:typed_data';

class Uint8ListAdapter extends TypeAdapter<Uint8List> {
  @override
  final int typeId = 1;

  @override
  Uint8List read(BinaryReader reader) {
    final length = reader.readInt();
    return reader.readByteList(length);
  }

  @override
  void write(BinaryWriter writer, Uint8List obj) {
    writer.writeInt(obj.length);
    writer.writeByteList(obj);
  }
}