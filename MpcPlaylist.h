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

#import <Cocoa/Cocoa.h>

#define NUM @"Num"
#define SONG @"Song"
#define TIME @"Time"
#define TITLE @"Title"
#define ALBUM @"Album"
#define ARTIST @"Artist"
#define SONG_FMT @"%@ / %@"
#define PBOARD_TYPE NSTabularTextPboardType

@interface MpcPlaylist : NSMutableArray {
  
  unsigned long playlistId;
  BOOL updated;
  NSMutableArray *list;

}
-(void)setPlaylistId:(unsigned long)id;
-(unsigned long)playlistId;
-(unsigned)count;
-(void)incrementPlaylistId;
-(id)getSong:(int)index;
-(void)addSong:(id)song;
-(void)clear;
-(void)removeLastSong;
-(int)getIndex:(id)song;
-(id)list;
-(void)replaceSongAt:(int)plpos withSong:(id)song;
-(int)numberOfRowsInTableView:(NSTableView *)tableView;
-(id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
-(NSDragOperation) tableView: (NSTableView *) view validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) operation;
-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation;
@end
