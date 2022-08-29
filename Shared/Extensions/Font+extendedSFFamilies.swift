//
//  Font+extendedSFFamilies.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/08/2022.
//

import SwiftUI

public extension Font {
	init(uiFont: UIFont) {
		self = Font(uiFont as CTFont)
	}
	
	static func expanded(_ style: UIFont.TextStyle, size: CGFloat? = nil, weight: Font.Weight = .regular) -> Font {
		var descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
		let traits: [UIFontDescriptor.TraitKey:Any] = [.width: 1.5]
		descriptor = descriptor.addingAttributes([.traits: traits])
		let uiFont = UIFont(descriptor: descriptor, size: size ?? descriptor.pointSize)
		return Font(uiFont: uiFont).weight(weight)
	}
	
	static func condensed(_ style: UIFont.TextStyle, size: CGFloat? = nil, weight: Font.Weight = .regular) -> Font {
		
		var descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
		let traits: [UIFontDescriptor.TraitKey:Any] = [.width: -0.2]
		descriptor = descriptor.addingAttributes([.traits: traits])
		let uiFont = UIFont(descriptor: descriptor, size: size ?? descriptor.pointSize)
		return Font(uiFont: uiFont).weight(weight)
	}
}
