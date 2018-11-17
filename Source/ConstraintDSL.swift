//
//  SnapKit
//
//  Copyright (c) 2011-Present SnapKit Team - https://github.com/SnapKit
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(iOS) || os(tvOS)
    import UIKit
#else
    import AppKit
#endif

//  面向协议编程，将所有遵守的对象增加对象 target 和对应的标识名称
public protocol ConstraintDSL {
    
    var target: AnyObject? { get }
    
    func setLabel(_ value: String?)
    func label() -> String?
    
}

extension ConstraintDSL {
    // 通过 extension 增加默认方法的实现
    public func setLabel(_ value: String?) {
        objc_setAssociatedObject(self.target as Any, &labelKey, value, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }
    public func label() -> String? {
        return objc_getAssociatedObject(self.target as Any, &labelKey) as? String
    }
    
}

private var labelKey: UInt8 = 0

//  创建默认协议，用于参数设置
public protocol ConstraintBasicAttributesDSL : ConstraintDSL {
}
extension ConstraintBasicAttributesDSL {
    
    // MARK: Basics
    // 增加上下左右的对象，通过枚举类型的位偏移，保证数据解析正确
    public var left: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.left)
    }
    
    public var top: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.top)
    }
    
    public var right: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.right)
    }
    
    public var bottom: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.bottom)
    }
    
    public var leading: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.leading)
    }
    
    public var trailing: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.trailing)
    }
    
    public var width: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.width)
    }
    
    public var height: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.height)
    }
    
    public var centerX: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.centerX)
    }
    
    public var centerY: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.centerY)
    }
    
    public var edges: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.edges)
    }
    
    public var size: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.size)
    }
    
    public var center: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.center)
    }
    
}

// 对于 View 的 DSL 进行一层协议封装
public protocol ConstraintAttributesDSL : ConstraintBasicAttributesDSL {
}
extension ConstraintAttributesDSL {
    
    // MARK: Baselines
    // 提供默认方法
    @available(*, deprecated:3.0, message:"Use .lastBaseline instead")
    public var baseline: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.lastBaseline)
    }
    
    @available(iOS 8.0, OSX 10.11, *)
    public var lastBaseline: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.lastBaseline)
    }
    
    @available(iOS 8.0, OSX 10.11, *)
    public var firstBaseline: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.firstBaseline)
    }
    
    // MARK: Margins
    // 提供默认 Margin
    @available(iOS 8.0, *)
    public var leftMargin: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.leftMargin)
    }
    
    @available(iOS 8.0, *)
    public var topMargin: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.topMargin)
    }
    
    @available(iOS 8.0, *)
    public var rightMargin: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.rightMargin)
    }
    
    @available(iOS 8.0, *)
    public var bottomMargin: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.bottomMargin)
    }
    
    @available(iOS 8.0, *)
    public var leadingMargin: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.leadingMargin)
    }
    
    @available(iOS 8.0, *)
    public var trailingMargin: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.trailingMargin)
    }
    
    @available(iOS 8.0, *)
    public var centerXWithinMargins: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.centerXWithinMargins)
    }
    
    @available(iOS 8.0, *)
    public var centerYWithinMargins: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.centerYWithinMargins)
    }
    
    @available(iOS 8.0, *)
    public var margins: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.margins)
    }
    
    @available(iOS 8.0, *)
    public var centerWithinMargins: ConstraintItem {
        return ConstraintItem(target: self.target, attributes: ConstraintAttributes.centerWithinMargins)
    }
    
}
