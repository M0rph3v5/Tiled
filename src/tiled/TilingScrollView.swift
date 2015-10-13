//
//  TilingScrollView.swift
//  tiledviewer
//
//  Created by Benjamin de Jager on 12/5/14.
//  Copyright (c) 2014 Q42. All rights reserved.
//

import UIKit

public protocol TilingScrollViewDataSource {
  func tilingScrollView(tilingScrollView: TilingScrollView, imageForColumn column: Int, andRow row: Int, forScale scale: CGFloat) -> UIImage?
  func numberOfDetailLevelsInTilingScrollView(tilingScrollView: TilingScrollView) -> Int
  func fullSizeOfImageInTilingScrollView(tilingScrollView: TilingScrollView) -> CGSize
  func sizeOfTilesInTilingScrollView(tilingScrollView: TilingScrollView) -> CGSize
}

public class TilingScrollView: UIScrollView, UIScrollViewDelegate, TilingViewDataSource {
  
  private var pointToCenterAfterResize: CGPoint!
  private var scaleToRestoreAfterResize: CGFloat!
  
  private var delegateProxy = DelegateProxy()
  private var tilingView: TilingView! // actual tiling view
  
//  override var delegate: UIScrollViewDelegate? {
//    get {
//      return delegateProxy.userDelegate
//    }
//    set {
//      delegateProxy.userDelegate = newValue;
//    }
//  }
  
  public var dataSource: TilingScrollViewDataSource? {
    didSet {
      guard let d = dataSource else { return }
      tileSize = d.sizeOfTilesInTilingScrollView(self)
      levelsOfDetail = d.numberOfDetailLevelsInTilingScrollView(self)
      imageSize = d.fullSizeOfImageInTilingScrollView(self)
    }
  }
  
  private var tileSize: CGSize = CGSizeZero {
    didSet {
      tilingView.tileSize = tileSize
    }
  }
  private var levelsOfDetail: Int = 0 {
    didSet {
      tilingView.levelsOfDetail = levelsOfDetail
    }
  }
  private var imageSize: CGSize! {
    didSet {
      zoomScale = 1
      
      imageView.frame.size = imageSize
      tilingView.frame = imageView.bounds
      contentSize = tilingView.frame.size
      setMaxMinZoomScalesForCurrentBounds()
      if fillMode {
        centerAnimated(true, horizontalOnly: false)
      }
    }
  }
  
  public var imageView: TilingImageView! // hold thumbnail
  
  var fillMode: Bool = false
  var widthIsCropped: Bool = false
  
  var tilingEnabled: Bool = true {
    didSet {
      tilingView.hidden = !tilingEnabled
    }
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }
  
  func initialize() {
    delegate = self
    
    imageView = TilingImageView(frame: bounds);
    addSubview(imageView)
    
    tilingView = TilingView(frame: bounds);
    tilingView.dataSource = self
    imageView.addSubview(tilingView)
  }
  
  // MARK: Actions

  func setMaxMinZoomScalesForCurrentBounds() {
    let tilingViewSize = tilingView.bounds.size

    let boundsSize = bounds.size
    
    let xScale = boundsSize.width / tilingViewSize.width
    let yScale = boundsSize.height / tilingViewSize.height
    
    // TODO: make retina limit an option
    let maxScale = 1.0 / UIScreen.mainScreen().scale
    var minScale = min(xScale, yScale)
    if minScale > maxScale {
      minScale = maxScale
    }
    
    maximumZoomScale = maxScale
    minimumZoomScale = minScale
    
    if fillMode {
      zoomScale = max(xScale, yScale)
      widthIsCropped = zoomScale == yScale
    } else {
      zoomScale = minimumZoomScale
    }
  }
  
  func centerAnimated(animated: Bool, horizontalOnly: Bool) {
    setContentOffset(CGPoint(
      x: contentSize.width/2 - frame.width/2,
      y: horizontalOnly ? contentOffset.y : contentSize.height/2 - frame.height/2), animated: animated)
  }
  
  func zoomToRect(zoomRect: CGRect, zoomOutWhenZoomedIn:Bool, animated: Bool) {
    guard tilingView.bounds.intersects(zoomRect) else { return }
      
    let zoomScaleX = (bounds.size.width - contentInset.left - contentInset.right) / zoomRect.size.width
    let zoomScaleY = (bounds.size.height - contentInset.top - contentInset.bottom) / zoomRect.size.height
    let zoomScale = min(maximumZoomScale, min(zoomScaleX, zoomScaleY))

    if !zoomOutWhenZoomedIn || fabs(zoomScale - zoomScale) > fabs(zoomScale - minimumZoomScale) {
      zoomToRect(zoomRect, animated: true)
    } else {
      setZoomScale(minimumZoomScale, animated: true)
    }
  }
  
  // MARK: rotation support methods
  
  func prepareToResize() {
    let boundsCenter = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
    pointToCenterAfterResize = convertPoint(boundsCenter, toView: imageView)
    scaleToRestoreAfterResize = zoomScale
    
    if scaleToRestoreAfterResize <= (minimumZoomScale + CGFloat(FLT_EPSILON)) {
      scaleToRestoreAfterResize = 0
    }
  }
  
  func recoverFromResizing() {
    setMaxMinZoomScalesForCurrentBounds()
    
    let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
    let zoomScale = min(maximumZoomScale, maxZoomScale)
    self.zoomScale = zoomScale
    
    let boundsCenter = convertPoint(pointToCenterAfterResize, toView: imageView)
    var offset = CGPoint(
      x: boundsCenter.x - bounds.size.width / 2.0,
      y: boundsCenter.y - bounds.size.height / 2.0)
    
    let maxOffset = maximumContentOffset()
    let minOffset = minimumContentOffset()
    
    var realMaxOffset = min(maxOffset.x, offset.x)
    offset.x = max(minOffset.x, realMaxOffset)
    
    realMaxOffset = min(maxOffset.y, offset.y)
    offset.y = max(minOffset.y, realMaxOffset)
  }
  
  func maximumContentOffset() -> CGPoint {
    let contentSize = self.contentSize
    let boundsSize = bounds.size;
    return CGPoint(x: contentSize.width - boundsSize.width, y: contentSize.height - boundsSize.height);
  }
  
  func minimumContentOffset() -> CGPoint {
    return CGPoint.zero;
  }
  
  // MARK: scrollview delegate methods
  public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  public func scrollViewDidZoom(scrollView: UIScrollView) {
    
    var top:CGFloat = 0, left:CGFloat = 0
    if (contentSize.width < bounds.size.width) {
      left = (bounds.size.width-contentSize.width) * 0.5
    }
    if (contentSize.height < bounds.size.height) {
      top = (bounds.size.height-contentSize.height) * 0.5
    }

    contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
  }
  
  override public var bounds: CGRect {
    willSet {
      if newValue.size != bounds.size {
        prepareToResize()
      }
    }
    
    didSet {
      if oldValue.size != bounds.size {
        recoverFromResizing()
      }
    }
  }

  // MARK: tilingview data source
  
  public func tilingView(tilingView: TilingView, imageForColumn column: Int, andRow row: Int, forScale scale: CGFloat) -> UIImage? {
    return dataSource?.tilingScrollView(self, imageForColumn: column, andRow: row, forScale: scale)
  }
}
