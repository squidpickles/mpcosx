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

#import "MpcPlaylistListController.h"

@implementation MpcPlaylistListController

- (void)remove:(id)sender
{
  NSArray *selected;
  NSEnumerator *objEnum;
  id obj;
  
  selected = [super selectedObjects];
  objEnum = [selected objectEnumerator];
  while (obj = [objEnum nextObject])
  {
    [windowController deletePlaylist:obj];
  }
}

@end
