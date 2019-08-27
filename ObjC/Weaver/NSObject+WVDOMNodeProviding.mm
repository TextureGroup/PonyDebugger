//
//  NSObject+WVDOMNodeProviding.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Weaver/NSObject+WVDOMNodeProviding.h>

#import <Weaver/WVDOMContext.h>

#import <Weaver/PDDOMTypes.h>

#import <Texture/Texture.h>

#import <queue>

// Constants defined in the DOM Level 2 Core: http://www.w3.org/TR/DOM-Level-2-Core/core.html#ID-1950641247
static const int kPDDOMNodeTypeElement = 1;

#pragma mark PDDOMNodeProviding

@interface NSObject (TDDOMNodeGenerating)

+ (nonnull NSString *)wv_nodeName;

@end

@implementation NSObject (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"object";
}

- (PDDOMNode *)wv_generateDOMNodeWithContext:(WVDOMContext *)context
{
  NSNumber *nodeId = [context storeObject:self];
  [context setRect:[self wv_frameInWindow] forKey:nodeId];
  
  PDDOMNode *node = [[PDDOMNode alloc] init];
  node.nodeType = @(kPDDOMNodeTypeElement);
  node.nodeId = nodeId;
  node.nodeName = [[self class] wv_nodeName];
  node.attributes = @[ @"description", self.debugDescription ];

  NSMutableArray *nodeChildren = [NSMutableArray array];
  for (id child in [self wv_children]) {
    [nodeChildren addObject:[child wv_generateDOMNodeWithContext:context]];
  }
  node.children = nodeChildren;
  node.childNodeCount = @(nodeChildren.count);
  
  return node;
}

- (CGRect)wv_frameInWindow
{
  return CGRectNull;
}

- (NSArray *)wv_children
{
  return @[];
}

@end

@implementation UIApplication (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"application";
}

- (NSArray *)wv_children
{
  return self.windows;
}

@end

@implementation CALayer (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"layer";
}

- (PDDOMNode *)wv_generateDOMNodeWithContext:(WVDOMContext *)context
{
  // For backing store of a display node (view/layer), let the node handle this job
  ASDisplayNode *displayNode = ASLayerToDisplayNode(self);
  if (displayNode) {
    return [displayNode wv_generateDOMNodeWithContext:context];
  }
  
  return [super wv_generateDOMNodeWithContext:context];
}

- (CGRect)wv_frameInWindow
{
  CALayer *rootLayer = self;
  CALayer *nextLayer = nil;
  while ((nextLayer = rootLayer.superlayer) != nil) {
    rootLayer = nextLayer;
  }
  
  return [self convertRect:self.bounds toLayer:rootLayer];
}

- (NSArray *)wv_children
{
  return self.sublayers;
}

@end

@implementation UIView (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"view";
}

- (PDDOMNode *)wv_generateDOMNodeWithContext:(WVDOMContext *)context
{
  // For backing store of a display node (view/layer), let the node handle this job
  ASDisplayNode *displayNode = ASViewToDisplayNode(self);
  if (displayNode) {
    return [displayNode wv_generateDOMNodeWithContext:context];
  }
  
  return [super wv_generateDOMNodeWithContext:context];
}

- (CGRect)wv_frameInWindow
{
  return [self convertRect:self.bounds toView:nil];
}

- (NSArray *)wv_children
{
  return self.subviews;
}

@end

@implementation UIWindow (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"window";
}

@end

@implementation ASLayoutSpec (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"layout-spec";
}

@end

@implementation ASDisplayNode (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"display-node";
}

/**
 * ASDisplayNode by default generates its DOM children from its calculated layout (@see -[ASDisplayNode wv_generateDOMNodeWithContext] below).
 * Subclasses whose calculated layout doesn't include all children, for example because it does manual layout
 * or it is a container node like ASCollectionNode and ASTableNode, can override this method to return the valid children.
 * -[ASDisplayNode wv_generateDOMNodeWithContext:] will respect that and bail early.
 */
// TODO Consider refactoring wv_children and wv_generateDOMNodeWithContext in this class
- (NSArray *)wv_children
{
  // If this node doesn't have calculated sublayouts but instead have some subnodes,
  // it is a container node, i.e the root node of an ASViewController
  // Handle by returning subnodes and by pass -[ASDisplayNode wv_generateDOMNodeWithContext:]
  if (self.unflattenedCalculatedLayout.sublayouts.count == 0 && self.subnodes.count > 0) {
    return self.subnodes;
  }

  // Return an empty array in most cases so that -[ASDisplayNode wv_generateDOMNodeWithContext:] will pickup unflattenedCalculatedLayout.
  return @[];
}

