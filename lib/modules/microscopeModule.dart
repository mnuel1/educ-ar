import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for loading JSON file
import 'package:provider/provider.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:developer' as developer;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MicroscopeModel(), // Provide the QuizModel to the widget tree
      child: const MaterialApp(
        // title: 'Quiz App',
        home: MicroscopeModuleWidget()
      ),
    );
  }
}

class MicroscopeModel extends ChangeNotifier {
  List<Map<String, dynamic>> _descriptions = []; // Modified to allow changes
  int _currentDescriptionIndex = 0;
  Map<String, dynamic> get currentDescription => _descriptions[_currentDescriptionIndex];
  bool _answerChosen = false;

  Timer? _timer;

  MicroscopeModel() {
    _loadDescriptions(); // Load descriptions from JSON file
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentDescriptionIndex < _descriptions.length - 1) {
        if ([4, 22, 34, 37, 39, 41, 43].contains(_currentDescriptionIndex) && _answerChosen ||
            ![4, 22, 34, 37, 39, 41, 43].contains(_currentDescriptionIndex) && !_answerChosen) {
          nextDescription();
        }
      } else {
        _timer?.cancel();
        // Quiz completed, perform actions accordingly
        print('Quiz completed!');
      }
    });
  }

  void chooseAnswer(String answer) {
    if (!_answerChosen) {
      _answerChosen = true;
    }
  }

  void nextDescription() {
    if (_currentDescriptionIndex < _descriptions.length - 1 && !_answerChosen) {
      _currentDescriptionIndex++;
      _answerChosen = false; // Reset answer chosen flag
      notifyListeners();
    } else {
      _timer?.cancel();
    }
  }

  void _loadDescriptions() async {
    try {
      String data = await rootBundle.loadString('assets/scripts/week1Script.json');
      List<dynamic> jsonList = json.decode(data);
      _descriptions = jsonList.cast<Map<String, dynamic>>(); // Cast JSON objects to Map
      notifyListeners(); // Notify listeners after descriptions are loaded
    } catch (e) {
      print('Error loading descriptions: $e');
    }
  }
}

class MicroscopeModuleWidget extends StatefulWidget {
  const MicroscopeModuleWidget({super.key});
  @override
  _MicroscopeModuleWidget createState() => _MicroscopeModuleWidget();
}



