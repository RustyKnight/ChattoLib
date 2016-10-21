/*
The MIT License (MIT)

Copyright (c) 2015-present Badoo Trading Limited.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import UIKit

public protocol BaseMessageCollectionViewCellStyleProtocol {
	func avatarSize(viewModel: MessageViewModelProtocol) -> CGSize // .zero => no avatar
	func avatarVerticalAlignment(viewModel: MessageViewModelProtocol) -> VerticalAlignment
	var failedIcon: UIImage { get }
	var failedIconHighlighted: UIImage { get }
	func attributedStringForDate(_ date: String) -> NSAttributedString
	func layoutConstants(viewModel: MessageViewModelProtocol) -> BaseMessageCollectionViewCellLayoutConstants
	
	var selectedCheckboxIcon: UIImage {get}
	var unselectedCheckboxIcon: UIImage {get}
}

public struct BaseMessageCollectionViewCellLayoutConstants {
	public let horizontalMargin: CGFloat
	public let horizontalInterspacing: CGFloat
	public let horizontalTimestampMargin: CGFloat
	public let maxContainerWidthPercentageForBubbleView: CGFloat
	
	public init(horizontalMargin: CGFloat,
	            horizontalInterspacing: CGFloat,
	            horizontalTimestampMargin: CGFloat,
	            maxContainerWidthPercentageForBubbleView: CGFloat) {
		self.horizontalMargin = horizontalMargin
		self.horizontalInterspacing = horizontalInterspacing
		self.horizontalTimestampMargin = horizontalTimestampMargin
		self.maxContainerWidthPercentageForBubbleView = maxContainerWidthPercentageForBubbleView
	}
}

/**
Base class for message cells

Provides:

- Reveleable timestamp layout logic
- Failed view
- Incoming/outcoming layout

Subclasses responsability
- Implement createBubbleView
- Have a BubbleViewType that responds properly to sizeThatFits:
*/

open class BaseMessageCollectionViewCell<BubbleViewType>: UICollectionViewCell, BackgroundSizingQueryable, AccessoryViewRevealable, UIGestureRecognizerDelegate where BubbleViewType:UIView, BubbleViewType:MaximumLayoutWidthSpecificable, BubbleViewType: BackgroundSizingQueryable {
	
	typealias Class = BaseMessageCollectionViewCell
	
	public var animationDuration: CFTimeInterval = 0.33
	open var viewContext: ViewContext = .normal
	
	var checkBoxImageView: UIImageView!
//	var deleteButton: UIButton!
	
	public private(set) var isUpdating: Bool = false
	open func performBatchUpdates(_ updateClosure: @escaping () -> Void, animated: Bool, completion: (() ->())?) {
		self.isUpdating = true
		let updateAndRefreshViews = {
			updateClosure()
			self.isUpdating = false
			self.updateViews()
			if animated {
				self.layoutIfNeeded()
			}
		}
		if animated {
			UIView.animate(withDuration: self.animationDuration, animations: updateAndRefreshViews, completion: { (finished) -> Void in
				completion?()
			})
		} else {
			updateAndRefreshViews()
		}
	}
	
	open var messageViewModel: MessageViewModelProtocol! {
		didSet {
			updateViews()
		}
	}
	
	var failedIcon: UIImage!
	var failedIconHighlighted: UIImage!
	public var baseStyle: BaseMessageCollectionViewCellStyleProtocol! {
		didSet {
			self.selectedImage = self.baseStyle.selectedCheckboxIcon
			self.unselectedImage = self.baseStyle.unselectedCheckboxIcon
			self.failedIcon = self.baseStyle.failedIcon
			self.failedIconHighlighted = self.baseStyle.failedIconHighlighted
			self.updateViews()
		}
	}
	
	override open var isSelected: Bool {
		didSet {
			if oldValue != self.isSelected {
				self.updateViews()
			}
			if isSelected {
				checkBoxImageView.image = selectedImage
			} else {
				checkBoxImageView.image = unselectedImage
			}
			setNeedsDisplay()
		}
	}
	
	open var canCalculateSizeInBackground: Bool {
		return self.bubbleView.canCalculateSizeInBackground
	}
	
	public private(set) var bubbleView: BubbleViewType!
	open func createBubbleView() -> BubbleViewType! {
		assert(false, "Override in subclass")
		return nil
	}
	
	public private(set) var avatarView: UIImageView!
	func createAvatarView() -> UIImageView! {
		let avatarImageView = UIImageView(frame: CGRect.zero)
		avatarImageView.isUserInteractionEnabled = true
		return avatarImageView
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		self.commonInit()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.commonInit()
	}
	
