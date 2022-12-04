String normalizePath(String key, String prefix) {
  // Remove prefix from Object/Directory path
  return key.replaceAll(prefix, '');
}
