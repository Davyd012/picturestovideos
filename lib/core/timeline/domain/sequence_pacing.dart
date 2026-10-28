enum SequencePacing {
  relaxed(Duration(seconds: 5)),
  balanced(Duration(milliseconds: 3500)),
  energetic(Duration(milliseconds: 2500));

  const SequencePacing(this.targetDuration);
  final Duration targetDuration;
}
