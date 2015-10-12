//
//  DelegateProxy.swift
//  tiled
//
//  Created by Benjamin de Jager on 12/10/15.
//  Copyright © 2015 Benjamin de Jager. All rights reserved.
//

import UIKit

class DelegateProxy: NSObject, UIScrollViewDelegate {
  weak var userDelegate: UIScrollViewDelegate?
  
  override func respondsToSelector(aSelector: Selector) -> Bool {
    return super.respondsToSelector(aSelector) || userDelegate?.respondsToSelector(aSelector) == true
  }
  
  override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
    if userDelegate?.respondsToSelector(aSelector) == true {
      return userDelegate
    }
    else {
      return super.forwardingTargetForSelector(aSelector)
    }
  }
  
  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    guard let scrollView = scrollView as? TilingScrollView else { return nil }
    return scrollView.viewForZoomingInScrollView(scrollView)
  }

  func scrollViewDidScroll(scrollView: UIScrollView) {
//    scrollView.didScroll()
//    _userDelegate?.scrollViewDidScroll?(scrollView)
  }

}
