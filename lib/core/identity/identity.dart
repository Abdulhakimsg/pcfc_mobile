class Identity {
  final String id, name;
  const Identity({required this.id, required this.name});
}
class IdentityContext {
  static Identity current = const Identity(id: 'user-123', name: 'MOHAMMED ALI');
}