//
//  ViewController.swift
//  ARDemo
//
//  Created by Stephen Brown on 3/4/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var player = AVPlayer()
    var videoScene: SKScene!
    var videoView: SKView!
    var videoNode: SKVideoNode!
    var url: String!
    var vtime:Int64 = 0
    var resourceGroup: String = "AR Resources Sneakertopia"
    let playerLayer = AVPlayerLayer()
    let rootLayer = CALayer()
    var museumItems = [String: MuseumItem]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        sceneView.delegate = self
        let defaults = UserDefaults.standard
        let fileName = defaults.string(forKey: "Showing") ?? "Error"
        resourceGroup = "AR Resources " + fileName
        print("file \(fileName) resource group \(resourceGroup)")
        loadData(fileName)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        
        // first see if there is a folder called "ARImages" Resource Group in our Assets Folder
        if let trackedImages = ARReferenceImage.referenceImages(inGroupNamed: resourceGroup, bundle: Bundle.main) {
            
            // if there is, set the images to track
            configuration.trackingImages = trackedImages
            // at any point in time, only 1 image will be tracked
            configuration.maximumNumberOfTrackedImages = 1
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    

    
    func loadData(_ fileName: String) {
        guard let url  = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            fatalError("Unable to find JSON bundle")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Unable to load JSON")
        }
        let decoder = JSONDecoder()
        
        guard let loadedMuseumItems = try? decoder.decode([String: MuseumItem].self, from: data) else {
            fatalError("Unable to parse JSON")
        }
        museumItems = loadedMuseumItems
    }
    

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
  
        guard let imageAnchor = anchor as? ARImageAnchor,
              let name = imageAnchor.referenceImage.name,
              let museumItem  = museumItems[name],
              let fileUrlString = Bundle.main.path(forResource: museumItem.videofile, ofType: "mp4")
              else {return}

        vtime = Int64(museumItem.videostart)
        url = fileUrlString
        
        let videoItem = AVPlayerItem(url: URL(fileURLWithPath: fileUrlString))
        
        player.replaceCurrentItem(with: videoItem)
        
        videoNode = SKVideoNode(avPlayer: player)

        let time = CMTime(value: vtime, timescale: 1)
        player.seek(to: time)
        player.play()

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: nil) { (notification) in
            self.player.seek(to: CMTime.zero)
            self.player.play()

        }
        
        let awidth = 960
        let aheight = 540
        
        videoScene = SKScene(size: CGSize(width: awidth, height: aheight))
        videoScene.scaleMode = .aspectFill
        videoNode.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
        videoNode.yScale = -1.0
        videoScene.addChild(videoNode)
      
        // create a plan that has the same real world height and width as our detected image
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        // set the first materials content to be our video scene
        plane.firstMaterial?.diffuse.contents = videoScene
        // create a node out of the plane
        let planeNode = SCNNode(geometry: plane)
        // since the created node will be vertical, rotate it along the x axis to have it be horizontal or parallel to our detected image
        planeNode.eulerAngles.x = -Float.pi / 2
        // finally add the plane node (which contains the video node) to the added node
        node.addChildNode(planeNode)

        let spacing: Float = 0.005
        
        let titleNode = textNode(museumItem.title, font: UIFont.boldSystemFont(ofSize: 10))
        titleNode.pivotOnTopLeft()
        
        titleNode.position.x += Float(plane.width / 2) + spacing
        titleNode.position.y += Float(plane.height / 2)
        
        planeNode.addChildNode(titleNode)

        let bioNode = textNode(museumItem.description, font: UIFont.systemFont(ofSize: 4), maxWidth: 100)
        bioNode.pivotOnTopLeft()
        
        bioNode.position.x += Float(plane.width / 2) + spacing
        bioNode.position.y = titleNode.position.y - titleNode.height - spacing
        planeNode.addChildNode(bioNode)

    }


    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        if node.isHidden == true {
            if let imageAnchor = anchor as? ARImageAnchor {
                sceneView.session.remove(anchor: imageAnchor)
                player.pause()
            }
        } else {
            player.play()
        }
    }
    

    func textNode(_ str: String, font: UIFont, maxWidth: Int? = nil) -> SCNNode {
        let text = SCNText(string: str, extrusionDepth: 0)
        
        text.flatness = 0.1
        text.font = font
        
        if let maxWidth = maxWidth  {
            text.containerFrame = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: 500))
            text.isWrapped = true
        }
        
        let textNode = SCNNode(geometry: text)
        textNode.scale  = SCNVector3Make(0.002, 0.002, 0.002)
        
        return textNode
    }
}


extension SCNNode {
    var width: Float {
        return(boundingBox.max.x -  boundingBox.min.x) * scale.x
    }
    
    var height: Float {
        return(boundingBox.max.y -  boundingBox.min.y) * scale.y
    }
    
    func pivotOnTopLeft() {
        let (min, max) = boundingBox
        pivot  = SCNMatrix4MakeTranslation(min.x, (max.y - min.y) + min.y, 0)
    }
    
    func pivotOnTopCenter() {
        let (min, max) = boundingBox
        pivot  = SCNMatrix4MakeTranslation((max.x - min.x) / 2 + min.x, (max.y - min.y) + min.y, 0)
    }
}
