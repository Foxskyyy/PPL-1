import 'package:flutter/material.dart';

class NicknameNotifier extends ValueNotifier<String> {
  NicknameNotifier() : super("M. Aria Ardhana");

  void updateNickname(String newNickname) {
    value = newNickname;
  }
}

final nicknameNotifier = NicknameNotifier();