	public private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = {
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseMessageCollectionViewCell.bubbleTapped(_:)))
		return tapGestureRecognizer
	}()
	
	public private (set) lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
		let longpressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(BaseMessageCollectionViewCell.bubbleLongPressed(_:)))
		longpressGestureRecognizer.delegate = self
		return longpressGestureRecognizer
	}()
	
	public private(set) lazy var avatarTapGestureRecognizer: UITapGestureRecognizer = {
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseMessageCollectionViewCell.avatarTapped(_:)))
		return tapGestureRecognizer
	}()

	public private(set) lazy var selectionTapGestureRecognizer: UITapGestureRecognizer = {
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseMessageCollectionViewCell.selectionTapped(_:)))
		return tapGestureRecognizer
	}()
	
	var selectedImage: UIImage!
	var unselectedImage: UIImage!
	
	private func commonInit() {
		self.avatarView = self.createAvatarView()
		self.avatarView.addGestureRecognizer(self.avatarTapGestureRecognizer)
		self.bubbleView = self.createBubbleView()
		self.bubbleView.isExclusiveTouch = true
		self.bubbleView.addGestureRecognizer(self.tapGestureRecognizer)
		self.bubbleView.addGestureRecognizer(self.longPressGestureRecognizer)
		self.contentView.addSubview(self.avatarView)
		self.contentView.addSubview(self.bubbleView)
		self.contentView.addSubview(self.failedButton)
		self.contentView.isExclusiveTouch = true
		self.isExclusiveTouch = true
		
		checkBoxImageView = UIImageView()
		checkBoxImageView.image = unselectedImage
		checkBoxImageView.sizeToFit()
		checkBoxImageView.frame = CGRect(x: 0,
		                                 y: -checkBoxImageView.bounds.size.width,
		                                 width: checkBoxImageView.bounds.size.width,
		                                 height: checkBoxImageView.bounds.size.height)
		checkBoxImageView.isUserInteractionEnabled = true
		addSubview(checkBoxImageView)
		checkBoxImageView.addGestureRecognizer(selectionTapGestureRecognizer)
		
//		deleteButton = UIButton()
//		deleteButton.setTitle("Delete", for: [])
//		deleteButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
//		deleteButton.setTitleColor(UIColor.white, for: [])
//		deleteButton.backgroundColor = UIColor.red
//		
//		deleteButton.sizeToFit()
//		deleteButton.frame = CGRect(x: 0, y: -deleteButton.bounds.size.width, width: deleteButton.bounds.size.width, height: deleteButton.bounds.size.height)
//		
//		addSubview(deleteButton)
//		
//		deleteButton.addTarget(self, action: #selector(BaseMessageCollectionViewCell.deleteButtonTapped(_:)), for: .touchUpInside)
		
		self.addSubview(self.accessoryTimestampView)
	}
	
	open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return self.bubbleView.bounds.contains(touch.location(in: self.bubbleView))
	}
	
	open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return gestureRecognizer === self.longPressGestureRecognizer
	}
	
	open override func prepareForReuse() {
		super.prepareForReuse()
		checkBoxImageView.image = unselectedImage
//		self.removeAccessoryView()
	}
	
	public lazy var failedButton: UIButton = {
		let button = UIButton(type: .custom)
		button.addTarget(self, action: #selector(BaseMessageCollectionViewCell.failedButtonTapped), for: .touchUpInside)
		return button
	}()
	
	// MARK: View model binding
	
	final private func updateViews() {
		if self.viewContext == .sizing { return }
		if self.isUpdating { return }
		guard let viewModel = self.messageViewModel, let style = self.baseStyle else { return }
		if viewModel.showsFailedIcon {
			self.failedButton.setImage(self.failedIcon, for: .normal)
			self.failedButton.setImage(self.failedIconHighlighted, for: .highlighted)
			self.failedButton.alpha = 1
		} else {
			self.failedButton.alpha = 0
		}
		self.accessoryTimestampView.attributedText = style.attributedStringForDate(viewModel.date)
		let avatarImageSize = baseStyle.avatarSize(viewModel: messageViewModel)
		if avatarImageSize != CGSize.zero {
			self.avatarView.image = self.messageViewModel.avatarImage.value
		}
		self.setNeedsLayout()
	}
	
	// MARK: layout
	open override func layoutSubviews() {
		super.layoutSubviews()

		var contentViewframe = self.contentView.frame
		contentViewframe.origin.x += offsetToRevealAccessoryView
		if messageViewModel.isIncoming && offsetToRevealAccessoryView < 0.0 {
			contentViewframe.origin.x = max(0, contentViewframe.origin.x)
		} else if !messageViewModel.isIncoming && offsetToRevealAccessoryView > 0.0 {
			contentViewframe.origin.x = min(0, contentViewframe.origin.x)
		}
		self.contentView.frame = contentViewframe
		
		let layoutModel = self.calculateLayout(availableWidth: self.contentView.bounds.width)
		self.failedButton.bma_rect = layoutModel.failedViewFrame
		self.bubbleView.bma_rect = layoutModel.bubbleViewFrame
		self.bubbleView.preferredMaxLayoutWidth = layoutModel.preferredMaxWidthForBubble
		self.bubbleView.layoutIfNeeded()
		
		self.avatarView.bma_rect = layoutModel.avatarViewFrame

		accessoryTimestampView.sizeToFit()
		let timeFrame = CGRect(x: self.contentView.frame.width + offsetToRevealAccessoryView,
		                       y: (contentView.bounds.height - accessoryTimestampView.intrinsicContentSize.height) / 2.0,
		                       width: accessoryTimestampView.intrinsicContentSize.width,
		                       height: accessoryTimestampView.intrinsicContentSize.height)
		accessoryTimestampView.frame = timeFrame
		
		let buttonHeight = checkBoxImageView.intrinsicContentSize.height
		let yPos = (bounds.height - buttonHeight) / 2.0
		
		let buttonFrame = CGRect(x: offsetToRevealAccessoryView - checkBoxImageView.intrinsicContentSize.width,
		                         y: yPos,
		                         width: checkBoxImageView.intrinsicContentSize.width,
		                         height: buttonHeight)
		checkBoxImageView.frame = buttonFrame
	}
	
	open override func sizeThatFits(_ size: CGSize) -> CGSize {
		return self.calculateLayout(availableWidth: size.width).size
	}
	
	private func calculateLayout(availableWidth: CGFloat) -> BaseMessageLayoutModel {
		let layoutConstants = baseStyle.layoutConstants(viewModel: messageViewModel)
		let parameters = BaseMessageLayoutModelParameters(
			containerWidth: availableWidth,
			horizontalMargin: layoutConstants.horizontalMargin,
			horizontalInterspacing: layoutConstants.horizontalInterspacing,
			failedButtonSize: self.failedIcon.size,
			maxContainerWidthPercentageForBubbleView: layoutConstants.maxContainerWidthPercentageForBubbleView,
			bubbleView: self.bubbleView,
			isIncoming: self.messageViewModel.isIncoming,
			isFailed: self.messageViewModel.showsFailedIcon,
			avatarSize: baseStyle.avatarSize(viewModel: messageViewModel),
			avatarVerticalAlignment: baseStyle.avatarVerticalAlignment(viewModel: messageViewModel)
		)
		var layoutModel = BaseMessageLayoutModel()
		layoutModel.calculateLayout(parameters: parameters)
		return layoutModel
	}
	
	
	// MARK: timestamp revealing
	
	lazy var accessoryTimestampView = UILabel()
	
	var offsetToRevealAccessoryView: CGFloat = 0 {
		didSet {
			self.setNeedsLayout()
		}
	}
	
	var accessoryViewStartOffset: CGFloat = 0.0
	
	public var allowAccessoryViewRevealing: Bool = true
	
	open func preferredOffsetToRevealAccessoryView(`for` offset: CGFloat) -> CGFloat? {
		let layoutConstants = baseStyle.layoutConstants(viewModel: messageViewModel)
		if offset < 0 {
			return self.accessoryTimestampView.intrinsicContentSize.width + layoutConstants.horizontalTimestampMargin
		} else {
			return checkBoxImageView.intrinsicContentSize.width + layoutConstants.horizontalTimestampMargin
		}
	}
	
	open func revealAccessorySide(withOffset offset: CGFloat) -> AccessoryViewRevealSide {
		
		if offset + accessoryViewStartOffset > 0 {
			return .left
		} else if offset + accessoryViewStartOffset < 0 {
			return .right
		} else {
			return .none
		}
		
	}
	
	open func revealAccessoryView(withOffset offset: CGFloat, animated: Bool) {
		offsetToRevealAccessoryView = offset + accessoryViewStartOffset
		if animated {
			UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
				self.layoutIfNeeded()
			})
		}
	}
	
	open func revealAccessoryViewDidStop(atOffset offset: CGFloat) -> Bool {
		var hidden = true
		if offset < 0.0 {
			offsetToRevealAccessoryView = 0.0
			UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
				self.layoutIfNeeded()
			})
		} else {
			let layoutConstants = baseStyle.layoutConstants(viewModel: messageViewModel)
			let size = checkBoxImageView.intrinsicContentSize.width + layoutConstants.horizontalTimestampMargin
			if offsetToRevealAccessoryView > size / 2.0 {
				hidden = false
				offsetToRevealAccessoryView = size
			} else {
				offsetToRevealAccessoryView = 0
			}
			UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
				self.layoutIfNeeded()
			})
		}
		accessoryViewStartOffset = offsetToRevealAccessoryView
		return hidden
	}
	
	// MARK: User interaction
	public var onSelectionTapped: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
	@objc
	func selectionTapped(_ sender: Any) {
		isSelected = !isSelected
		self.onSelectionTapped?(self)
	}
	
	public var onFailedButtonTapped: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
	@objc
	func failedButtonTapped() {
		self.onFailedButtonTapped?(self)
	}
	
	public var onAvatarTapped: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
	@objc
	func avatarTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
		self.onAvatarTapped?(self)
	}
	
	public var onBubbleTapped: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
	@objc
	func bubbleTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
		self.onBubbleTapped?(self)
	}
	
	public var onBubbleLongPressBegan: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
	public var onBubbleLongPressEnded: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
	@objc
	private func bubbleLongPressed(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
		switch longPressGestureRecognizer.state {
		case .began:
			self.onBubbleLongPressBegan?(self)
		case .ended, .cancelled:
			self.onBubbleLongPressEnded?(self)
		default:
			break
		}
	}
}

