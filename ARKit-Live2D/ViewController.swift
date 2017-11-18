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

class ViewController: GLKViewController {

    // MARK: - Properties
    let contentUpdater = ContentUpdater()
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
        
        let touchUp = UITapGestureRecognizer(target: self, action: #selector(ViewController.toggleSceneView))
        view.addGestureRecognizer(touchUp)
        
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

    // MARK: - Instance Life Cycle

    deinit {
        self.tearDownGL()
        if EAGLContext.current() == self.context {
            EAGLContext.setCurrent(nil)
        }
        self.context = nil
    }
    
    // MARK: - Gesture action
    
    @objc func toggleSceneView() {
        self.sceneView.isHidden = !self.sceneView.isHidden
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
        
        Live2D.initL2D()
        
        let modelFile = "haru"
        let textures = ["texture_00", "texture_01", "texture_02"]
        
        guard let modelPath = Bundle.main.path(forResource: modelFile, ofType: "moc") else {
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
    }
    
    func tearDownGL() {
        live2DModel = nil
        Live2D.dispose()
        EAGLContext.setCurrent(self.context)
    }
    
    // MARK: - GLKViewDelegate
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        let size = UIScreen.main.bounds.size
        
        let scx: Float = (Float)(5.6 / live2DModel.getCanvasWidth())
        let scy: Float = (Float)(-5.6 / live2DModel.getCanvasWidth() * (Float)(size.width/size.height))
        let x: Float = -2.8
        let y: Float = 1
        
        let matrix4 = SCNMatrix4(
            m11: scx, m12: 0,   m13: 0, m14: 0,
            m21: 0,   m22: scy, m23: 0, m24: 0,
            m31: 0,   m32: 0,   m33: 1, m34: 0,
            m41: x,   m42: y,   m43: 0, m44: 1)
        live2DModel.setMatrix(matrix4)
        
        let t = UtSystem.getUserTimeMSec() / 1000.0
        
        live2DModel.setParam("PARAM_BODY_ANGLE_Z", value: (CGFloat)(10.0 * sin(t)))
        live2DModel.setParam("PARAM_HAIR_FRONT", value: (CGFloat)(sin(t)))
        live2DModel.setParam("PARAM_HAIR_BACK", value: (CGFloat)(sin(t)))
        live2DModel.setParam("PARAM_BREATH", value: (CGFloat)((cos(t) + 1.0) / 2.0))
        live2DModel.setParam("PARAM_BUST_Y", value: (CGFloat)(cos(t)))
        live2DModel.setPartsOpacity("PARTS_01_ARM_L_A_001", opacity: 0) // hide default position armL
        live2DModel.setPartsOpacity("PARTS_01_ARM_R_A_001", opacity: 0) // hide default position armR

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
        let errorMessage = messages.flatMap({ $0 }).joined(separator: "\n")
        
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

