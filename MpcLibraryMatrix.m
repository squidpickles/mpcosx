/*
MpcOSX
Copyright 2005-2007 Kevin Dorne

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "MpcLibraryMatrix.h"
#import "MpcWindowController.h"

#define NO_SELECTION -1
#define NO_MODIFIERS(x) (! (x & NSCommandKeyMask || x & NSShiftKeyMask))


@implementation MpcLibraryMatrix

-(NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
  return NSDragOperationCopy;
}

- (void)mouseDown:(NSEvent *)event
{
  int row, col;
  int startPos;
  int flags;
  BOOL rowIsSelected;
  
  if ([self getRow: &row column: &col
          forPoint:[self convertPoint:[event locationInWindow] 
                             fromView: nil]]) {
    startPos = row;
    
    if ([self selectedRow] < 0)
      anchor = NO_SELECTION;
    
    flags = [event modifierFlags];
    
    if (NO_SELECTION == anchor || 
        flags & NSCommandKeyMask)
      anchor = row;
    
    if (flags & NSShiftKeyMask)
      startPos = anchor;
    
    rowIsSelected = ([[self selectedCells] containsObject:[self cellAtRow:row column:0]]);
    
    if (rowIsSelected)
    {
      // Do nothing if no modifiers
      if (NO_MODIFIERS(flags))
        return;
      // Otherwise, deselect the current cell
      [self setSelectionFrom:row to:row anchor:row highlight:NO];
      [self deselectSelectedCell];
    }
    // If no modifiers are pressed and the cell isn't selected,
    // deselect all of the cells
    else
    {
      if (NO_MODIFIERS(flags))
      {
        [self deselectAllCells];
        anchor = row;
      }
      // Finally, add the row to the selection
      [self setSelectionFrom:startPos to:row anchor:anchor highlight:YES];
    }
    // And update the browser
    [self sendAction];
    anchor = row;
  }

}

-(BOOL)acceptsFirstResponder
{
  return YES;
}

-(NSString *)tabularPlaylistAdditions:(MpcWindowController *)windowController
{
  NSArray *tracks;
  NSString *table;
  
  // Oh my, this is a brutally ugly hack!
  tracks = [windowController selectedLibraryTracks];
  table = [tracks componentsJoinedByString:@"\t"];
  return table;
}

-(void)mouseDragged:(NSEvent *)event
{
  NSPasteboard *pboard;
  NSImage *dragImage;
  id wc;
  
  wc = [[event window] windowController];
  pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
  dragImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"dragImage.png"]];
  [pboard declareTypes:[NSArray arrayWithObject:NSTabularTextPboardType] owner:nil];
  [pboard setData:[[NSString stringWithString:[self tabularPlaylistAdditions:wc]] dataUsingEncoding:NSUTF8StringEncoding] forType:NSTabularTextPboardType];
  [dragImage lockFocus];
  [dragImage dissolveToPoint:NSZeroPoint fraction:.3];
  [dragImage unlockFocus];
  [self dragImage: dragImage
               at: [self convertPoint:[event locationInWindow] 
                            fromView: nil]
           offset: NSZeroSize
            event:event
       pasteboard:pboard
           source:self
        slideBack:YES];
  [dragImage release];
}

@end
