/**
 *
 * ViewController.swift
 * ARKit-Live2D
 * Created by Yuki MIZUNO on 2017/11/14.
 *
 * Copyright (c) 2017, Yuki MIZUNO
 * All rights reserved.
 *
 * See LICENSE for license information
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

import ARKit
import GLKit
import ReplayKit
import SceneKit
import UIKit

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
    var lastFrame: TimeInterval = 0.0

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = contentUpdater
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true

        context = EAGLContext(api: .openGLES2)
        if context == nil {
            print("Failed to create ES context")
            return
        }

        guard let view = self.view as? GLKView else {
            print("Failed to cast view to GLKView")
            return
        }
        view.context = context

        setupGL()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIApplication.shared.isIdleTimerDisabled = true

        resetTracking()

        if isViewLoaded, view.window == nil {
            view = nil
            tearDownGL()

            if EAGLContext.current() == context {
                EAGLContext.setCurrent(nil)
            }
            context = nil
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }

    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .bottom
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
            errorWithInfo.localizedRecoverySuggestion,
        ]
        let errorMessage = messages.compactMap { $0 }.joined(separator: "\n")
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

    @IBAction func tapInfoButton(_ sender: UIButton) {
        let liveBroadcast = UIAlertAction(title: controller.isBroadcasting ? "Stop Broadcast" : "Live Broadcast", style: .default, handler: { _ in
            if self.controller.isBroadcasting {
                self.stopBroadcast()
            } else {
                self.startBroadcast()
            }
        })

        let toggleSceneView = UIAlertAction(title: sceneView.isHidden ? "Show Front View" : "Hide Front View", style: .default, handler: { _ in
            self.sceneView.isHidden = !self.sceneView.isHidden
        })

        let setting = UIAlertAction(title: "Setting", style: .default, handler: { _ in
            self.present(SettingController(), animated: true, completion: nil)
        })

        let actionSheet = UIAlertController(title: "Option", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(liveBroadcast)
        actionSheet.addAction(toggleSceneView)
        actionSheet.addAction(setting)

        actionSheet.addAction(UIAlertAction(title: "Cacnel", style: .cancel, handler: nil))

        actionSheet.popoverPresentationController?.sourceView = sender

        show(actionSheet, sender: self)
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
        EAGLContext.setCurrent(context)

        Live2DCubism.initL2D()

        let jsonFile = "hiyori_movie_pro_t01.model3"

        guard let jsonPath = Bundle.main.path(forResource: jsonFile, ofType: "json") else {
            print("Failed to find model json file")
            return
        }

        live2DModel = Live2DModelOpenGL(jsonPath: jsonPath)
        contentUpdater.live2DModel = live2DModel

        for index in 0 ..< live2DModel.getNumberOfTextures() {
            let fileName = live2DModel.getFileName(ofTexture: index)!
            let filePath = Bundle.main.path(forResource: fileName, ofType: nil)!
            let textureInfo = try! GLKTextureLoader.texture(withContentsOfFile: filePath, options: [GLKTextureLoaderApplyPremultiplication: false, GLKTextureLoaderGenerateMipmaps: true])

            let num = textureInfo.name
            live2DModel.setTexture(Int32(index), to: num)
        }

        live2DModel.setPremultipliedAlpha(true)

        setupSizeAndPosition()

        _ = updateFrame()
    }

    fileprivate func setupSizeAndPosition() {
        let size = UIScreen.main.bounds.size
        let defaults = UserDefaults.standard

        let zoom: Float = defaults.float(forKey: ZOOM)

        let scx: Float = (Float)(5.6 / live2DModel.getCanvasWidth()) * zoom
        let scy: Float = (Float)(5.6 / live2DModel.getCanvasWidth() * (Float)(size.width / size.height)) * zoom
        let x: Float = defaults.float(forKey: X_POS)
        let y: Float = defaults.float(forKey: Y_POS)

        let matrix4 = SCNMatrix4(
            m11: scx, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: scy, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: x, m42: y, m43: 0, m44: 1
        )
        live2DModel.setMatrix(matrix4)
    }

    func tearDownGL() {
        live2DModel = nil
        Live2DCubism.dispose()
        EAGLContext.setCurrent(context)
    }

    // MARK: - GLKViewDelegate

    override func glkView(_: GLKView, drawIn _: CGRect) {
        setupSizeAndPosition()

        var rgb: [Float] = [0.0, 0.0, 0.0]
        let defaults = UserDefaults.standard
        for i in 0 ... 2 {
            rgb[i] = defaults.float(forKey: colorKeys[i])
        }

        glClearColor(rgb[0], rgb[1], rgb[2], 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))

        let delta = updateFrame()
        live2DModel.updatePhysics(Float(delta))

        live2DModel.setParam("ParamBreath", value: Float32((cos(lastFrame) + 1.0) / 2.0))

        live2DModel.update()
        live2DModel.draw()
    }

    // MARK: - Frame Update

    func updateFrame() -> TimeInterval {
        let now = Date().timeIntervalSince1970
        let deltaTime = now - lastFrame
        lastFrame = now
        return deltaTime
    }

    // MARK: - Device orientation

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let isLandscape = size.width / size.height > 1

        let scale: Float = isLandscape ? 2.6 : 5.6
        let scx: Float = (Float)(scale / live2DModel.getCanvasWidth())
        let scy: Float = (Float)(scale / live2DModel.getCanvasWidth() * (Float)(size.width / size.height))
        let x: Float = 0
        let y: Float = isLandscape ? -2.4 : -0.8

        let matrix4 = SCNMatrix4(
            m11: scx, m12: 0, m13: 0, m14: 0,
            m21: 0, m22: scy, m23: 0, m24: 0,
            m31: 0, m32: 0, m33: 1, m34: 0,
            m41: x, m42: y, m43: 0, m44: 1
        )
        live2DModel.setMatrix(matrix4)
    }
}

// MARK: - ARSessionDelegate

extension ViewController: ARSessionDelegate {
    func session(_: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion,
        ]
        let errorMessage = messages.compactMap { $0 }.joined(separator: "\n")

        DispatchQueue.main.async {
            print("The AR session failed. ::" + errorMessage)
        }
    }

    func sessionWasInterrupted(_: ARSession) {}

    func sessionInterruptionEnded(_: ARSession) {
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
            print("Set broadcast controller failed. ::" + errorString(error!))
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
