// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../data/models/habit_model.dart';

class HabitTile extends StatelessWidget {
  final HabitModel habit;

  const HabitTile({super.key, required this.habit});

  Color get _habitColor =>
      Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _habitColor.withOpacity(0.1),
          child: Icon(
            IconData(habit.iconCode, fontFamily: 'MaterialIcons'),
            color: _habitColor,
          ),
        ),
        title: Text(habit.name),
        trailing: Checkbox(
          value: false,
          activeColor: _habitColor,
          onChanged: (value) {},
        ),
        onTap: () {},
        onLongPress: () {},
      ),
    );
  }
}
