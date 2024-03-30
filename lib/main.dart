import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  runApp(const MaterialApp(
    home: ObjectsOnPlanesWidget(),
  ));
}
class ObjectsOnPlanesWidget extends StatefulWidget {
  const ObjectsOnPlanesWidget({super.key});
  @override
  _ObjectsOnPlanesWidgetState createState() => _ObjectsOnPlanesWidgetState();
}

class _ObjectsOnPlanesWidgetState extends State<ObjectsOnPlanesWidget> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];

  @override
  void dispose() {
    super.dispose();
    arSessionManager!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Anchors & Objects on Planes'),
        ),
        body: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: onRemoveEverything,
                      child: const Text("Remove Everything")),
                ]),
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
      showWorldOrigin: true,
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

      // addNodeToAnchor("assets/base/base.gltf", Vector3(0, 0, 0), Vector3(1, 1, 1), singleHitTestResult);
      addNodeToAnchor("assets/arm/arm.gltf", Vector3(0, 0, 0), Vector3(1, 1, 1),  singleHitTestResult);
      // addNodeToAnchor("assets/focusknob/focusknob.gltf", Vector3(-0.04, 0.02, -0.026), Vector3(1, 1, 1),  singleHitTestResult);
      // addNodeToAnchor("assets/condenser/condenser.gltf", Vector3(0.0, 0.097, 0.018), Vector3(1, 1, 1), singleHitTestResult);
      // addNodeToAnchor("assets/tray/tray.gltf", Vector3(-0.01, 0.132, 0.015), Vector3(0.7, 0.7, 0.9), singleHitTestResult);
      // addNodeToAnchor("assets/slideholder/slideholder.gltf", Vector3(0.0, 0.136, 0.01), Vector3(0.7, 0.7, 0.9), singleHitTestResult);
      // addNodeToAnchor("assets/disk/disk.gltf", Vector3(0.0, 0.175, 0.034), Vector3(1, 1, 1),  singleHitTestResult);
      // addNodeToAnchor("assets/4x/4x.gltf", Vector3(0.0, 0.16, 0.02), Vector3(0.6, 0.4, 0.6), singleHitTestResult);
      // addNodeToAnchor("assets/8x/8x.gltf", Vector3(-0.015, 0.16, 0.039), Vector3(0.6, 0.43, 0.6), singleHitTestResult);
      // addNodeToAnchor("assets/40x/40x.gltf", Vector3(0.0, 0.16, 0.055), Vector3(0.6, 0.46, 0.6), singleHitTestResult);
      // addNodeToAnchor("assets/100x/100x.gltf", Vector3(0.015, 0.16, 0.039), Vector3(0.6, 0.46, 0.6), singleHitTestResult);
      // addNodeToAnchor("assets/lamp/lamp.gltf", Vector3(0.0, 0.03, 0.018), Vector3(1, 1, 1), singleHitTestResult);
      // addNodeToAnchor("assets/knob/knob.gltf", Vector3(0.0, 0.03, 0.075), Vector3(0.3, 0.3, 0.3), singleHitTestResult);
      // addNodeToAnchor("assets/lens/lens.gltf", Vector3(0.0, -0.0184, 0.09), Vector3(1, 1, 1), singleHitTestResult);
      addNodeToAnchor("assets/microscpe/microscope.gltf", Vector3(0, -0.01, 0.023), Vector3(1.5, 1.5, 1.5),  singleHitTestResult);
    }


  Future<void> addNodeToAnchor(String uri, Vector3 position, Vector3 scale,
      singleHitTestResult) async {

    var newAnchor =
    ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager!.addAnchor(newAnchor);
    if (didAddAnchor!) {
      anchors.add(newAnchor);
      // Add note to anchor
      var newNode = ARNode(
          type: NodeType.localGLTF2,
          uri: uri,
          scale: scale,
          position: position,
          rotation: Vector4(1.0, 0.0, 0.0, 0.0));
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