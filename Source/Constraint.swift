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

// 每一条约束的对象，用于描述 A 的 x 相对于 B 的 y 的位置和数值是多少，以及相关的优先级以及比例

#if os(iOS) || os(tvOS)
    import UIKit
#else
    import AppKit
#endif

public final class Constraint {

    internal let sourceLocation: (String, UInt)
    internal let label: String?

    private let from: ConstraintItem
    private let to: ConstraintItem
    private let relation: ConstraintRelation
    private let multiplier: ConstraintMultiplierTarget
    private var constant: ConstraintConstantTarget {
        didSet {
            self.updateConstantAndPriorityIfNeeded()
        }
    }
    private var priority: ConstraintPriorityTarget {
        didSet {
          self.updateConstantAndPriorityIfNeeded()
        }
    }
    public var layoutConstraints: [LayoutConstraint]
    
    public var isActive: Bool {
        set {
            if newValue {
                activate()
            }
            else {
                deactivate()
            }
        }
        
        get {
            for layoutConstraint in self.layoutConstraints {
                if layoutConstraint.isActive {
                    return true
                }
            }
            return false
        }
    }
    
    // MARK: Initialization

    internal init(from: ConstraintItem,
                  to: ConstraintItem,
                  relation: ConstraintRelation,
                  sourceLocation: (String, UInt),
                  label: String?,
                  multiplier: ConstraintMultiplierTarget,
                  constant: ConstraintConstantTarget,
                  priority: ConstraintPriorityTarget) {
        self.from = from
        self.to = to
        self.relation = relation
        self.sourceLocation = sourceLocation
        self.label = label
        self.multiplier = multiplier
        self.constant = constant
        self.priority = priority
        self.layoutConstraints = []

        // get attributes
        // 获得源 view 和目标 view 之间的所有位置描述
        let layoutFromAttributes = self.from.attributes.layoutAttributes
        let layoutToAttributes = self.to.attributes.layoutAttributes

        // get layout from
        // 获得源 view
        let layoutFrom = self.from.layoutConstraintItem!

        // get relation
        // 获得相对关系，是大于还是等于还是小于
        let layoutRelation = self.relation.layoutRelation

        // 遍历所有源目标的 attribute
        for layoutFromAttribute in layoutFromAttributes {
            // get layout to attribute
            // 创建一个目标的位置描述
            let layoutToAttribute: LayoutAttribute
            #if os(iOS) || os(tvOS)
                // 根据目标进行数据分析
                if layoutToAttributes.count > 0 {
                    // 如果对方设置了对应的目标，如果目标是 edges 边缘，而目标是 margins
                    if self.from.attributes == .edges && self.to.attributes == .margins {
                        // 那么根据当前的遍历对象设置设置目标对象，将目标值设置为对应方向的 margin
                        switch layoutFromAttribute {
                        case .left:
                            layoutToAttribute = .leftMargin
                        case .right:
                            layoutToAttribute = .rightMargin
                        case .top:
                            layoutToAttribute = .topMargin
                        case .bottom:
                            layoutToAttribute = .bottomMargin
                        default:
                            fatalError()
                        }
                    } else if self.from.attributes == .margins && self.to.attributes == .edges {
                        // 如果返过来，那么赋值也是犯规来
                        switch layoutFromAttribute {
                        case .leftMargin:
                            layoutToAttribute = .left
                        case .rightMargin:
                            layoutToAttribute = .right
                        case .topMargin:
                            layoutToAttribute = .top
                        case .bottomMargin:
                            layoutToAttribute = .bottom
                        default:
                            fatalError()
                        }
                    } else if self.from.attributes == self.to.attributes {
                        // 如果这两个数组一样，那么直接赋值
                        layoutToAttribute = layoutFromAttribute
                    } else {
                        // 否则获得 toAttribute 的第一个进行赋值
                        layoutToAttribute = layoutToAttributes[0]
                    }
                } else {
                    // 如果目标是空，且当前对象是居中对齐中的一个，那么就是根据是垂直还是水平，赋值 .left 和 .top
                    if self.to.target == nil && (layoutFromAttribute == .centerX || layoutFromAttribute == .centerY) {
                        layoutToAttribute = layoutFromAttribute == .centerX ? .left : .top
                    } else {
                        // 否则就直接用两边相等进行计算
                        layoutToAttribute = layoutFromAttribute
                    }
                }
            #else
                if self.from.attributes == self.to.attributes {
                    layoutToAttribute = layoutFromAttribute
                } else if layoutToAttributes.count > 0 {
                    layoutToAttribute = layoutToAttributes[0]
                } else {
                    layoutToAttribute = layoutFromAttribute
                }
            #endif

            // get layout constant
            // 将对应的 constraint 进行数据化
            let layoutConstant: CGFloat = self.constant.constraintConstantTargetValueFor(layoutAttribute: layoutToAttribute)

            // get layout to
            // 获得目标约束
            var layoutTo: AnyObject? = self.to.target

            // use superview if possible
            //  如果没有目标对象但是有非长宽的属性设置，那么就是用父对象
            if layoutTo == nil && layoutToAttribute != .width && layoutToAttribute != .height {
                layoutTo = layoutFrom.superview
            }

            // create layout constraint
            // 创建系统底层的 Layout 约束
            let layoutConstraint = LayoutConstraint(
                item: layoutFrom,
                attribute: layoutFromAttribute,
                relatedBy: layoutRelation,
                toItem: layoutTo,
                attribute: layoutToAttribute,
                multiplier: self.multiplier.constraintMultiplierTargetValue,
                constant: layoutConstant
            )

            // set label
            // 设置标签
            layoutConstraint.label = self.label

            // set priority
            // 设置优先级
            layoutConstraint.priority = LayoutPriority(rawValue: self.priority.constraintPriorityTargetValue)

            // set constraint
            // 并将自身这个约束附着到创建出来的对象上，方便后期调整
            layoutConstraint.constraint = self

            // append
            // 将新建出来的约束放到约束数组里面，方便后期更改。
            self.layoutConstraints.append(layoutConstraint)
        }
    }

