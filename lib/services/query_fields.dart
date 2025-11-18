import 'package:flutter_querybuilder/flutter_querybuilder.dart';

import '../models/priority.dart';

/// Returns field definitions for LogEntry properties
List<Field> getLogEntryFields() {
  return [
    Field(
      name: 'tag',
      label: 'Tag',
      inputType: InputType.text,
      operators: [equals, notEquals, contains, startsWith, endsWith, matchesRegex],
      defaultOperator: contains,
    ),
    Field(
      name: 'message',
      label: 'Message',
      inputType: InputType.text,
      operators: [equals, notEquals, contains, startsWith, endsWith, matchesRegex],
      defaultOperator: contains,
    ),
    Field(
      name: 'priority',
      label: 'Priority',
      inputType: InputType.select,
      operators: [equals, notEquals, inList, notInList],
      options: Priority.values.map((p) => p.name).toList(),
      defaultOperator: equals,
      defaultValue: Priority.warn.name,
    ),
    Field(
      name: 'processId',
      label: 'Process ID',
      inputType: InputType.number,
      operators: [equals, notEquals, greaterThan, lessThan, greaterOrEqual, lessOrEqual, between],
      defaultOperator: equals,
    ),
    Field(
      name: 'pid',
      label: 'PID',
      inputType: InputType.number,
      operators: [equals, notEquals, greaterThan, lessThan, greaterOrEqual, lessOrEqual, between],
      defaultOperator: equals,
    ),
    Field(
      name: 'threadId',
      label: 'Thread ID',
      inputType: InputType.number,
      operators: [equals, notEquals, greaterThan, lessThan, greaterOrEqual, lessOrEqual, between],
      defaultOperator: equals,
    ),
    Field(
      name: 'tid',
      label: 'TID',
      inputType: InputType.number,
      operators: [equals, notEquals, greaterThan, lessThan, greaterOrEqual, lessOrEqual, between],
      defaultOperator: equals,
    ),
    Field(
      name: 'dateTime',
      label: 'Date/Time',
      inputType: InputType.date,
      operators: [equals, notEquals, greaterThan, lessThan, greaterOrEqual, lessOrEqual, between],
      defaultOperator: equals,
    ),
    Field(
      name: 'timeString',
      label: 'Time String',
      inputType: InputType.text,
      operators: [equals, notEquals, contains, startsWith, endsWith, matchesRegex],
      defaultOperator: equals,
    ),
  ];
}

