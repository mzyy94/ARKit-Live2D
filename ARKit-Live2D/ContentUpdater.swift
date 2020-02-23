/**
 *
 * ContentUpdater.swift
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

import SceneKit
import ARKit

class ContentUpdater: NSObject, ARSCNViewDelegate {
    
    // MARK: - Properties
    var live2DModel: Live2DModelOpenGL!

    // MARK: - ARSCNViewDelegate
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        guard let eyeBlinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft] as? Float,
            let eyeBlinkRight = faceAnchor.blendShapes[.eyeBlinkRight] as? Float,
            let browInnerUp = faceAnchor.blendShapes[.browInnerUp] as? Float,
            let browOuterUpLeft = faceAnchor.blendShapes[.browOuterUpLeft] as? Float,
            let browOuterUpRight = faceAnchor.blendShapes[.browOuterUpRight] as? Float,
            let mouthFunnel = faceAnchor.blendShapes[.mouthFunnel] as? Float,
            let jawOpen = faceAnchor.blendShapes[.jawOpen] as? Float
            else { return }
        
        let c = faceAnchor.transform.columns

        live2DModel.setParam("ParamAngleZ", value: atan2f(c.1.x, c.1.y) * 180 / Float.pi)

        live2DModel.setParam("ParamBrowLY", value: -(0.5 - browOuterUpLeft))
        live2DModel.setParam("ParamBrowRY", value: -(0.5 - browOuterUpRight))
        live2DModel.setParam("ParamBrowLAngle", value: 2*(browInnerUp - browOuterUpLeft))
        live2DModel.setParam("ParamBrowRAngle", value: 2*(browInnerUp - browOuterUpRight))

        live2DModel.setParam("ParamEyeLOpen", value: 1.0 - eyeBlinkLeft)
        live2DModel.setParam("ParamEyeROpen", value: 1.0 - eyeBlinkRight)
        
        live2DModel.setParam("ParamMouthOpenY", value: jawOpen*1.8)
        live2DModel.setParam("ParamMouthForm", value: 1 - mouthFunnel*2)

    }
}

