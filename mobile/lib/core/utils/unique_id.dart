import 'dart:math';

/// Generates a random alphanumeric ID similar to AppSheet's UNIQUEID().
/// [length] defaults to 8 for maestros, use 5 for tablas with shorter codes.
String uniqueId([int length = 8]) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random.secure();
  return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
}
