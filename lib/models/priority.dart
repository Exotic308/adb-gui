enum Priority {
  verbose('V'),
  debug('D'),
  info('I'),
  warn('W'),
  error('E'),
  fatal('F');

  final String letter;

  const Priority(this.letter);

  static Priority fromLetter(String letter) {
    switch (letter.toUpperCase()) {
      case 'V':
        return Priority.verbose;
      case 'D':
        return Priority.debug;
      case 'I':
        return Priority.info;
      case 'W':
        return Priority.warn;
      case 'E':
        return Priority.error;
      case 'F':
        return Priority.fatal;
      default:
        return Priority.verbose;
    }
  }

  bool operator >=(Priority other) => index >= other.index;
  bool operator <=(Priority other) => index <= other.index;
}
