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
#import "libmpdclient.h"
#import "MpcStatus.h"
#import "MpcSong.h"
#import "MpcPlaylist.h"
#import "MpcLibrary.h"

#define DB_ROOT "/"

@interface MpcServer : NSObject {
  mpd_Connection *conn;
  MpcStatus *status;
  MpcSong *currSong;
  MpcPlaylist *currPlaylist;
  MpcLibrary *library;
}
+(id)sharedInstance;
-(int)finishCmd;
-(int)finishCmdList;
-(void)disconnect;
-(int)connect:(NSString *)host:(int)port:(float)timeout:(NSString *)password;
-(BOOL)isConnected;
-(int)update;
-(int)playSong:(MpcSong *)song;
-(int)playSongId:(unsigned long)songId;
-(int)removeSongs:(NSArray *)songs;
-(int)pause:(BOOL)mode;
-(int)stop;
-(int)next;
-(int)prev;
-(int)seek:(int)songid:(int)pos;
-(int)shuffle;
-(int)clearPlaylist;
-(int)repeat:(BOOL)mode;
-(int)random:(BOOL)mode;
-(int)crossfade:(int)seconds;
-(int)updateDb;
-(int)setVolume:(int)value;
-(int)addSong:(MpcSong *)song;
-(int)addPaths:(NSArray *)paths;
-(int)updatePlaylist;
-(int)updatePlaylistChanges;
-(int)deletePlaylist:(NSString *)name;
-(int)savePlaylist:(NSString *)name;
-(int)getLibrary;
-(id)song;
-(id)playlist;
-(id)library;
-(id)status;
@end
