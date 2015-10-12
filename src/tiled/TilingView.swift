//
//  TilingView.swift
//  tiledviewer
//
//  Created by Benjamin de Jager on 12/5/14.
//  Copyright (c) 2014 Q42. All rights reserved.
//

import UIKit
import QuartzCore

protocol TilingViewDataSource {
  func tilingView(tilingView: TilingView, imageForColumn column: Int, andRow row: Int, forScale scale: CGFloat) -> UIImage?
}

class TilingView: UIView {
  
  var dataSource : TilingViewDataSource!
  var levelsOfDetail : Int = 0 {
    didSet {
      let tiledLayer = self.layer as! CATiledLayer
      tiledLayer.levelsOfDetail = levelsOfDetail
    }
  }
  var tileSize : CGSize = CGSizeZero {
    didSet {
      let tiledLayer = self.layer as! CATiledLayer
      tiledLayer.tileSize = tileSize
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.backgroundColor = UIColor.clearColor()
  }
  
  // MARK: overrides
  
  override func drawRect(rect: CGRect) {
    
    let context = UIGraphicsGetCurrentContext()
    
    let tiledLayer = self.layer as! CATiledLayer
    var tileSize = tiledLayer.tileSize
    
    // Even at scales lower than 100%, we are drawing into a rect in the coordinate system
    // of the full image. One tile at 50% covers the width (in original image coordinates)
    // of two tiles at 100%. So at 50% we need to stretch our tiles to double the width
    // and height; at 25% we need to stretch them to quadruple the width and height; and so on.
    // (Note that this means that we are drawing very blurry images as the scale gets low.
    // At 12.5%, our lowest scale, we are stretching about 6 small tiles to fill the entire
    // original image area. But this is okay, because the big blurry image we're drawing
    // here will be scaled way down before it is displayed.)
    
    let contextTransform = CGContextGetCTM(context)
    let scaleX = contextTransform.a
    let scaleY = contextTransform.d
    
    tileSize.width /= scaleX
    tileSize.height /= -scaleY
    
    // calculate the rows and columns of tiles that intersect the rect we have been asked to draw
    let firstCol = Int(floorf(Float(CGRectGetMinX(rect) / tileSize.width)))
    let lastCol = Int(floorf(Float(CGRectGetMaxX(rect) / tileSize.width)))
    let firstRow = Int(floorf(Float(CGRectGetMinY(rect) / tileSize.height)))
    let lastRow = Int(floorf(Float(CGRectGetMaxY(rect) / tileSize.height)))
    
    for row in firstRow...lastRow {
      for col in firstCol...lastCol {
        var tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row),
                              width: tileSize.width, height: tileSize.height)

        // if the tile would stick outside of our bounds, we need to truncate it so as
        // to avoid stretching out the partial tiles at the right and bottom edges
        tileRect = CGRectIntersection(self.bounds, tileRect)
        if let tile = dataSource.tilingView(self, imageForColumn: col, andRow: row, forScale: scaleX) {
          tile.drawInRect(tileRect)
        }
      }
    }
    
  }
  
  override class func layerClass() -> AnyClass {
    return CATiledLayer.self
  }
  
  override var contentScaleFactor : CGFloat {
    didSet {
      super.contentScaleFactor = 1
    }
  }
  
}
