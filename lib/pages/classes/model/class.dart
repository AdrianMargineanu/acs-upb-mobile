import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

enum ShortcutType { main, classbook, resource, other }

extension ShortcutTypeExtension on ShortcutType {
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case ShortcutType.main:
        return S.of(context).shortcutTypeMain;
      case ShortcutType.classbook:
        return S.of(context).shortcutTypeClassbook;
      case ShortcutType.resource:
        return S.of(context).shortcutTypeResource;
      default:
        return S.of(context).shortcutTypeOther;
    }
  }
}

class Shortcut {
  final ShortcutType type;
  final String name;
  final String link;
  final String ownerUid;

  Shortcut({this.type, this.name, this.link, this.ownerUid});
}

class ClassHeader {
  final String id;
  final String name;
  final String acronym;
  final String category;

  ClassHeader({this.id, this.name, this.acronym, this.category});
}

class Class {
  ClassHeader header;
  final List<Shortcut> shortcuts;
  final Map<String, double> grading;

  Class(
      {@required this.header,
      List<Shortcut> shortcuts,
      this.grading})
      : shortcuts = shortcuts ?? [];
}
