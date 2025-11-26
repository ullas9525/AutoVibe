import 'package:autovibe/models/schedule_model.dart';
import 'package:autovibe/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CreateScheduleScreen extends StatefulWidget {
  final Schedule? existingSchedule;

  const CreateScheduleScreen({super.key, this.existingSchedule});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final _nameController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  List<bool> _days = List.filled(7, true); // Default all days active

  @override
  void initState() {
    super.initState();
    if (widget.existingSchedule != null) {
      _nameController.text = widget.existingSchedule!.name;
      _startTime = widget.existingSchedule!.startTime;
      _endTime = widget.existingSchedule!.endTime;
      _days = List.from(widget.existingSchedule!.days);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Schedule'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schedule Name', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Work Hours',
                hintStyle: TextStyle(color: Colors.grey.shade600),
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTimeTile('Start Time', _startTime, (t) => setState(() => _startTime = t)),
                  const Divider(height: 1, color: Colors.white10),
                  _buildTimeTile('End Time', _endTime, (t) => setState(() => _endTime = t)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Repeat on', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                // 0=Mon, 6=Sun. Figma shows S M T W T F S.
                // Let's align with DateTime.weekday: 1=Mon, 7=Sun.
                // But our list is 0-indexed Mon-Sun.
                // Figma order: S M T W T F S (Sun Mon Tue...) usually? Or Mon Tue...?
                // Let's assume Mon-Sun for consistency with code, but display labels.
                final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final isSelected = _days[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _days[index] = !_days[index];
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.accentColor : const Color(0xFF242A38),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile(String title, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.access_time, color: AppTheme.accentColor.withOpacity(0.8)),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time.format(context),
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
    );
  }

  void _save() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name')),
      );
      return;
    }

    final schedule = Schedule(
      id: widget.existingSchedule?.id ?? const Uuid().v4(),
      name: _nameController.text,
      startTime: _startTime,
      endTime: _endTime,
      days: _days,
      isEnabled: widget.existingSchedule?.isEnabled ?? true,
    );

    Navigator.pop(context, schedule);
  }
}
