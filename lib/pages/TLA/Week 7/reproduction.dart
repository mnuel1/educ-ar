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
import 'package:microscope_ar/classes/change_notifier.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UpdateNotify("assets/lesson7/lesson7Subitles/TLA/subtitle.json"),
      child: const ModuleScreen(),
    ),
  );
}

class ModuleScreen extends StatefulWidget  {
  const ModuleScreen({super.key});

  _ModuleScreenPage createState() => _ModuleScreenPage();
}

class _ModuleScreenPage extends State<ModuleScreen> {

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  var singleHit = null;
  int objectBoardIndex = 1;
  List<SceneNode> sceneNodes = [
    SceneNode(name:"", modelPath:"assets/bot/scene.gltf", position: vector.Vector3(0.2, 0.5, 0.2), scale: vector.Vector3(0.3, 0.3, 0.3)),
    SceneNode(name:"", modelPath:"assets/lesson7/assets/propo.gltf", position:vector.Vector3(0, 0, 0), scale:vector.Vector3(.1, .1, .1)),
    SceneNode(name:"", modelPath:"assets/lesson7/assets/runners.gltf", position:vector.Vector3(0, 0, 0), scale:vector.Vector3(.1, .1, .1)),
    SceneNode(name:"", modelPath:"assets/lesson7/assets/budding.gltf", position:vector.Vector3(0, 0, 0), scale:vector.Vector3(.1, .1, .1)),
    SceneNode(name:"", modelPath:"assets/lesson7/assets/fission.gltf", position:vector.Vector3(0, 0, 0), scale:vector.Vector3(.1, .1, .1)),
    SceneNode(name:"", modelPath:"assets/lesson7/assets/poli.gltf", position:vector.Vector3(0, 0, 0), scale:vector.Vector3(.1, .1, .1)),
    SceneNode(name:"", modelPath:"assets/lesson7/assets/mating.gltf", position:vector.Vector3(0, 0, 0), scale:vector.Vector3(.1, .1, .1)),

  ];

  late UpdateNotify updateNotify;
  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }
  @override
  Widget build(BuildContext context) {
    updateNotify = Provider.of<UpdateNotify>(context);
    updateNotify.onDescriptionChange = () {
      // print(objectBoardIndex);
      if (objectBoardIndex == 1) {
        addNodeToAnchor(sceneNodes[0]);
      }
      if (objectBoardIndex == 4) {
        addNodeToAnchor(sceneNodes[1]);

      }
      if (objectBoardIndex == 13) {
        for (var anchor in anchors) {
          arAnchorManager!.removeAnchor(anchor);
        }
        anchors = [];
        addNodeToAnchor(sceneNodes[2]);
      }
      if (objectBoardIndex == 15) {
        for (var anchor in anchors) {
          arAnchorManager!.removeAnchor(anchor);
        }

        anchors = [];
        addNodeToAnchor(sceneNodes[3]);
      }
      if (objectBoardIndex == 17) {
        for (var anchor in anchors) {
          arAnchorManager!.removeAnchor(anchor);
        }
        anchors = [];

        addNodeToAnchor(sceneNodes[4]);
      }
      if (objectBoardIndex == 21) {
        for (var anchor in anchors) {
          arAnchorManager!.removeAnchor(anchor);
        }
        anchors = [];

        addNodeToAnchor(sceneNodes[5]);
      }
      if (objectBoardIndex == 33) {
        for (var anchor in anchors) {
          arAnchorManager!.removeAnchor(anchor);
        }
        anchors = [];

        addNodeToAnchor(sceneNodes[6]);
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
                  if (updateNotify.currentDescription[1].length != 0)
                    Column(
                      children: List.generate(
                        updateNotify.currentDescription[1].length,
                            (index) => ChoiceButton(
                          choice: updateNotify.currentDescription[1][index],
                          onPressed: () {
                            updateNotify.chooseAnswer(updateNotify.currentDescription[1][index]);
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
                  updateNotify.currentDescription[0] ?? '',
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
      updateNotify.startTimer();
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
          rotation: vector.Vector4(1, 0, 0, 0.0));
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



