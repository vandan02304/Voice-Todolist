import 'package:intl/intl.dart';
import '../data/models/task_model.dart';

/// The action extracted from a voice command.
enum VoiceAction {
  create,
  complete,
  uncomplete,
  delete,
  list,
  update,
  unknown,
}

/// Result of parsing a natural-language voice command.
class ParsedCommand {
  final VoiceAction action;

  /// The task title extracted from the command (may be null for list/unknown).
  final String? taskTitle;

  /// Optional due date parsed from relative/absolute expressions.
  final DateTime? dueDate;

  /// Optional priority parsed from the command.
  final TaskPriority? priority;

  /// The raw input text for display.
  final String rawText;

  const ParsedCommand({
    required this.action,
    required this.rawText,
    this.taskTitle,
    this.dueDate,
    this.priority,
  });

  @override
  String toString() =>
      'ParsedCommand(action: $action, title: $taskTitle, dueDate: $dueDate)';
}

/// Regex/keyword-based NLP parser that converts voice transcript strings into
/// structured [ParsedCommand] objects.
///
/// Supported command patterns:
///   - "Create/Add task <title> [for/on/due <date>]"
///   - "Complete/Done/Finish/Check task <title>"
///   - "Uncomplete/Uncheck task <title>"
///   - "Delete/Remove/Cancel task <title>"
///   - "List/Show/What are my tasks"
///   - "Update/Rename task <title> to <new title>"
class CommandParser {
  // ── Action keyword patterns ────────────────────────────────────────────
  static final _createReg = RegExp(
    r'^(create|add|new|make|set)\s+(a\s+)?(task|reminder|todo|item)?\s*',
    caseSensitive: false,
  );

  static final _completeReg = RegExp(
    r'^(complete|done|finish|check|mark as done|tick)\s+(task\s+)?',
    caseSensitive: false,
  );

  static final _uncompleteReg = RegExp(
    r'^(uncomplete|uncheck|undo|undone|reopen|mark as incomplete)\s+(task\s+)?',
    caseSensitive: false,
  );

  static final _deleteReg = RegExp(
    r'^(delete|remove|cancel|erase|drop)\s+(task\s+)?',
    caseSensitive: false,
  );

  static final _listReg = RegExp(
    r'^(list|show|display|what are|read|tell me)\s+(my\s+)?(tasks?|todos?|reminders?)?',
    caseSensitive: false,
  );

  static final _updateReg = RegExp(
    r'^(update|rename|change|edit)\s+(task\s+)',
    caseSensitive: false,
  );

  // ── Date/time patterns ─────────────────────────────────────────────────
  static final _dateKeyword = RegExp(
    r'\s+(for|on|due|at|by)\s+(.+)$',
    caseSensitive: false,
  );

  static final _timePattern = RegExp(
    r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
    caseSensitive: false,
  );

  // ── Priority patterns ──────────────────────────────────────────────────
  static final _priorityHigh = RegExp(r'\b(urgent|high|important|critical)\b', caseSensitive: false);
  static final _priorityLow  = RegExp(r'\b(low|minor|someday|whenever)\b',    caseSensitive: false);