    // MARK: Public

    @available(*, deprecated:3.0, message:"Use activate().")
    public func install() {
        self.activate()
    }

    @available(*, deprecated:3.0, message:"Use deactivate().")
    public func uninstall() {
        self.deactivate()
    }

    // 激活所有约束，在更新的时候设置
    public func activate() {
        self.activateIfNeeded()
    }

    // 注销所有约束，在更新的时候需要设置
    public func deactivate() {
        self.deactivateIfNeeded()
    }

    // 更新新约束的值
    @discardableResult
    public func update(offset: ConstraintOffsetTarget) -> Constraint {
        self.constant = offset.constraintOffsetTargetValue
        return self
    }

    @discardableResult
    public func update(inset: ConstraintInsetTarget) -> Constraint {
        self.constant = inset.constraintInsetTargetValue
        return self
    }
    
    // 更新约束的优先级
    @discardableResult
    public func update(priority: ConstraintPriorityTarget) -> Constraint {
        self.priority = priority.constraintPriorityTargetValue
        return self
    }

    @discardableResult
    public func update(priority: ConstraintPriority) -> Constraint {
        self.priority = priority.value
        return self
    }

    @available(*, deprecated:3.0, message:"Use update(offset: ConstraintOffsetTarget) instead.")
    public func updateOffset(amount: ConstraintOffsetTarget) -> Void { self.update(offset: amount) }

    @available(*, deprecated:3.0, message:"Use update(inset: ConstraintInsetTarget) instead.")
    public func updateInsets(amount: ConstraintInsetTarget) -> Void { self.update(inset: amount) }

    @available(*, deprecated:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriority(amount: ConstraintPriorityTarget) -> Void { self.update(priority: amount) }

    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityRequired() -> Void {}

    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityHigh() -> Void { fatalError("Must be implemented by Concrete subclass.") }

    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityMedium() -> Void { fatalError("Must be implemented by Concrete subclass.") }

    @available(*, obsoleted:3.0, message:"Use update(priority: ConstraintPriorityTarget) instead.")
    public func updatePriorityLow() -> Void { fatalError("Must be implemented by Concrete subclass.") }

    // MARK: Internal

    // 在更新完之后调用，如果更新了约束值，或者修改了优先级，那么就更新的约束
    internal func updateConstantAndPriorityIfNeeded() {
        for layoutConstraint in self.layoutConstraints {
            // 如果更新之后的对象是没有对象，那么就和源对象的属性一致
            let attribute = (layoutConstraint.secondAttribute == .notAnAttribute) ? layoutConstraint.firstAttribute : layoutConstraint.secondAttribute
            // 重新设置约束值
            layoutConstraint.constant = self.constant.constraintConstantTargetValueFor(layoutAttribute: attribute)

            // 更新优先级的值
            let requiredPriority = ConstraintPriority.required.value
            if (layoutConstraint.priority.rawValue < requiredPriority), (self.priority.constraintPriorityTargetValue != requiredPriority) {
                layoutConstraint.priority = LayoutPriority(rawValue: self.priority.constraintPriorityTargetValue)
            }
        }
    }

    internal func activateIfNeeded(updatingExisting: Bool = false) {
        // 获得源的 view
        guard let item = self.from.layoutConstraintItem else {
            print("WARNING: SnapKit failed to get from item from constraint. Activate will be a no-op.")
            return
        }
        // 已经创建完的约束对象
        let layoutConstraints = self.layoutConstraints

        // 根据外部是否传入需要激活来重新，只有在调用 updateConstraints 方法之后才会被激活
        if updatingExisting {
            // 已经在 view 上的所有约束集合
            var existingLayoutConstraints: [LayoutConstraint] = []
            // 遍历这个 view 上的所有约束对象，获得所有方向
            for constraint in item.constraints {
                existingLayoutConstraints += constraint.layoutConstraints
            }

            // 已经创建完的对象
            for layoutConstraint in layoutConstraints {
                // 获得已经存在的对象中的第一个在 view 中存在，且被保存在我的 constraint 当中的对象
                let existingLayoutConstraint = existingLayoutConstraints.first { $0 == layoutConstraint }
                guard let updateLayoutConstraint = existingLayoutConstraint else {
                    fatalError("Updated constraint could not find existing matching constraint to update: \(layoutConstraint)")
                }

                let updateLayoutAttribute = (updateLayoutConstraint.secondAttribute == .notAnAttribute) ? updateLayoutConstraint.firstAttribute : updateLayoutConstraint.secondAttribute
                updateLayoutConstraint.constant = self.constant.constraintConstantTargetValueFor(layoutAttribute: updateLayoutAttribute)
            }
        } else {
            // 激活所有 view
            NSLayoutConstraint.activate(layoutConstraints)
            item.add(constraints: [self])
        }
    }

    internal func deactivateIfNeeded() {
        guard let item = self.from.layoutConstraintItem else {
            print("WARNING: SnapKit failed to get from item from constraint. Deactivate will be a no-op.")
            return
        }
        // 从 from 当中将需要对齐的对象拿出来，并在已经设置完的 array 当中注销，最后将他从 from 中移除。
        let layoutConstraints = self.layoutConstraints
        NSLayoutConstraint.deactivate(layoutConstraints)
        item.remove(constraints: [self])
    }
}
