class HelperFunctions {
  static String formatDate(DateTime dt, {bool hasTime = true}) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return hasTime
        ? '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
