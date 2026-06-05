// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../data/models/habit_model.dart';

const _kIcons = [
  Icons.fitness_center,
  Icons.menu_book,
  Icons.self_improvement,
  Icons.directions_run,
  Icons.water_drop,
  Icons.bedtime,
  Icons.favorite,
  Icons.brush,
  Icons.music_note,
  Icons.code,
  Icons.restaurant,
  Icons.directions_bike,
];

const _kColors = [
  Color(0xFF7F77DD),
  Color(0xFF1D9E75),
  Color(0xFFD85A30),
  Color(0xFFD4537E),
  Color(0xFF378ADD),
  Color(0xFF639922),
  Color(0xFFBA7517),
  Color(0xFF888780),
];

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddHabitSheet(),
    );
  }

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  IconData _selectedIcon = _kIcons.first;
  Color _selectedColor = _kColors.first;
  HabitFrequency _frequency = HabitFrequency.daily;
  final Set<int> _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};
  TimeOfDay? _reminderTime;
  final bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            const SizedBox(height: 20),
            _SectionLabel('Habit name'),
            const SizedBox(height: 8),
            _NameField(controller: _nameController),
            const SizedBox(height: 20),
            _SectionLabel('Icon'),
            const SizedBox(height: 8),
            _IconPicker(
              icons: _kIcons,
              selected: _selectedIcon,
              color: _selectedColor,
              onSelect: (ic) => setState(() => _selectedIcon = ic),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Color'),
            const SizedBox(height: 8),
            _ColorPicker(
              colors: _kColors,
              selected: _selectedColor,
              onSelect: (c) => setState(() => _selectedColor = c),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Frequency'),
            const SizedBox(height: 8),
            _FrequencyToggle(
              value: _frequency,
              onChange: (f) => setState(() => _frequency = f),
            ),
            if (_frequency == HabitFrequency.weekly) ...[
              const SizedBox(height: 12),
              _WeekdayPicker(
                selected: _selectedWeekdays,
                color: _selectedColor,
                onToggle: (day) => setState(() {
                  if (_selectedWeekdays.contains(day)) {
                    if (_selectedWeekdays.length > 1) {
                      _selectedWeekdays.remove(day);
                    }
                  } else {
                    _selectedWeekdays.add(day);
                  }
                }),
              ),
            ],
            const SizedBox(height: 20),
            _ReminderRow(
              time: _reminderTime,
              onTap: _pickTime,
              onClear: () => setState(() => _reminderTime = null),
            ),
            const SizedBox(height: 28),
            _SaveButton(
              color: _selectedColor,
              isSaving: _isSaving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  const _NameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: 'e.g. Read for 20 minutes',
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a habit name';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        if (value.trim().length > 50) {
          return 'Name must be 50 characters or fewer';
        }
        return null;
      },
    );
  }
}

class _IconPicker extends StatelessWidget {
  final List<IconData> icons;
  final IconData selected;
  final Color color;
  final ValueChanged<IconData> onSelect;

  const _IconPicker({
    required this.icons,
    required this.selected,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: icons.map((ic) {
        final isSelected = ic == selected;
        return GestureDetector(
          onTap: () => onSelect(ic),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              ic,
              size: 20,
              color: isSelected ? color : Colors.grey.shade500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelect;

  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: colors.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 6)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _FrequencyToggle extends StatelessWidget {
  final HabitFrequency value;
  final ValueChanged<HabitFrequency> onChange;

  const _FrequencyToggle({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: HabitFrequency.values.map((f) {
        final isSelected = f == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChange(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: f == HabitFrequency.daily ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                f.name[0].toUpperCase() + f.name.substring(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  final Set<int> selected;
  final Color color;
  final ValueChanged<int> onToggle;

  const _WeekdayPicker({
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = i + 1;
        final isOn = selected.contains(day);
        return GestureDetector(
          onTap: () => onToggle(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOn ? color : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isOn ? color : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isOn ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final TimeOfDay? time;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _ReminderRow({
    required this.time,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.notifications_outlined, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            time != null ? time!.format(context) : 'No reminder set',
            style: TextStyle(
              fontSize: 14,
              color: time != null
                  ? Theme.of(context).textTheme.bodyMedium!.color
                  : Colors.grey,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(time != null ? 'Change' : 'Set reminder'),
        ),
        if (time != null)
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final Color color;
  final bool isSaving;
  final VoidCallback onTap;

  const _SaveButton({
    required this.color,
    required this.isSaving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Add habit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
