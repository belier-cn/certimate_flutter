Future<(A, B)> wait2<A, B>(Future<A> fa, Future<B> fb) async {
  final a = await fa;
  final b = await fb;
  return (a, b);
}