class _MicroscopeModuleWidget extends State<MicroscopeModuleWidget> {

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  AudioPlayer audioPlayer = AudioPlayer();

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];


  Timer? _timer;
  var singleHit = null;

  String descriptionBoard = 'Move you camera until white dots will display in your'
      'screen. Touch at any white dots to start your learning!';
  int objectBoardIndex = 0;

  void changeText(String text) {
    setState(() {
      descriptionBoard = text;
    });
  }
  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }
  @override
  Widget build(BuildContext context) {
    MicroscopeModel microscopeModel = Provider.of<MicroscopeModel>(context);

    return Scaffold(
      appBar: AppBar(
        // title: Text('Quiz App'),
      ),
        body: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  microscopeModel.currentDescription['description'],
                  style: const TextStyle(fontSize: 20.0),
                ),
                if (microscopeModel.currentDescription.containsKey('choices')) // Check if 'choices' key exists
                  const SizedBox(height: 20.0),
                Column(
                  children: List.generate(
                    (microscopeModel.currentDescription['choices'] as List?)?.length ?? 0, // Check for null and get length
                        (index) => ChoiceButton(
                      choice: microscopeModel.currentDescription['choices'][index],
                      onPressed: () {
                        microscopeModel.chooseAnswer(microscopeModel.currentDescription['choices'][index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
              alignment: FractionalOffset.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5), // Gray background with reduced opacity
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: descriptionBoard,
                    style: const TextStyle(
                      fontSize: 18.0, // Adjust font size as needed
                    ),
                  ),
                ),
              )

          )
        ]));
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
    );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;
  }

  Future<void> onRemoveEverything() async {
    /*nodes.forEach((node) {
      this.arObjectManager.removeNode(node);
    });*/
    for (var anchor in anchors) {
      arAnchorManager!.removeAnchor(anchor);
    }
    anchors = [];
  }


  Future<void> onNodeTapped(List<String> nodes) async {
    var number = nodes.length;
    arSessionManager!.onError("Tapped $number node(s)");
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
            (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
    if(singleHit == null) {
      singleHit = singleHitTestResult;
      _startTimer();
    }
  }

  void _startTimer() {
    // Timer logic
    List<String> _subtitleList = [];

    List<SceneNode> _sceneNodes = [
      SceneNode(modelPath: "assets/bot/scene.gltf", position: vector.Vector3(0.2, 0.2, 0.030), scale: vector.Vector3(0.3, 0.3, 0.3),
          subtitle: [
            "Let's delve into the fascinating world of microscopes, class!",
            "These incredible instruments allow us to explore the tiniest of details.",
            "Think of them as our window into the microscopic realm!",
            "From studying cells to analyzing materials, microscopes are indispensable tools.",
            "Shall we embark on this exciting journey together, exploring the wonders of microscopy?"
          ],
          subtitleDuration: [4, 5, 5, 7, 5]),
      SceneNode(modelPath: "assets/bot/scene.gltf", position: vector.Vector3(-0.2, 0.2, 0.030), scale: vector.Vector3(0.3, 0.3, 0.3),
          subtitle: [
            "Alright, let's break it down a bit further, shall we?",
            "Microscopes come in various types, each serving specific purposes.",
            "These tools allow us to magnify objects hundreds, thousands, or even millions of times.",
            "With microscopes, we can observe the intricate structures of cells, bacteria, and even atoms!",
            "Now, let's explore the fascinating parts of microscopes together!"
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/base/base.gltf", position: vector.Vector3(0, -0.01,  0.023), scale: vector.Vector3(1, 1, 1),
          subtitle: [
            "The microscope's base provides stability and support, crucial for accurate observations.",
            "Made of durable materials like metal or plastic, it ensures steady operation.",
            "Rubberized feet prevent slipping, safeguarding surfaces during microscopy.",
            "Storage compartments may be included for convenient accessory organization.",
            "In essence, the base is essential for stability and precision in microscopy."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/arm/arm.gltf", position: vector.Vector3(0, 0, 0), scale: vector.Vector3(1, 1, 1),
          subtitle:[
            "The arm connects the base to the head, facilitating adjustments.",
            "Usually made of metal, it provides structural support to the microscope.",
            "Its ergonomic design allows for comfortable handling during use.",
            "Some arms feature built-in focusing mechanisms for enhanced precision.",
            "Overall, the arm plays a crucial role in maneuverability and stability."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/focusknob/focusknob.gltf", position: vector.Vector3(-0.034, 0.03, -0.02), scale: vector.Vector3(.8, .8, .8),
          subtitle: [
            "The focus knob adjusts the sharpness and clarity of the image.",
            "Typically located on the arm, it's easily accessible during microscopy.",
            "Rotating the knob moves the objective lenses to achieve focus.",
            "Precision in focusing is essential for detailed observation and analysis.",
            "Ultimately, the focus knob facilitates fine adjustments for optimal clarity."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/condenser/condenser.gltf", position: vector.Vector3(0.0, 0.09, 0.03), scale: vector.Vector3(1, 1, 1),
          subtitle: [
            "The condenser focuses light onto the specimen for better visibility.",
            "Positioned beneath the stage, it regulates the intensity and angle of illumination.",
            "Adjusting the condenser enhances contrast and resolution of the specimen.",
            "Its aperture diaphragm controls the amount of light passing through.",
            "Overall, the condenser optimizes illumination for clearer microscopy."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/tray/tray.gltf", position: vector.Vector3(-0.01, 0.12, 0.030), scale: vector.Vector3(1, 0.7, 0.84),
          subtitle: [
            "The tray, often located beneath the stage, holds slides or specimens.",
            "It provides a stable platform for examining samples under the microscope.",
            "Various tray designs accommodate different sizes and types of specimens.",
            "Some trays feature mechanical stages for precise specimen positioning.",
            "In microscopy, the tray is essential for secure and organized sample observation."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/slideholder/slideholder.gltf", position: vector.Vector3(0, 0.125, 0.018), scale: vector.Vector3(0.88, 0.7, 0.84),
          subtitle:  [
            "The slide holder secures slides in place for examination under the microscope.",
            "Typically located on the stage, it ensures stability during observation.",
            "Different slide holder designs accommodate various sizes and types of slides.",
            "Securely holding slides allows for precise and consistent viewing.",
            "Ultimately, the slide holder is integral for efficient and accurate microscopy."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/disk/disk.gltf", position: vector.Vector3(0.0, 0.175, 0.034), scale: vector.Vector3(1, 1, 1),
          subtitle: [
            "The disk, often situated within the microscope, regulates light intensity.",
            "It may contain filters or diaphragms to control illumination.",
            "Rotating the disk adjusts brightness or alters the light wavelength.",
            "Precise disk manipulation enhances contrast and visibility of specimens.",
            "Overall, the disk contributes to optimized lighting conditions for microscopy."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/4x/4x.gltf", position: vector.Vector3(0.0001, 0.145, 0.022), scale: vector.Vector3(0.45, 0.6, 0.6),
          subtitle:  [
            "The 4x objective lens provides low magnification for initial observation.",
            "With a magnification power of 4 times, it offers a wide field of view.",
            "Ideal for scanning specimens quickly, it aids in sample location.",
            "Higher magnification objectives are often used for detailed examination.",
            "In microscopy, the 4x lens is fundamental for initial specimen overview."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/8x/8x.gltf", position: vector.Vector3(-0.01, 0.146, 0.038), scale: vector.Vector3(0.62, 0.7, 0.6),
          subtitle: [
            "The 8x objective lens offers moderate magnification for detailed observation.",
            "With a magnification power of 8 times, it provides enhanced clarity.",
            "Suitable for examining larger structures while maintaining a wider field of view.",
            "Higher magnification objectives further amplify specimen details.",
            "In microscopy, the 8x lens balances magnification and field of view for thorough analysis."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/40x/40x.gltf", position: vector.Vector3(0.0, 0.14, 0.045), scale: vector.Vector3(0.7, 0.9, 0.6),
          subtitle: [
            "The 40x objective lens provides high magnification for fine details.",
            "With a magnification power of 40 times, it offers exceptional clarity.",
            "Ideal for observing cellular structures and minute features.",
            "Requires immersion oil for optimal performance and resolution.",
            "In microscopy, the 40x lens enables detailed examination at a higher magnification."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/100x/100x.gltf", position: vector.Vector3(0.015, 0.15, 0.038), scale: vector.Vector3(0.7, 0.7, 0.6),
          subtitle:  [
            "The 100x objective lens offers the highest magnification for fine resolution.",
            "With a magnification power of 100 times, it reveals intricate details.",
            "Commonly used with oil immersion technique for increased clarity.",
            "Ideal for observing microscopic structures with utmost precision.",
            "In microscopy, the 100x lens is essential for detailed examination at maximum magnification."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/lamp/lamp.gltf", position: vector.Vector3(0.0, 0.024, 0.03), scale: vector.Vector3(0.8, 0.8, 0.8),
          subtitle:  [
            "The lamp provides illumination for observing specimens under the microscope.",
            "Positioned beneath or within the microscope, it directs light upwards.",
            "Different types of lamps, such as halogen or LED, offer varying intensities.",
            "Adjusting the lamp brightness optimizes visibility and contrast of specimens.",
            "Overall, the lamp ensures adequate lighting conditions for microscopy."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath: "assets/lens/lens.gltf", position: vector.Vector3(0.0, 0.02, 0.07), scale: vector.Vector3(0.8, 0.8, 0.8),
          subtitle: [
            "The ocular lens, also known as the eyepiece, magnifies the specimen image.",
            "Located at the top of the microscope, it's closest to the viewer's eye.",
            "Typically with a magnification of 10x, it enhances the image produced by the objective lens.",
            "Quality ocular lenses ensure clear and accurate visualization.",
            "In microscopy, the ocular lens contributes to the overall magnification and clarity of the specimen."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
      SceneNode(modelPath:"assets/microscpe/microscope.gltf", position:vector.Vector3(0.015, -0.01, 0.048), scale:vector.Vector3(1, 1, 1),
          subtitle: [
            "Understanding the parts of a microscope is crucial for its effective use in scientific exploration.",
            "Each component plays a vital role in magnifying and illuminating specimens for observation.",
            "From the base to the lenses, every part contributes to the clarity and precision of microscopy.",
            "Mastering these components empowers scientists to unlock the mysteries of the microscopic world.",
            "Now that we've covered the essentials, it's time to put our knowledge into practice."
          ],
          subtitleDuration: [3, 3, 7, 8, 6]),
    ];
    int _currentIndex = 0; // Index for subtitle rotation
    bool isPlayed = false;
    if (_subtitleList.isEmpty) {
      // Assign subtitles from the SceneNode at objectBoardIndex to _subtitleList
      _subtitleList.addAll(_sceneNodes[objectBoardIndex].subtitle);
    }
    if (nodes.isEmpty) {
      addNodeToAnchor(_sceneNodes[0]); // Add the first node to the AR scene
    }

    // _timer = Timer.periodic(Duration(seconds: _sceneNodes[objectBoardIndex].subtitleDuration[_currentIndex]), (timer) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // if (objectBoardIndex == 15) {
      //   _timer?.cancel();
      // }
      // if (timer.tick == 5) { // After 10 seconds (5 ticks)

      if (_currentIndex == 5) {
        if (objectBoardIndex == 0 || objectBoardIndex == 1 || objectBoardIndex == 14) {
          for (var anchor in anchors) {
            arAnchorManager!.removeAnchor(anchor);
          }
          anchors = [];
        }
        if (objectBoardIndex + 1 != 16){
          objectBoardIndex = objectBoardIndex + 1;
        }

        addNodeToAnchor(_sceneNodes[objectBoardIndex]);

        _currentIndex = 0;
        _subtitleList.clear();
      }
      if (_subtitleList.isNotEmpty) {
        changeText(_subtitleList[_currentIndex]);
        _currentIndex = _currentIndex + 1;
      }
      _subtitleList.addAll(_sceneNodes[objectBoardIndex].subtitle);

      // if (!isPlayed) {
      //   // Player.play('audio/storyboard1.wav');
      //   isPlayed = true;
      // }

    });
  }
  void handleTimeout() {

    _timer?.cancel(); // Cancel the timer if needed
  }
  Future<void> addNodeToAnchor(SceneNode) async {
    var singleHitTestResult = singleHit;
    var newAnchor =
    ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);
    if (didAddAnchor!) {
      anchors.add(newAnchor);
      // Add note to anchor
      var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: SceneNode.modelPath,
          scale: SceneNode.scale,
          position: SceneNode.position,
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0));
      bool? didAddNodeToAnchor =
      await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
      if (didAddNodeToAnchor!) {
        nodes.add(newNode);
      } else {
        arSessionManager!.onError("Adding Node to Anchor failed");
      }
    } else {
      arSessionManager!.onError("Adding Anchor failed");
    }
  }

}
class SceneNode {
  final String modelPath; // Path to the 3D model
  final vector.Vector3 position; // Position of the model in 3D space
  final vector.Vector3 scale; // Scale of the model
  // final int duration;
  final List<String> subtitle;
  final List<int> subtitleDuration;
  const SceneNode({
    required this.modelPath,
    required this.position,
    required this.scale,
    // required this.duration
    required this.subtitle,
    required this.subtitleDuration,
  });
}
class Player {
  static play(String src) async {
    final player = AudioPlayer();
    await player.play(AssetSource(src));
  }
}

class ChoiceButton extends StatelessWidget {
  final String choice;
  final Function onPressed;

  ChoiceButton({super.key, required this.choice, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: ElevatedButton(
        onPressed: onPressed as void Function()?,
        child: Text(choice),
      ),
    );
  }
}