struct BaseMessageLayoutModel {
	private (set) var size = CGSize.zero
	private (set) var failedViewFrame = CGRect.zero
	private (set) var bubbleViewFrame = CGRect.zero
	private (set) var avatarViewFrame = CGRect.zero
	private (set) var preferredMaxWidthForBubble: CGFloat = 0
	
	
	mutating func calculateLayout(parameters: BaseMessageLayoutModelParameters) {
		let containerWidth = parameters.containerWidth
		let isIncoming = parameters.isIncoming
		let isFailed = parameters.isFailed
		let failedButtonSize = parameters.failedButtonSize
		let bubbleView = parameters.bubbleView
		let horizontalMargin = parameters.horizontalMargin
		let horizontalInterspacing = parameters.horizontalInterspacing
		let avatarSize = parameters.avatarSize
		
		let preferredWidthForBubble = (containerWidth * parameters.maxContainerWidthPercentageForBubbleView).bma_round()
		let bubbleSize = bubbleView.sizeThatFits(CGSize(width: preferredWidthForBubble, height: .greatestFiniteMagnitude))
		let containerRect = CGRect(origin: CGPoint.zero, size: CGSize(width: containerWidth, height: bubbleSize.height))
		
		
		self.bubbleViewFrame = bubbleSize.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: .center, dx: 0, dy: 0)
		self.failedViewFrame = failedButtonSize.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: .center, dx: 0, dy: 0)
		self.avatarViewFrame = avatarSize.bma_rect(inContainer: containerRect, xAlignament: .center, yAlignment: parameters.avatarVerticalAlignment, dx: 0, dy: 0)
		
		// Adjust horizontal positions
		
		var currentX: CGFloat = 0
		if isIncoming {
			currentX = horizontalMargin
			self.avatarViewFrame.origin.x = currentX
			currentX += avatarSize.width
			currentX += horizontalInterspacing
			
			if isFailed {
				self.failedViewFrame.origin.x = currentX
				currentX += failedButtonSize.width
				currentX += horizontalInterspacing
			} else {
				self.failedViewFrame.origin.x = -failedButtonSize.width
			}
			self.bubbleViewFrame.origin.x = currentX
		} else {
			currentX = containerRect.maxX - horizontalMargin
			currentX -= avatarSize.width
			self.avatarViewFrame.origin.x = currentX
			currentX -= horizontalInterspacing
			if isFailed {
				currentX -= failedButtonSize.width
				self.failedViewFrame.origin.x = currentX
				currentX -= horizontalInterspacing
			} else {
				self.failedViewFrame.origin.x = containerRect.width - -failedButtonSize.width
			}
			currentX -= bubbleSize.width
			self.bubbleViewFrame.origin.x = currentX
		}
		
		self.size = containerRect.size
		self.preferredMaxWidthForBubble = preferredWidthForBubble
	}
}

struct BaseMessageLayoutModelParameters {
	let containerWidth: CGFloat
	let horizontalMargin: CGFloat
	let horizontalInterspacing: CGFloat
	let failedButtonSize: CGSize
	let maxContainerWidthPercentageForBubbleView: CGFloat // in [0, 1]
	let bubbleView: UIView
	let isIncoming: Bool
	let isFailed: Bool
	let avatarSize: CGSize
	let avatarVerticalAlignment: VerticalAlignment
}
