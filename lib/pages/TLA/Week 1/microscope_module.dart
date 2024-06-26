import 'dart:async';
import 'dart:convert';
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

import 'package:microscope_ar/components/choice_button.dart';
import 'package:microscope_ar/classes/scenenode.dart';
import 'package:microscope_ar/classes/change_notifier.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UpdateNotify("assets/lesson1&2/lesson1Subtitles/TLA/subtitle.json"),
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
      SceneNode(name: "Bot", modelPath: "assets/bot/scene.gltf", position: vector.Vector3(0.2, 0.2, 0.030), scale: vector.Vector3(0.3, 0.3, 0.3)),
      SceneNode(name: "Base", modelPath: "assets/lesson1&2/assets/base/base.gltf", position: vector.Vector3(0, -0.01,  0.023), scale: vector.Vector3(1, 1, 1)),
      SceneNode(name: "Arm", modelPath: "assets/lesson1&2/assets/arm/arm.gltf", position: vector.Vector3(0, 0, 0), scale: vector.Vector3(1, 1, 1)),
      SceneNode(name: "Focus Knob", modelPath: "assets/lesson1&2/assets/focusknob/focusknob.gltf", position: vector.Vector3(-0.034, 0.03, -0.02), scale: vector.Vector3(.8, .8, .8)),
      SceneNode(name: "Condenser", modelPath: "assets/lesson1&2/assets/condenser/condenser.gltf", position: vector.Vector3(0.0, 0.09, 0.03), scale: vector.Vector3(1, 1, 1)),
      SceneNode(name: "Tray", modelPath: "assets/lesson1&2/assets/tray/tray.gltf", position: vector.Vector3(-0.01, 0.12, 0.030), scale: vector.Vector3(1, 0.7, 0.84)),
      SceneNode(name: "Slide Holder", modelPath: "assets/lesson1&2/assets/slideholder/slideholder.gltf", position: vector.Vector3(0, 0.125, 0.018), scale: vector.Vector3(0.88, 0.7, 0.84)),
      SceneNode(name: "Lamp", modelPath: "assets/lesson1&2/assets/lamp/lamp.gltf", position: vector.Vector3(0.0, 0.024, 0.03), scale: vector.Vector3(0.8, 0.8, 0.8)),
      SceneNode(name: "Disk", modelPath: "assets/lesson1&2/assets/disk/disk.gltf", position: vector.Vector3(0.0, 0.175, 0.034), scale: vector.Vector3(1, 1, 1)),
      SceneNode(name: "Objective Lens 4x", modelPath: "assets/lesson1&2/assets/lenses/4x/4x.gltf", position: vector.Vector3(0.0001, 0.145, 0.022), scale: vector.Vector3(0.45, 0.6, 0.6)),
      SceneNode(name: "Objective Lens 10x", modelPath: "assets/lesson1&2/assets/lenses/8x/8x.gltf", position: vector.Vector3(-0.01, 0.146, 0.038), scale: vector.Vector3(0.62, 0.7, 0.6)),
      SceneNode(name: "Objective Lens 40x", modelPath: "assets/lesson1&2/assets/lenses/40x/40x.gltf", position: vector.Vector3(0.0, 0.14, 0.045), scale: vector.Vector3(0.7, 0.9, 0.6)),
      SceneNode(name: "Objective Lens 100x", modelPath: "assets/lesson1&2/assets/lenses/100x/100x.gltf", position: vector.Vector3(0.015, 0.15, 0.038), scale: vector.Vector3(0.7, 0.7, 0.6)),
      SceneNode(name: "Ocular Lens", modelPath: "assets/lesson1&2/assets/lens/lens.gltf", position: vector.Vector3(0.0, 0.02, 0.07), scale: vector.Vector3(0.8, 0.8, 0.8)),
      // SceneNode(modelPath:"assets/microscpe/microscope.gltf", position:vector.Vector3(0.015, -0.01, 0.048), scale:vector.Vector3(1, 1, 1)),
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
      if (objectBoardIndex == 6) {
        addNodeToAnchor(sceneNodes[1]);
      }

      if (objectBoardIndex == 10) {
        addNodeToAnchor(sceneNodes[2]);
      }

      if (objectBoardIndex == 12) {
        addNodeToAnchor(sceneNodes[3]);
      }
      if (objectBoardIndex == 15) {
        addNodeToAnchor(sceneNodes[4]);
      }
      if (objectBoardIndex == 16) {
        addNodeToAnchor(sceneNodes[5]);
      }
      if (objectBoardIndex == 21) {
        addNodeToAnchor(sceneNodes[6]);
      }
      if (objectBoardIndex == 24) {
        addNodeToAnchor(sceneNodes[7]);
      }
      if (objectBoardIndex == 26) {
        addNodeToAnchor(sceneNodes[8]);
        addNodeToAnchor(sceneNodes[9]);
        addNodeToAnchor(sceneNodes[10]);
        addNodeToAnchor(sceneNodes[11]);
        addNodeToAnchor(sceneNodes[12]);
      }

      if (objectBoardIndex == 29) {
        addNodeToAnchor(sceneNodes[13]);
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
      showWorldOrigin: false,
    );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    var foregroundNode =
    nodes.firstWhere((element) => element.name == nodeNames.first);
    arSessionManager!.onError(foregroundNode.data!["name"]);
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
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
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
          data: {"name": sceneNode.name});
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



