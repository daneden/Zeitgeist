//
//  Created by https://quickplan.app on 2020/11/8.
//

import SwiftUI

/// Control if allow to dismiss the sheet by the user actions
/// - Drag down on the sheet on iPhone and iPad
/// - Tap outside the sheet on iPad
/// No impact to dismiss programatically (by calling "presentationMode.wrappedValue.dismiss()")
/// -----------------
/// Tested on iOS 14.2 with Xcode 12.2 RC
/// This solution may NOT work in the furture.
/// -----------------
#if os(iOS)
struct MbModalHackView: UIViewControllerRepresentable {
  var dismissable: () -> Bool = { false }
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<MbModalHackView>) -> UIViewController {
    MbModalViewController(dismissable: self.dismissable)
  }
  
  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    
  }
}

extension MbModalHackView {
  private final class MbModalViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    let dismissable: () -> Bool
    
    init(dismissable: @escaping () -> Bool) {
      self.dismissable = dismissable
      super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(toParent parent: UIViewController?) {
      super.didMove(toParent: parent)
      
      setup()
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
      dismissable()
    }
    
    // set delegate to the presentation of the root parent
    private func setup() {
      guard let rootPresentationViewController = self.rootParent.presentationController,
            rootPresentationViewController.delegate == nil else { return }
      rootPresentationViewController.delegate = self
    }
  }
}

extension UIViewController {
  fileprivate var rootParent: UIViewController {
    if let parent = self.parent {
      return parent.rootParent
    } else {
      return self
    }
  }
}

/// make the call the SwiftUI style:
/// view.allowAutDismiss(...)
extension View {
  /// Control if allow to dismiss the sheet by the user actions
  public func allowAutoDismiss(_ dismissable: @escaping () -> Bool) -> some View {
    self
      .background(MbModalHackView(dismissable: dismissable))
  }
  
  /// Control if allow to dismiss the sheet by the user actions
  public func allowAutoDismiss(_ dismissable: Bool) -> some View {
    self
      .background(MbModalHackView(dismissable: { dismissable }))
  }
}
#else
extension View {
  /// Control if allow to dismiss the sheet by the user actions
  public func allowAutoDismiss(_ dismissable: @escaping () -> Bool) -> some View {
    self.frame(width: 300)
  }
  
  /// Control if allow to dismiss the sheet by the user actions
  public func allowAutoDismiss(_ dismissable: Bool) -> some View {
    self.frame(width: 300)
  }
}
#endif
