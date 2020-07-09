/**
 *
 * SettingController.swift
 * ARKit-Live2D
 * Created by Yi Chen on 2020/3/21.
 *
 * Copyright (c) 2020, Yuki MIZUNO
 * All rights reserved.
 *
 * See LICENSE for license information
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

import UIKit

class SettingController: UIViewController {
    fileprivate let setBackgroundColorButton: UIButton = {
        let button = UIButton()
        button.setTitle("Change Background Color", for: .normal)
        button.addTarget(self, action: #selector(handleChangeColor), for: .touchUpInside)
        return button
    }()

    @objc fileprivate func handleChangeColor() {
        let defaults = UserDefaults.standard
        let alert = UIAlertController(title: "Enter Color Here", message: "RGB value are ranged [0, 255]", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "R value here"
            textField.text = "\(Int(defaults.float(forKey: RED_COLOR) * 255))"
            textField.keyboardType = .numberPad
        }
        alert.addTextField { textField in
            textField.placeholder = "G value here"
            textField.text = "\(Int(defaults.float(forKey: GREEN_COLOR) * 255))"
            textField.keyboardType = .numberPad
        }
        alert.addTextField { textField in
            textField.placeholder = "B value here"
            textField.text = "\(Int(defaults.float(forKey: BLUE_COLOR) * 255))"
            textField.keyboardType = .numberPad
        }

        guard let colorTextFields = alert.textFields else {
            fatalError("Fatal Error")
        }

        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { _ in
            var rgb: [Float] = [1 / 255, 1 / 255, 1 / 255]
            for tf in colorTextFields {
                guard let text = tf.text else {
                    self.displayAlert(alertTitle: "Error", alertMessage: "Try again")
                    return
                }
                if text.isEmpty {
                    self.displayAlert(alertTitle: "Error", alertMessage: "Please fill all fields")
                }
                let numberOnly = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: text))

                if numberOnly {
                    guard let number: Float = Float(text) else {
                        fatalError("Fatal Error")
                    }
                    if !self.checkRange(value: number) {
                        self.displayAlert(alertTitle: "Error", alertMessage: "Number is not in range [0, 255]")
                        return
                    } else {
                        guard let index = colorTextFields.firstIndex(of: tf) else {
                            fatalError("Fatal Error")
                        }
                        rgb[index] *= number
                    }
                } else {
                    self.displayAlert(alertTitle: "Error", alertMessage: "Please enter number only")
                }
            }
            for i in 0 ... 2 {
                defaults.set(rgb[i], forKey: colorKeys[i])
            }
            self.updateInfo()
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    fileprivate func checkRange(value: Float) -> Bool {
        return (value >= 0 && value <= 255)
    }

    fileprivate let zoomTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Zoom"
        return label
    }()

    // default = 1 / 1.3
    fileprivate let setZoomSlider: UISlider = {
        let defaults = UserDefaults.standard
        let slider = UISlider()
        slider.maximumValue = 4
        slider.value = defaults.float(forKey: ZOOM)
        slider.minimumValue = 0
        slider.addTarget(self, action: #selector(handleSlideZoom), for: .valueChanged)
        return slider
    }()

    @objc fileprivate func handleSlideZoom() {
        let defaults = UserDefaults.standard
        defaults.set(setZoomSlider.value, forKey: ZOOM)
        updateInfo()
    }

    fileprivate let setYPositionSlider: UISlider = {
        let defaults = UserDefaults.standard
        let slider = UISlider()
        slider.maximumValue = 3
        slider.value = defaults.float(forKey: Y_POS)
        slider.minimumValue = -4
        slider.addTarget(self, action: #selector(handleYPos), for: .valueChanged)
        return slider
    }()

    fileprivate let yPosLabel: UILabel = {
        let label = UILabel()
        label.text = "Y-Position"
        return label
    }()

    @objc fileprivate func handleYPos() {
        let defaults = UserDefaults.standard
        defaults.set(setYPositionSlider.value, forKey: Y_POS)
        updateInfo()
    }

    fileprivate let setXPositionSlider: UISlider = {
        let defaults = UserDefaults.standard
        let slider = UISlider()
        slider.maximumValue = 2
        slider.value = defaults.float(forKey: X_POS)
        slider.minimumValue = -2
        slider.addTarget(self, action: #selector(handleXPos), for: .valueChanged)
        return slider
    }()

    fileprivate let xPosLabel: UILabel = {
        let label = UILabel()
        label.text = "X-Position"
        return label
    }()

    @objc fileprivate func handleXPos() {
        let defaults = UserDefaults.standard
        defaults.set(setXPositionSlider.value, forKey: X_POS)
        updateInfo()
    }

    fileprivate let infoTextView: UITextView = {
        let tf = UITextView()
        tf.backgroundColor = .clear
        tf.isEditable = false
        tf.isScrollEnabled = false
        return tf
    }()

    fileprivate func generateInfo() -> String {
        let defaults = UserDefaults.standard
        let r = defaults.float(forKey: RED_COLOR)
        let g = defaults.float(forKey: GREEN_COLOR)
        let b = defaults.float(forKey: BLUE_COLOR)
        let zoom = defaults.float(forKey: ZOOM)
        let y_pos = defaults.float(forKey: Y_POS)
        let x_pos = defaults.float(forKey: X_POS)
        return "R: \(r)\nG: \(g)\nB: \(b)\nZoom: \(zoom)\nY-Pos: \(y_pos)\nX-Pos: \(x_pos)\n"
    }

    fileprivate func updateInfo() {
        infoTextView.text = generateInfo()
    }

    fileprivate let resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("Restore Default", for: .normal)
        button.addTarget(self, action: #selector(handleDefault), for: .touchUpInside)
        return button
    }()

    @objc fileprivate func handleDefault() {
        let alert = UIAlertController(title: "Warning", message: "Are you sure you want to restore to default settings?", preferredStyle: .alert)
        alert.addAction(.init(title: "Restore", style: .destructive, handler: { _ in
            let oldInfo = self.generateInfo()
            let pasteboard = UIPasteboard.general
            pasteboard.string = oldInfo
            let defaults = UserDefaults.standard
            defaults.set(RED_COLOR_DEFAULT, forKey: RED_COLOR)
            defaults.set(GREEN_COLOR_DEFAULT, forKey: GREEN_COLOR)
            defaults.set(BLUE_COLOR_DEFAULT, forKey: BLUE_COLOR)
            defaults.set(ZOOM_DEFAULT, forKey: ZOOM)
            defaults.set(X_POS_DEFAULT, forKey: X_POS)
            defaults.set(Y_POS_DEFAULT, forKey: Y_POS)
            self.updateInfo()
            self.displayAlert(alertTitle: "Restored", alertMessage: "However, your old settings are stored in pasteboard")
        }))
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateInfo()

        let zoomStackView = UIStackView(arrangedSubviews: [zoomTitleLabel, setZoomSlider])
        zoomStackView.axis = .horizontal
        zoomStackView.spacing = 8

        let yPosStackView = UIStackView(arrangedSubviews: [yPosLabel, setYPositionSlider])
        yPosStackView.axis = .horizontal
        yPosStackView.spacing = 8

        let xPosStackView = UIStackView(arrangedSubviews: [xPosLabel, setXPositionSlider])
        xPosStackView.axis = .horizontal
        xPosStackView.spacing = 8

        let mainStackView = UIStackView(arrangedSubviews: [setBackgroundColorButton, zoomStackView, yPosStackView, xPosStackView, infoTextView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 12

        view.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 24.0).isActive = true
        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24.0).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24.0).isActive = true

        view.addSubview(resetButton)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24.0).isActive = true
        resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0.0).isActive = true
        resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0.0).isActive = true
        resetButton.widthAnchor.constraint(equalToConstant: 100.0).isActive = true
    }

    fileprivate func displayAlert(alertTitle title: String, alertMessage msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