- (PDDOMNode *)wv_generateDOMNodeWithContext:(WVDOMContext *)context
{
  PDDOMNode *rootNode = [super wv_generateDOMNodeWithContext:context];
  if (rootNode.childNodeCount.intValue > 0) {
    // If rootNode.children was populated, return right away. Check the concrete implementation of -wv_children.
    return rootNode;
  }
  
  /*
   * The rest of this method does 2 things:
   * - Generate the rest of the DOM tree:
   *      ASDisplayNode has a different way to generate DOM children.
   *      That is, from an unflattened layout, a DOM child is generated from the layout element of each sublayout in the layout tree.
   *      In addition, since non-display-node layout elements (e.g layout specs) don't (and shouldn't) store their calculated layout,
   *      they can't generate their own DOM children. So it's the responsibility of the root display node to fill out the gaps.
   * - Calculate the frame in window of some layout elements in the layout tree:
   *      Non-display-node layout elements can't determine their own frame because they don't have a backing store.
   *      Thus, it's also the responsibility of the root display node to calculate and keep track of the frame of each child
   *      and assign to it if need to.
   */
  struct Context {
    PDDOMNode *node;
    ASLayout *layout;
    CGRect frameInWindow;
  };
  
  // Queue used to keep track of sublayouts while traversing this layout in BFS frashion.
  std::queue<Context> queue;
  queue.push({rootNode, self.unflattenedCalculatedLayout, self.wv_frameInWindow});
  
  while (!queue.empty()) {
    Context queueContext = queue.front();
    queue.pop();
    
    ASLayout *layout = queueContext.layout;
    NSArray<ASLayout *> *sublayouts = layout.sublayouts;
    PDDOMNode *node = queueContext.node;
    NSMutableArray<PDDOMNode *> *children = [NSMutableArray arrayWithCapacity:sublayouts.count];
    CGRect frameInWindow = queueContext.frameInWindow;
    
    for (ASLayout *sublayout in sublayouts) {
      NSObject<ASLayoutElement> *sublayoutElement = sublayout.layoutElement;
      PDDOMNode *subnode = [sublayoutElement wv_generateDOMNodeWithContext:context];
      [children addObject:subnode];
      
      // Non-display-node (sub)elements can't generate their own DOM children and frame in window
      // We calculate the frame and assign to those now
      // We add them to the queue to generate their DOM children later
      if ([sublayout.layoutElement isKindOfClass:[ASDisplayNode class]] == NO) {
        CGRect sublayoutElementFrameInWindow = CGRectNull;
        if (! CGRectIsNull(frameInWindow)) {
          sublayoutElementFrameInWindow = CGRectMake(frameInWindow.origin.x + sublayout.position.x,
                                                     frameInWindow.origin.y + sublayout.position.y,
                                                     sublayout.size.width,
                                                     sublayout.size.height);
        }
        [context setRect:sublayoutElementFrameInWindow forKey:subnode.nodeId];
        
        queue.push({subnode, sublayout, sublayoutElementFrameInWindow});
      }
    }
    
    node.children = children;
    node.childNodeCount = @(children.count);
  }

  return rootNode;
}

- (CGRect)wv_frameInWindow
{
  if (self.isNodeLoaded == NO || self.isInHierarchy == NO) {
    return CGRectNull;
  }
  
  if (self.layerBacked) {
    return self.layer.wv_frameInWindow;
  } else {
    return self.view.wv_frameInWindow;
  }
}

@end

@implementation ASCellNode (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"cell-node";
}

- (NSArray *)wv_children
{
  if (UIViewController *viewController = self.viewController) {
    // ASCellNodes with a view controller block have only 1 subnode that is the view controller's node.
    // Since the subnode is manually laid out, the calculated layout of this cell node has no sublayout
    // and thus can't be used in -[ASDisplayNode wv_generateDOMNodeWithContext].
    // Therefore, `self.subnodes` should be returned here.
    return self.subnodes;
  } else {
    // Opt into the default behavior of ASDisplayNode.
    return [super wv_children];
  }
}

@end

@implementation ASCollectionNode (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"collection-node";
}

- (NSArray *)wv_children
{
  // Only show visible nodes for now. This requires user to refresh the browser to update the DOM.
  return self.visibleNodes;
}

@end

@implementation ASTableNode (PDDOMNodeProviding)

+ (NSString *)wv_nodeName
{
  return @"table-node";
}

- (NSArray *)wv_children
{
  // Only show visible nodes for now. This requires user to refresh the browser to update the DOM.
  return self.visibleNodes;
}

@end
