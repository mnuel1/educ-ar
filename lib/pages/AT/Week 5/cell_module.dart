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
      create: (context) => UpdateNotify("assets/lesson5/lesson5Subitles/AT/subtitle.json"),
      child: const MicroscopeModuleScreen(),
    ),
  );
}

class MicroscopeModuleScreen extends StatefulWidget  {
  const MicroscopeModuleScreen({super.key});

  _MicroscopeModulePage createState() => _MicroscopeModulePage();
}

class _MicroscopeModulePage extends State<MicroscopeModuleScreen> {

  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  List <Map<String, dynamic>> blocks = [];
  Map<String, dynamic> leftBlock = {};
  Map<String, dynamic> rightBlock = {};

  var singleHit = null;
  int objectBoardIndex = 1;
  List<SceneNode> sceneNodes = [
    SceneNode(name:"", modelPath:"assets/bot/scene.gltf", position: vector.Vector3(0.2, 0.5, 0.2), scale: vector.Vector3(0.3, 0.3, 0.3)),
    SceneNode(name:"repro", modelPath:"assets/lesson5/assets/blocks/repro.gltf", position:vector.Vector3(0.0, 0.0, 0.0), scale:vector.Vector3(.25, .25, .25)),
    SceneNode(name:"respo", modelPath:"assets/lesson5/assets/blocks/respo.gltf", position:vector.Vector3(0.0, 0.01, 0.0), scale:vector.Vector3(.25, .25, .25)),
    SceneNode(name:"photo", modelPath:"assets/lesson5/assets/blocks/photo.gltf", position:vector.Vector3(0.0, 0.02, 0.0), scale:vector.Vector3(.25, .25, .25)),
    SceneNode(name:"repro", modelPath:"assets/lesson5/assets/blocks/ansrepro.gltf", position:vector.Vector3(0.2, 0.0, 0.0), scale:vector.Vector3(.25, .25, .25)),
    SceneNode(name:"respo", modelPath:"assets/lesson5/assets/blocks/ansrepo.gltf", position:vector.Vector3(0.2, 0.01, 0.0), scale:vector.Vector3(.25, .25, .25)),
    SceneNode(name:"photo", modelPath:"assets/lesson5/assets/blocks/ansphoto.gltf", position:vector.Vector3(0.2, 0.02, 0.0), scale:vector.Vector3(.25, .25, .25)),
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
        addNodeToAnchor(sceneNodes[1]);
      }
      if (objectBoardIndex == 2) {
        addNodeToAnchor(sceneNodes[2]);
        addNodeToAnchor(sceneNodes[3]);
      }
      if (objectBoardIndex == 3) {
        addNodeToAnchor(sceneNodes[4]);
        addNodeToAnchor(sceneNodes[5]);
      }
      if (objectBoardIndex == 4) {
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

  Future<void> onNodeTapped(List<String> nodeNames) async {
    var foregroundNode = nodes.firstWhere((element) => element.name == nodeNames.first);

    var sceneNodeName = foregroundNode.data!["name"];

    if(anchors.isEmpty) {
      // Check if the block exists with the given name
      var existingBlockIndex = blocks.indexWhere((block) => block["name"] == sceneNodeName);

      if (existingBlockIndex != -1) {
        var block = blocks[existingBlockIndex];

        // Check if leftBlock is empty
        if (leftBlock.isEmpty) {
          leftBlock = block;
          blocks.removeAt(existingBlockIndex);
        } else {
          // If leftBlock is not empty, assign it to rightBlock
          rightBlock = block;

          // Check if both leftBlock and rightBlock have the same name
          if (leftBlock["name"] == rightBlock["name"]) {
            // Remove anchors associated with the blocks
            for (var anchor in anchors) {
              if (anchor.name == leftBlock["anchor"] || anchor.name == rightBlock["anchor"]) {
                arAnchorManager!.removeAnchor(anchor);
              }
            }
          } else {
            // If the names are not the same, prompt wrong answer
            arSessionManager!.onError("Wrong Match");
          }
        }
      } else {
        // If the block doesn't exist, prompt wrong answer
        arSessionManager!.onError("");
      }
    } else {
      arSessionManager!.onError("Good job you ace it! Now you learned our topic properly!");
    }
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
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
          data: {"name": sceneNode.name});
      bool? didAddNodeToAnchor =
      await arObjectManager!.addNode(newNode, planeAnchor: newAnchor);
      if (didAddNodeToAnchor!) {
        nodes.add(newNode);
        blocks.add({
          "name": sceneNode.name,
          "anchor": newAnchor.name,
        });
      } else {
        arSessionManager!.onError("Adding Node to Anchor failed");
      }
    } else {
      arSessionManager!.onError("Adding Anchor failed");
    }
  }

}



