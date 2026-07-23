class ImageCropTransform {
  const ImageCropTransform({this.focalX = 0, this.focalY = 0, this.zoom = 1})
    : assert(focalX >= -1 && focalX <= 1),
      assert(focalY >= -1 && focalY <= 1),
      assert(zoom >= 1);

  static const centered = ImageCropTransform();
  static const maxZoom = 4.0;

  final double focalX;
  final double focalY;
  final double zoom;

  bool get isCentered => focalX == 0 && focalY == 0 && zoom == 1;

  ImageCropTransform copyWith({double? focalX, double? focalY, double? zoom}) {
    return ImageCropTransform(
      focalX: (focalX ?? this.focalX).clamp(-1, 1),
      focalY: (focalY ?? this.focalY).clamp(-1, 1),
      zoom: (zoom ?? this.zoom).clamp(1, maxZoom),
    );
  }

  Map<String, Object?> toJson() {
    return {'focalX': focalX, 'focalY': focalY, 'zoom': zoom};
  }

  factory ImageCropTransform.fromJson(Object? json) {
    if (json is! Map) {
      return centered;
    }
    return ImageCropTransform(
      focalX: ((json['focalX'] as num?)?.toDouble() ?? 0).clamp(-1, 1),
      focalY: ((json['focalY'] as num?)?.toDouble() ?? 0).clamp(-1, 1),
      zoom: ((json['zoom'] as num?)?.toDouble() ?? 1).clamp(1, maxZoom),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ImageCropTransform &&
        other.focalX == focalX &&
        other.focalY == focalY &&
        other.zoom == zoom;
  }

  @override
  int get hashCode => Object.hash(focalX, focalY, zoom);
}
