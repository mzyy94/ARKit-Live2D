/**
 *
 * ContentUpdater.swift
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
import SceneKit

class ContentUpdater: NSObject, ARSCNViewDelegate {
    // MARK: - Properties

    var live2DModel: Live2DModelOpenGL!

    // MARK: - ARSCNViewDelegate

    /// - Tag: ARNodeTracking
    func renderer(_: SCNSceneRenderer, didAdd _: SCNNode, for _: ARAnchor) {}

    /// - Tag: ARFaceGeometryUpdate
    func renderer(_: SCNSceneRenderer, didUpdate _: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        guard let eyeBlinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft] as? Float,
            let eyeBlinkRight = faceAnchor.blendShapes[.eyeBlinkRight] as? Float,
            let browInnerUp = faceAnchor.blendShapes[.browInnerUp] as? Float,
            let browOuterUpLeft = faceAnchor.blendShapes[.browOuterUpLeft] as? Float,
            let browOuterUpRight = faceAnchor.blendShapes[.browOuterUpRight] as? Float,
            let mouthFunnel = faceAnchor.blendShapes[.mouthFunnel] as? Float,
            let jawOpen = faceAnchor.blendShapes[.jawOpen] as? Float,
            let cheekPuff = faceAnchor.blendShapes[.cheekPuff] as? Float
        else { return }

        let newFaceMatrix = SCNMatrix4(faceAnchor.transform)
        let faceNode = SCNNode()
        faceNode.transform = newFaceMatrix

        live2DModel.setParam("ParamAngleY", value: faceNode.eulerAngles.x * -360 / Float.pi)
        live2DModel.setParam("ParamAngleX", value: faceNode.eulerAngles.y * 360 / Float.pi)
        live2DModel.setParam("ParamAngleZ", value: faceNode.eulerAngles.z * -360 / Float.pi)

        live2DModel.setParam("ParamBodyPosition", value: 10 + faceNode.position.z * 20)
        live2DModel.setParam("ParamBodyAngleZ", value: faceNode.position.x * 20)
        live2DModel.setParam("ParamBodyAngleY", value: faceNode.position.y * 20)

        live2DModel.setParam("ParamEyeBallX", value: faceAnchor.lookAtPoint.x * 2)
        live2DModel.setParam("ParamEyeBallY", value: faceAnchor.lookAtPoint.y * 2)

        live2DModel.setParam("ParamBrowLY", value: -(0.5 - browOuterUpLeft))
        live2DModel.setParam("ParamBrowRY", value: -(0.5 - browOuterUpRight))
        live2DModel.setParam("ParamBrowLAngle", value: 16 * (browInnerUp - browOuterUpLeft) - 1.6)
        live2DModel.setParam("ParamBrowRAngle", value: 16 * (browInnerUp - browOuterUpRight) - 1.6)

        live2DModel.setParam("ParamEyeLOpen", value: 1.0 - eyeBlinkLeft)
        live2DModel.setParam("ParamEyeROpen", value: 1.0 - eyeBlinkRight)

        live2DModel.setParam("ParamMouthOpenY", value: jawOpen * 1.8)
        live2DModel.setParam("ParamMouthForm", value: 1 - mouthFunnel * 2)

        live2DModel.setParam("ParamCheek", value: cheekPuff)
    }
}
