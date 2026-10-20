enum PropertyType {
  title,
  text,
  number,
  select,
  multiSelect,
  status,
  date,
  checkbox,
  url,
  email,
  phone,
  createdTime,
  lastEditedTime,
  relation,
  rollup,
  formula,
}

extension PropertyTypeParsing on PropertyType {
  static PropertyType fromString(String str) {
    return PropertyType.values.firstWhere(
      (e) => e.name.toLowerCase() == str.toLowerCase(),
      orElse: () => PropertyType.text,
    );
  }
}
