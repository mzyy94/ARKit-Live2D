/**
 *
 * ViewController.swift
 * ARKit-Live2D
 * Created by Yuki MIZUNO on 2017/11/14.
 *
 * Copyright (c) 2017, Yuki MIZUNO
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

import ARKit
import GLKit
import SceneKit
import UIKit
import ReplayKit

class ViewController: GLKViewController {

    // MARK: - Properties
    let contentUpdater = ContentUpdater()
    let controller = RPBroadcastController()
    @IBOutlet var sceneView: ARSCNView!
    var session: ARSession {
        return sceneView.session
    }
    var live2DModel: Live2DModelOpenGL!
    var context: EAGLContext!
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = contentUpdater
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        self.context = EAGLContext(api: .openGLES2)
        if context == nil {
            print("Failed to create ES context")
            return
        }
        
        guard let view = self.view as? GLKView else {
            print("Failed to cast view to GLKView")
            return
        }
        view.context = self.context
        
        self.setupGL()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        resetTracking()
        
        if self.isViewLoaded && self.view.window == nil {
            self.view = nil
            self.tearDownGL()
            
            if EAGLContext.current() == self.context {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        session.pause()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Memory Management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Utility
    func errorString(_ error: Error) -> String {
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        return errorMessage
    }
    
    // MARK: - Instance Life Cycle

    deinit {
        self.tearDownGL()
        if EAGLContext.current() == self.context {
            EAGLContext.setCurrent(nil)
        }
        self.context = nil
    }
    
    // MARK: - Gesture action

    @IBAction func tapInfoButton() {
        let liveBroadcast = UIAlertAction(title: controller.isBroadcasting ? "Stop Broadcast" : "Live Broadcast", style: .default, handler: { action in
            if self.controller.isBroadcasting {
                self.stopBroadcast()
            } else {
                self.startBroadcast()
            }
        })
        
        let toggleSceneView = UIAlertAction(title: sceneView.isHidden ? "Show Front View" : "Hide Front View", style: .default, handler: { action in
            self.sceneView.isHidden = !self.sceneView.isHidden
        })
        
        let actionSheet = UIAlertController(title: "Option", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(liveBroadcast)
        actionSheet.addAction(toggleSceneView)

        actionSheet.addAction(UIAlertAction(title: "Cacnel", style: .cancel, handler: nil))
        
        self.show(actionSheet, sender: self)
    }
    
    // MARK: - ReplayKit Live broadcasting
    
    func startBroadcast() {
        RPScreenRecorder.shared().isMicrophoneEnabled = true // Not work?
        RPBroadcastActivityViewController.load { broadcastAVC, error in
            if error != nil {
                print("Load BroadcastActivityViewController failed. ::" + self.errorString(error!))
                return
            }
            if let broadcastAVC = broadcastAVC {
                broadcastAVC.delegate = self
                self.present(broadcastAVC, animated: true, completion: nil)
            }
        }
    }
    
    func stopBroadcast() {
        controller.finishBroadcast { error in
            if error != nil {
                print("Finish broadcast failed. ::" + self.errorString(error!))
                return
            }
        }
    }

    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Live2D OpenGL setup

    func setupGL() {
        EAGLContext.setCurrent(self.context)
        
        Live2DCubism.initL2D()
        
        let modelFile = "hiyori_pro_t08"
        let textures = ["texture_00", "texture_01"]
        
        guard let modelPath = Bundle.main.path(forResource: modelFile, ofType: "moc3") else {
            print("Failed to find model file")
            return
        }
        
        live2DModel = Live2DModelOpenGL(modelPath: modelPath)
        contentUpdater.live2DModel = live2DModel
        
        for (index, texture) in textures.enumerated() {
            let filePath = Bundle.main.path(forResource: texture, ofType: "png")!
            let textureInfo = try! GLKTextureLoader.texture(withContentsOfFile: filePath, options: [GLKTextureLoaderApplyPremultiplication: false, GLKTextureLoaderGenerateMipmaps: true])
            
            let num = textureInfo.name
            live2DModel?.setTexture(Int32(index), to: num)
        }
        
        live2DModel?.setPremultipliedAlpha(true);
    }
    
    func tearDownGL() {
        live2DModel = nil
        Live2DCubism.dispose()
        EAGLContext.setCurrent(self.context)
    }
    
    // MARK: - GLKViewDelegate
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        let size = UIScreen.main.bounds.size
        
        let scx: Float = (Float)(3.6 / live2DModel.getCanvasWidth())
        let scy: Float = (Float)(3.6 / live2DModel.getCanvasWidth() * (Float)(size.width/size.height))
        let x: Float = 0
        let y: Float = -0.5
        
        let matrix4 = SCNMatrix4(
            m11: scx, m12: 0,   m13: 0, m14: 0,
            m21: 0,   m22: scy, m23: 0, m24: 0,
            m31: 0,   m32: 0,   m33: 1, m34: 0,
            m41: x,   m42: y,   m43: 0, m44: 1)
        live2DModel.setMatrix(matrix4)
        
        let t = UtSystem.getUserTimeMSec() / 1000.0
        
        live2DModel.setParam("ParamBodyAngleZ", value: Float32(10.0 * sin(t)))
        live2DModel.setParam("ParamHairFront", value: Float32(sin(t)))
        live2DModel.setParam("ParamHairBack", value: Float32(sin(t)))
        live2DModel.setParam("ParamBreath", value: Float32((cos(t) + 1.0) / 2.0))
        live2DModel.setPartsOpacity("PartArmB", opacity: 0) // hide alternative position arm

        live2DModel.update()
        live2DModel.draw()
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            print("The AR session failed. ::" + errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.resetTracking()
        }
    }
}

// MARK: - RPBroadcastActivityViewControllerDelegate

extension ViewController: RPBroadcastActivityViewControllerDelegate {
    func broadcastActivityViewController(_ broadcastActivityViewController: RPBroadcastActivityViewController, didFinishWith broadcastController: RPBroadcastController?, error: Error?) {
        if error != nil {
            broadcastActivityViewController.dismiss(animated: false, completion: nil)
            print("Set broadcast controller failed. ::" + self.errorString(error!))
            return
        }
        
        broadcastActivityViewController.dismiss(animated: true) {
            broadcastController?.startBroadcast { error in
                if error != nil {
                    print("Start broadcast failed. ::" + self.errorString(error!))
                    return
                }
            }
        }
    }
}

