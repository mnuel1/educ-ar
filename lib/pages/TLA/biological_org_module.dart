import 'dart:async';
import 'dart:convert';
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
// import 'dart:developer' as developer;

import 'package:microscope_ar/components/choice_button.dart';
import 'package:microscope_ar/classes/scenenode.dart';
import 'package:microscope_ar/classes/audio_player.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MicroscopeModel(),
      child: const MicroscopeModuleScreen(),
    ),
  );
}

class MicroscopeModuleScreen extends StatefulWidget  {
  const MicroscopeModuleScreen({super.key});

  _MicroscopeModulePage createState() => _MicroscopeModulePage();
}

class MicroscopeModel extends ChangeNotifier {
  List<List<dynamic>> _descriptions = []; // Modified to allow changes
  int _currentDescriptionIndex = 0;
  List<dynamic> get currentDescription => _descriptions[_currentDescriptionIndex];
  bool _answerChosen = false;
  bool isPlayed = false;
  Timer? _timer;


  Function? onDescriptionChange;

  MicroscopeModel() {
    _loadDescriptions(); // Load descriptions from JSON file
    // _startTimer();
  }


  void _startTimer() {

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentDescriptionIndex < _descriptions.length - 1) {
        if ([4, 9, 12, 16, 17, 18, 22, 23, 24].contains(_currentDescriptionIndex) && _answerChosen ||
            ![4, 9, 12, 16, 17, 18, 22, 23, 24].contains(_currentDescriptionIndex) && !_answerChosen) {
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
      if (answer == currentDescription[2]) {
        _answerChosen = true;
      }
    }
  }

  void nextDescription() {
    if (_currentDescriptionIndex < _descriptions.length - 1) {
      _currentDescriptionIndex++;
      _answerChosen = false; // Reset answer chosen flag
      notifyListeners();
      if (onDescriptionChange != null) {
        onDescriptionChange!();
      }
    } else {
      _timer?.cancel();
    }
  }

  void _loadDescriptions() async {
    try {
      String data = await rootBundle.loadString('assets/scripts/week3Script.json');
      List<dynamic> jsonList = json.decode(data);
      _descriptions = jsonList.map((jsonItem) {
        return [
          jsonItem['description'] as String,
          (jsonItem['choices'] as List),
          jsonItem['answer'], // Keep it dynamic since the type may vary
        ];
      }).toList();
      notifyListeners(); // Notify listeners after descriptions are loaded
    } catch (e) {
      print('Error loading descriptions: $e');
    }
  }
}

class _MicroscopeModulePage extends State<MicroscopeModuleScreen> {

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  var singleHit = null;
  int objectBoardIndex = 1;
  List<SceneNode> sceneNodes = [
    SceneNode(modelPath: "assets/bot/scene.gltf", position: vector.Vector3(0.2, 0.4, 0.030), scale: vector.Vector3(0.3, 0.3, 0.3)),
    SceneNode(modelPath:"assets/org/org.gltf", position:vector.Vector3(0.015, -0.01, 0.048), scale:vector.Vector3(.2, .2, .2)),
  ];

  late MicroscopeModel microscopeModel;
  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }
  @override
  Widget build(BuildContext context) {
    microscopeModel = Provider.of<MicroscopeModel>(context);
    microscopeModel.onDescriptionChange = () {
      // print(objectBoardIndex);
      if (objectBoardIndex == 1) {
        addNodeToAnchor(sceneNodes[0]);
      addNodeToAnchor(sceneNodes[1]);
      }
      objectBoardIndex++;

      //  // Call addNodeToAnchor method whenever nextDescription is called
      //       if (objectBoardIndex == 0 || objectBoardIndex == 1 || objectBoardIndex == 14) {
      //         for (var anchor in anchors) {
      //           arAnchorManager!.removeAnchor(anchor);
      //         }
      //         anchors = [];
    };

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ARView(
              onARViewCreated: onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (microscopeModel.currentDescription[1].length != 0)
                    Column(
                      children: List.generate(
                        microscopeModel.currentDescription[1].length,
                            (index) => ChoiceButton(
                          choice: microscopeModel.currentDescription[1][index],
                          onPressed: () {
                            microscopeModel.chooseAnswer(microscopeModel.currentDescription[1][index]);
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
                  color: Colors.grey.withOpacity(0.5),
                ),
                child: Text(
                  microscopeModel.currentDescription[0] ?? '',
                  style: const TextStyle(fontSize: 20.0),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          ],
        ),
      ),
    );

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

  Future<void> onNodeTapped(List<String> nodes) async {
    var number = nodes.length;
    arSessionManager!.onError("Tapped $number node(s)");
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstWhere(
            (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
    if (singleHit == null) {
      singleHit = singleHitTestResult;
      microscopeModel._startTimer();
    }
  }

  Future<void> addNodeToAnchor(SceneNode sceneNode) async {
    var singleHitTestResult = singleHit;
    var newAnchor =
    ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);
    if (didAddAnchor!) {
      anchors.add(newAnchor);
      // Add note to anchor
      var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: sceneNode.modelPath,
          scale: sceneNode.scale,
          position: sceneNode.position,
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



