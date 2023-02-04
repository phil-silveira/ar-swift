//
//  ViewController.swift
//  DiceAR
//
//  Created by Philippe Silveira on 03/02/23.
//

import UIKit
import SceneKit
import ARKit

class DicesViewController: UIViewController, ARSCNViewDelegate {
    var dices = [SCNNode]()

    @IBOutlet var sceneView: ARSCNView!
    @IBAction func onRefreshPressed(_ sender: UIBarButtonItem) {
        rollAllDices()
    }
    @IBAction func onCleanPressed(_ sender: UIBarButtonItem) {
        if dices.isEmpty { return }
        
        for dice in dices {
            dice.removeFromParentNode()
        }
        dices = []
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAllDices()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        
//        // Useful debuging tools
//        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//        // Enable debug mode (show feature points)
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Add lighting effect to 3d models
        sceneView.autoenablesDefaultLighting = true
    }
//        // Create a 3d cube
//        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
//        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.red
//        cube.materials = [material]
        
//        // Create a 3d sphere that looks like earth
//        let sphere = SCNSphere(radius: 0.2)
//        let material = SCNMaterial()
//        material.diffuse.contents = UIImage(named: "art.scnassets/earth-8k-texture.jpg")
//        sphere.materials = [material]
//        let node = SCNNode()
//        node.position = SCNVector3(0, 0.1, -0.5)
//        node.geometry = sphere
        
//        // Import a 3d model from .dea files
//        let diceScene = SCNScene(named: "art.scnassets/dice.scn")!
//
//        let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true)
//        diceNode?.position = SCNVector3(x: 0, y: 0, z: -0.1)
//
//        guard let dice = diceNode else { return }
//        sceneView.scene.rootNode.addChildNode(sphere)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            let results = sceneView.hitTest(touchLocation, types: .existingPlane)
            
            if let plane = results.first {
                let diceScene = SCNScene(named: "art.scnassets/dice.scn")!
                
                guard let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) else {return}
                
                diceNode.position = SCNVector3(
                    x: plane.worldTransform.columns.3.x,
                    y: plane.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                    z: plane.worldTransform.columns.3.z
                )
       
                dices.append(diceNode)
                
                sceneView.scene.rootNode.addChildNode(diceNode)
                
                rollDice(diceNode)
            }
        }
    }
    
    func addNewDice(atLocation location: ARHitTestResult) {
        guard let diceScene = SCNScene(named: "art.scnassets/dice.scn") else { return }
        guard let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) else {return}
        
        diceNode.position = SCNVector3(
            x: location.worldTransform.columns.3.x,
            y: location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
            z: location.worldTransform.columns.3.z
        )
        
        sceneView.scene.rootNode.addChildNode(diceNode)
        
        dices.append(diceNode)
        rollDice(diceNode)
    }
    
    func rollAllDices(){
        if dices.isEmpty { return }
        
        for dice in dices {
            rollDice(dice)
        }
    }
    
    func rollDice(_ dice: SCNNode) {
        let randX = CGFloat(Float(arc4random_uniform(4) + 1) * (Float.pi/2) * 5)
        let randZ = CGFloat(Float(arc4random_uniform(4) + 1) * (Float.pi/2) * 5)
        
        dice.runAction(
            SCNAction.rotateBy(
                x: randX,
                y: 0,
                z: randZ,
                duration: 0.5
            )
        )
    }

// MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        let planeNode = createPlane(withAnchor: planeAnchor)
        
        node.addChildNode(planeNode)
    }
    
    func createPlane(withAnchor planeAnchor: ARPlaneAnchor, withDebugGrid debugGrid: Bool = false) -> SCNNode {
        let plane = SCNPlane(
            width: CGFloat(planeAnchor.extent.x),
            height: CGFloat(planeAnchor.extent.z)
        )
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(
            planeAnchor.center.x,
            0,
            planeAnchor.center.z
        )
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        if debugGrid {
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
        }
        
        planeNode.geometry = plane
        planeNode.opacity = 0
        
        return planeNode
    }
}
