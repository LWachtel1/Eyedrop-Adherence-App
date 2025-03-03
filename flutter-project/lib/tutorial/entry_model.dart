import 'package:flutter/material.dart';

class EntryModel {
  String name;
  String iconPath;
  Color boxColor;

  EntryModel(
      {required this.name, required this.iconPath, required this.boxColor});

  static List<EntryModel> getEntries() {
    List<EntryModel> entries = [];

    entries.add(EntryModel(
        name: "An entry",
        iconPath: "assets/icons/notepad.svg",
        boxColor: Colors.blueGrey));

    return entries;
  }
}
