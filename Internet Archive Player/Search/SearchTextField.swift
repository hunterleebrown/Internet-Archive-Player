//
//  SearchTextField.swift
//  TVGuide
//
//  Created by Jonathan Swaidner on 4/1/20.
//  Copyright © 2020 CBS Interactive. All rights reserved.
//

import SwiftUI
import UIKit

final class SearchTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    private var setFirstResponder: Bool = false
    private var onReturn: () -> Void = {}
    
    /// Sets textField as active on first appear
    func becomeFirstResponder() -> Self {
        self.setFirstResponder = true
        return self
    }
    
    func onReturn(_ action: @escaping () -> Void) -> Self {
        self.onReturn = action
        return self
    }
    
    // MARK: - Initialization
    
    init(_ text: Binding<String>, placeholder: String = "Search The Archive") {
        self._text = text
        self.placeholder = placeholder
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = PaddedTextField(frame: .zero)
        textField.placeholder = placeholder
        textField.keyboardType = .default
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(context.coordinator.textFieldTextDidChange(_:)), for: .editingChanged)
        textField.autocorrectionType = .no
        textField.rightViewMode = .whileEditing
        textField.clearButtonMode = .never
        textField.rightView = clearButtonView(context.coordinator)
        textField.font = UIFont(name: "ProximaNova-Regular", size: 14)
        textField.returnKeyType = .search
        
        if setFirstResponder { textField.becomeFirstResponder() }
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.isFirstResponder ? styleActive(uiView) : styleInactive(uiView)
        uiView.text = text
        uiView.rightView?.isHidden = text.isEmpty
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Styling
    
    func clearButtonView(_ coordinator: Coordinator) -> UIView {
        let size = CGSize(width: 20, height: 20)
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 28, height: size.height))
        let clearButton = UIButton(frame: CGRect(origin: .zero, size: size))
        let icon = UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
        
        let normalImage = UIGraphicsImageRenderer(size:size).image { _ in
            let color = UIColor(red: 142/255.0, green: 142/255.0, blue: 142/255.0, alpha: 1.0)
            icon?.withTintColor(color).draw(in: CGRect(origin:.zero, size:size))
        }
        
        let highlightImage = UIGraphicsImageRenderer(size:size).image { _ in
            let color = UIColor(red: 142/255.0, green: 142/255.0, blue: 142/255.0, alpha: 0.5)
            icon?.withTintColor(color).draw(in: CGRect(origin:.zero, size:size))
        }
        
        clearButton.setImage(normalImage, for: .normal)
        clearButton.setImage(highlightImage, for: .highlighted)
        clearButton.addTarget(coordinator, action: #selector(coordinator.clearText), for: .touchUpInside)
        
        view.addSubview(clearButton)
        return view
    }
    
    func styleActive(_ textField: UITextField) {
        textField.tintColor = .black
        textField.textColor = .black
        textField.backgroundColor = .white
    }
    
    func styleInactive(_ textField: UITextField) {
        textField.textColor = UIColor.gray
        textField.backgroundColor = UIColor(named: "PlaceholderBackgroundColor")
    }
    
    // MARK: - Coordinator

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SearchTextField
        

        init(_ textField: SearchTextField) {
            self.parent = textField
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard let text = textField.text, text != "" else { return false }
            
            textField.resignFirstResponder()
            parent.onReturn()
            return true
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.styleActive(textField)
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.styleInactive(textField)
        }
         
        @objc func textFieldTextDidChange(_ sender: UITextField) {
            let text = sender.text ?? ""
            parent.text = text
        }
        
        @objc func clearText() {
            self.parent.text = ""
        }
    }
}

