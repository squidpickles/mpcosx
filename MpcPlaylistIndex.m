/*
MpcOSX
Copyright 2005-2006 Kevin Dorne

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

#import "MpcPlaylistIndex.h"


@implementation MpcPlaylistIndex
{
  NSArray *playlists;
}

-(id)initWithArray:(NSArray *)lists
{
  [super init];
  playlists = [[NSArray alloc] initWithArray:lists];
  return self;
}

-(void)replaceWithArray:(NSArray *)lists
{
  [playlists release];
  playlists = [[NSArray alloc] initWithArray:lists];
}
  

-(NSString *)playlistAtIndex:(int)index
{
  switch (index) {
    case 0:
      return [NSString stringWithString:CURRENT_LIST];
      break;
    default:
      index -= NUM_SPECIAL_LISTS;
      return [playlists objectAtIndex:index];
  }
}

-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  return [self playlistAtIndex:rowIndex];
}

-(int)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [playlists count] + NUM_SPECIAL_LISTS;
}


-(void)dealloc
{
  [playlists release];
  playlists = nil;
  [super dealloc];
}

@end
