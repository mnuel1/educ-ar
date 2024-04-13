import 'package:vector_math/vector_math_64.dart' as vector;

class SceneNode {
  final String name;
  final String modelPath;
  final vector.Vector3 position;
  final vector.Vector3 scale;
  // final List<String> subtitle;
  // final List<int> subtitleDuration;
  const SceneNode({
    required this.name,
    required this.modelPath,
    required this.position,
    required this.scale,
    // required this.subtitle,
    // required this.subtitleDuration,
  });
}
