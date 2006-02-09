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

#import "MpcPlaylist.h"
#import "MpcSong.h"
#import "MpcServer.h"

@implementation MpcPlaylist
{

unsigned long playlistId;
BOOL updated;
NSMutableArray *list;

}

-(id)init
{
  [super init];
  list = [[NSMutableArray alloc] init];
  playlistId = -1;
  updated = TRUE;
  return self;
}

-(void)clear
{
  [list removeAllObjects];
  updated = TRUE;
}

-(void)setPlaylistId:(unsigned long)id
{
  playlistId = id;
}

-(unsigned long)playlistId
{
  return playlistId;
}

-(void)incrementPlaylistId
{
  playlistId++;
}

-(unsigned)count
{
  return [list count];
}

-(id)getSong:(int)index
{
  return [list objectAtIndex:index];
}

-(void)addSong:(id)song
{
  [list addObject:song];
  updated = TRUE;
}

-(int)getIndex:(id)song
{
  return [list indexOfObject:song];
}

-(void)removeLastSong
{
  [list removeLastObject];
  updated = TRUE;
}

-(void)replaceSongAt:(int)plpos withSong:(id)song
{
  [list replaceObjectAtIndex:plpos withObject:song];
  updated = TRUE;
}

-(int)numberOfRowsInTableView:(NSTableView *)tableView
{
  return [self count];
}

-(id)list
{
  return list;
}

-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  id song = [self getSong:rowIndex];
  id ident = [aTableColumn identifier];
  if ([ident isEqualToString:TIME])
    return [song formattedLength];
  if ([ident isEqualToString:TITLE])
    return [song title];
  if ([ident isEqualToString:ARTIST])
    return [song artist];
  if ([ident isEqualToString:ALBUM])
    return [song album];
  if ([ident isEqualToString:NUM])
    return [NSNumber numberWithInt:(1+[song plpos])];
  if ([ident isEqualToString:SONG])
    return [NSString stringWithFormat:SONG_FMT, [song title], [song artist]];
  NSLog(@"Unknown identifier: %@", ident);
  return [NSString stringWithString:@"???"];
}

-(NSDragOperation) tableView: (NSTableView *) view validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) operation
{
  [view setDropRow:[view numberOfRows] dropOperation:NSTableViewDropAbove];
  return operation;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
  NSPasteboard *pboard;
  NSString *dropData;
  NSArray *tracksToAdd;
  MpcServer *server;
  
  pboard = [info draggingPasteboard];
  dropData = [pboard stringForType:PBOARD_TYPE];
  
  if (row > [self count])
    return NO;
  
  if (nil == [info draggingSource])
  {
    // It's from another app
    NSLog(@"Got (unusable) data from another app: %@", dropData); //dbug
    return NO;
  }
  else if (tableView == [info draggingSource])
  {
    // It's from our self.  We don't want that right now.
    // Some day we'll be able to reorder items
    NSLog(@"Got (unusable) data from ourselves: %@", dropData); //dbug
    return NO; // TODO
  }
  else
  {
    tracksToAdd = [dropData componentsSeparatedByString:@"\t"];
    server = [MpcServer sharedInstance];
    [server addPaths:tracksToAdd];
    return YES;
  }
}


-(void)dealloc
{
  [list release];
  list = nil;
  [super dealloc];
}

@end