  /// Parses [transcript] and returns a [ParsedCommand].
  static ParsedCommand parse(String transcript) {
    final text = transcript.trim();

    if (_listReg.hasMatch(text)) {
      return ParsedCommand(action: VoiceAction.list, rawText: text);
    }

    if (_createReg.hasMatch(text)) {
      final rest = text.replaceFirst(_createReg, '').trim();
      return _buildCommand(VoiceAction.create, rest, text);
    }

    if (_completeReg.hasMatch(text)) {
      final rest = text.replaceFirst(_completeReg, '').trim();
      return _buildCommand(VoiceAction.complete, rest, text);
    }

    if (_uncompleteReg.hasMatch(text)) {
      final rest = text.replaceFirst(_uncompleteReg, '').trim();
      return _buildCommand(VoiceAction.uncomplete, rest, text);
    }

    if (_deleteReg.hasMatch(text)) {
      final rest = text.replaceFirst(_deleteReg, '').trim();
      return _buildCommand(VoiceAction.delete, rest, text);
    }

    if (_updateReg.hasMatch(text)) {
      final rest = text.replaceFirst(_updateReg, '').trim();
      return _buildCommand(VoiceAction.update, rest, text);
    }

    return ParsedCommand(action: VoiceAction.unknown, rawText: text);
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  static ParsedCommand _buildCommand(
      VoiceAction action, String rest, String rawText) {
    // Extract date
    DateTime? dueDate;
    String title = rest;

    final dateMatch = _dateKeyword.firstMatch(rest);
    if (dateMatch != null) {
      title = rest.substring(0, dateMatch.start).trim();
      final dateStr = dateMatch.group(2)!.trim();
      dueDate = _parseDate(dateStr);
    }

    // Extract priority
    TaskPriority? priority;
    if (_priorityHigh.hasMatch(title)) {
      priority = TaskPriority.high;
      title = title.replaceAll(_priorityHigh, '').trim();
    } else if (_priorityLow.hasMatch(title)) {
      priority = TaskPriority.low;
      title = title.replaceAll(_priorityLow, '').trim();
    }

    // Clean up the title
    title = _cleanTitle(title);

    return ParsedCommand(
      action: action,
      rawText: rawText,
      taskTitle: title.isEmpty ? null : title,
      dueDate: dueDate,
      priority: priority,
    );
  }

  /// Parses common date/time expressions into a [DateTime].
  static DateTime? _parseDate(String dateStr) {
    final now = DateTime.now();
    final lower = dateStr.toLowerCase().trim();

    // Relative
    if (lower == 'today')    return DateTime(now.year, now.month, now.day, 23, 59);
    if (lower == 'tomorrow') return DateTime(now.year, now.month, now.day + 1, 23, 59);
    if (lower == 'yesterday')return DateTime(now.year, now.month, now.day - 1, 23, 59);

    // Next weekday: "next monday", "next friday"
    final nextWeekday = RegExp(r'next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
        caseSensitive: false);
    final nw = nextWeekday.firstMatch(lower);
    if (nw != null) {
      return _nextWeekday(_weekdayNumber(nw.group(1)!));
    }

    // This weekday: "this friday"
    final thisWeekday = RegExp(r'this\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)',
        caseSensitive: false);
    final tw = thisWeekday.firstMatch(lower);
    if (tw != null) {
      return _nextWeekday(_weekdayNumber(tw.group(1)!));
    }

    // "in N days"
    final inDays = RegExp(r'in\s+(\d+)\s+days?');
    final id = inDays.firstMatch(lower);
    if (id != null) {
      final n = int.parse(id.group(1)!);
      return DateTime(now.year, now.month, now.day + n, 23, 59);
    }

    // "in N weeks"
    final inWeeks = RegExp(r'in\s+(\d+)\s+weeks?');
    final iw = inWeeks.firstMatch(lower);
    if (iw != null) {
      final n = int.parse(iw.group(1)!);
      return DateTime(now.year, now.month, now.day + n * 7, 23, 59);
    }

    // Month day (e.g., "March 26", "26 March")
    final monthDay = RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})',
        caseSensitive: false);
    final md = monthDay.firstMatch(lower);
    if (md != null) {
      final month = _monthNumber(md.group(1)!);
      final day   = int.parse(md.group(2)!);
      var year = now.year;
      if (DateTime(year, month, day).isBefore(now)) year++;
      return DateTime(year, month, day, 23, 59);
    }

    // Day Month (e.g., "26 March")
    final dayMonth = RegExp(r'(\d{1,2})\s+(january|february|march|april|may|june|july|august|september|october|november|december)',
        caseSensitive: false);
    final dm = dayMonth.firstMatch(lower);
    if (dm != null) {
      final day   = int.parse(dm.group(1)!);
      final month = _monthNumber(dm.group(2)!);
      var year = now.year;
      if (DateTime(year, month, day).isBefore(now)) year++;
      return DateTime(year, month, day, 23, 59);
    }

    // Parse time component separately if present
    int addHour = 0, addMin = 0;
    final tm = _timePattern.firstMatch(lower);
    if (tm != null) {
      addHour = int.parse(tm.group(1)!);
      addMin  = tm.group(2) != null ? int.parse(tm.group(2)!) : 0;
      final period = tm.group(3)?.toLowerCase();
      if (period == 'pm' && addHour < 12) addHour += 12;
      if (period == 'am' && addHour == 12) addHour = 0;
    }
    if (addHour > 0) {
      return DateTime(now.year, now.month, now.day, addHour, addMin);
    }

    // Try intl DateFormat
    for (final fmt in ['MMM d', 'MMMM d', 'MM/dd', 'd MMM', 'yyyy-MM-dd', 'MM-dd-yyyy']) {
      try {
        final parsed = DateFormat(fmt).parse(dateStr);
        var year = now.year;
        if (DateTime(year, parsed.month, parsed.day).isBefore(now)) year++;
        return DateTime(year, parsed.month, parsed.day, 23, 59);
      } catch (_) {}
    }

    return null;
  }

  static DateTime _nextWeekday(int targetWeekday) {
    final now = DateTime.now();
    var daysUntil = targetWeekday - now.weekday;
    if (daysUntil <= 0) daysUntil += 7;
    return DateTime(now.year, now.month, now.day + daysUntil, 23, 59);
  }

  static int _weekdayNumber(String name) {
    const map = {
      'monday': 1, 'tuesday': 2, 'wednesday': 3,
      'thursday': 4, 'friday': 5, 'saturday': 6, 'sunday': 7,
    };
    return map[name.toLowerCase()] ?? 1;
  }

  static int _monthNumber(String name) {
    const map = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
    };
    return map[name.toLowerCase()] ?? 1;
  }

  static String _cleanTitle(String title) {
    // Remove leading/trailing filler words
    return title
        .replaceAll(RegExp(r'^(called|named|titled|the task)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
