//
//  Copyright © FINN.no AS, Inc. All rights reserved.
//

import UIKit

open class BottomSheetNavigationController: UINavigationController {
    private var bottomSheetTransitioningDelegate: BottomSheetTransitioningDelegate?
    private lazy var initialViewSize = view.frame.size

    // MARK: - Init

    public init(
        rootViewController: UIViewController,
        handleBackground: BottomSheetView.HandleBackground = .color(.clear),
        draggableHeight: CGFloat? = nil,
        useSafeAreaInsets: Bool = false,
        stretchOnResize: Bool = false
    ) {
        super.init(rootViewController: rootViewController)
        bottomSheetTransitioningDelegate = BottomSheetTransitioningDelegate(
            contentHeights: [systemLayoutSizeFittingHeight(for: rootViewController)],
            handleBackground: handleBackground,
            draggableHeight: draggableHeight,
            useSafeAreaInsets: useSafeAreaInsets,
            stretchOnResize: stretchOnResize
        )
        transitioningDelegate = bottomSheetTransitioningDelegate
        modalPresentationStyle = .custom
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - View lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    // MARK: - Public

    public func systemLayoutSizeFittingHeight(for viewController: UIViewController) -> CGFloat {
        let navigationBarHeight = navigationBar.isTranslucent || navigationBar.isHidden ? 0 : navigationBar.frame.size.height
        let height = viewController.view.systemLayoutHeightFitting(initialViewSize)
        return height + navigationBarHeight
    }

    public func reload(with height: CGFloat) {
        bottomSheetTransitioningDelegate?.reload(with: [height])
    }
}

// MARK: - UINavigationControllerDelegate

extension BottomSheetNavigationController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController, animated: Bool
    ) {
        let height = systemLayoutSizeFittingHeight(for: viewController)
        reload(with: height)
    }
}
