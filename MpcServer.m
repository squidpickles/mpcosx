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

#import "MpcServer.h"

#define MPD_ERROR(conn) (conn==nil || conn->error)
#define MPD_CONNECTION_ERROR conn->error == MPD_ERROR_TIMEOUT || \
                             conn->error == MPD_ERROR_NOTMPD || \
                             conn->error == MPD_ERROR_NORESPONSE || \
                             conn->error == MPD_ERROR_CONNCLOSED
#define ERROR -1
#define MAX_ERROR 512
#define MIN_ERROR -512

@implementation MpcServer
{
  mpd_Connection *conn;
  MpcStatus *status;
  MpcSong *currSong;
  MpcPlaylist *currPlaylist;
  MpcLibrary *library;
}

static MpcServer *sharedInstance = nil;

-(id)init
{
  if (sharedInstance)
  {
    [self autorelease];
    self = [sharedInstance retain];
  }
  else
  {
    self = [super init];
    if (self)
    {
      sharedInstance = [self retain];
    }
  }
  return self;
}

+(id)sharedInstance
{
  if (nil == sharedInstance)
    sharedInstance = [[self alloc] init];
  return sharedInstance;
}

-(int)finishCmd
{
  int error = 0;
  
  mpd_finishCommand(conn);
  error = conn->error;
  if (error)
  {
    if (error < MAX_ERROR && error > MIN_ERROR)
    {
      NSLog(@"Error: %s (#%d)", conn->errorStr, error);
    }
    else
    {
      NSLog(@"Server sent unreadable error code");
    }

    if (MPD_CONNECTION_ERROR)
      [self disconnect];
  }
  return error;
}

-(int)finishCmdList
{
  mpd_sendCommandListEnd(conn);
  return [self finishCmd];
}

-(void)disconnect
{
  if (conn)
    mpd_closeConnection(conn);
  conn = nil;
  
  [currPlaylist release];
  [library release];
  [status release];
  [currSong release];
  currPlaylist = nil;
  library = nil;
  status = nil;
  currSong = nil;
}

-(int)connect:(NSString *)host:(int)port:(float)timeout:(NSString *)password;
{
  int error;
  
  status = [[MpcStatus alloc] init];
  currSong = [[MpcSong alloc] init];
  currPlaylist = [[MpcPlaylist alloc] init];
  library = [[MpcLibrary alloc] init];
  
  if (conn)
    [self disconnect];
  
  conn = mpd_newConnection([host cString], port, timeout);
  error = conn->error;
  if (error)
  {
    [self disconnect];
    return error;
  }
 
  if (nil != password && [password length] > 0)
  {
    mpd_sendPasswordCommand(conn,[password cString]);
    error = [self finishCmd];
  }
  
  return error;
}

-(BOOL)isConnected
{
  return (nil != conn);
}

-(int)update
{
  int retval = 0;
  mpd_Status *stat;
  
  if (MPD_ERROR(conn))
    return ERROR;
  
  mpd_sendStatusCommand(conn);
  
  stat = mpd_getStatus(conn);
  if (stat)
  {
    [status setStatus:stat];
    mpd_freeStatus(stat);
  }
  
  if (retval = [self finishCmd])
    return retval;
  // Did the current playlist change?
  if (!currPlaylist)
  {
    retval = [self updatePlaylist];
  }
  else if ([currPlaylist playlistId] != [status playlist])
  {
    retval = [self updatePlaylistChanges];
  }
  
  // Did the current song change?
  if ([currPlaylist count] != 0 && (!currSong || [status songid] !=[currSong songid]))
    currSong = [[currPlaylist getSong:[status song]] retain];
  
  // Did the library get updated?
  if ([status updatingDb])
    [library setNeedsUpdate];

  return [self finishCmd];
}

-(int)playSong:(MpcSong *)song
{
  if (song && [song songid] > 0)
  {
    return [self playSongId:[song songid]];
  }
  else
  {
    return [self playSongId:MPD_PLAY_AT_BEGINNING];
  }
}

-(int)playSongId:(unsigned long)songId
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendPlayIdCommand(conn, songId);
  return [self finishCmd];
}

-(int)removeSongs:(NSArray *)songs
{
  NSEnumerator *songEnum;
  MpcSong *song;
  
  if (MPD_ERROR(conn))
    return ERROR;
  
  [[songs retain] autorelease];
  
  songEnum = [songs objectEnumerator];
  mpd_sendCommandListBegin(conn);
  while (song = [songEnum nextObject])
  {
  mpd_sendDeleteIdCommand(conn, [song songid]);
  }
  return [self finishCmdList];
}

-(int)moveSongs:(NSArray *)songs toIndex:(int)idx
{
  NSEnumerator *songEnum;
  MpcSong *song;
  int songSourcePosition, offset;
  
  if (MPD_ERROR(conn))
    return ERROR;
  
  [[songs retain] autorelease];
  
  songEnum = [songs objectEnumerator];
  offset = 0;
  mpd_sendCommandListBegin(conn);
  while (song = [songEnum nextObject])
  {
    songSourcePosition = [song plpos];
    // Since moving a song puts it before the index, we need to compensate
    // for tracks occurring before the index
    if (songSourcePosition < idx)
    {
      songSourcePosition -= offset;
      idx--;
      offset++;
    }
    // Ignore requests to move to the same location
    if (songSourcePosition != idx)
    {
      mpd_sendMoveCommand(conn, songSourcePosition, idx);
    }
    // The next track should go below the current track
    idx++;
  }
  return [self finishCmdList];
}

-(int)pause:(BOOL)mode
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendPauseCommand(conn, mode);
  return [self finishCmd];
}

-(int)stop
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendStopCommand(conn);
  return [self finishCmd];
}

-(int)next
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendNextCommand(conn);
  return [self finishCmd];
}

-(int)prev
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendPrevCommand(conn);
  return [self finishCmd];
}

-(int)seek:(int)songid:(int)pos
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendSeekCommand(conn, songid, pos);
  return [self finishCmd];
}

-(int)shuffle
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendShuffleCommand(conn);
  return [self finishCmd];
}

-(int)clearPlaylist
{
  if (MPD_ERROR(conn))
    return ERROR;
  int retval = 0;
  mpd_sendClearCommand(conn);
  retval = [self finishCmd];
  [currPlaylist clear];
  return retval;
}

-(int)repeat:(BOOL)mode
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendRepeatCommand(conn, mode);
  return [self finishCmd];
}

-(int)random:(BOOL)mode
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendRandomCommand(conn, mode);
  return [self finishCmd];
}

-(int)crossfade:(int)seconds
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendCrossfadeCommand(conn, seconds);
  return [self finishCmd];
}

-(int)updateDb
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendUpdateCommand(conn, "");
  return [self finishCmd];
}

-(int)setVolume:(int)value
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendSetvolCommand(conn, value);
  return [self finishCmd];
}

-(int)addSong:(MpcSong *)song
{
  if (MPD_ERROR(conn))
    return ERROR;
  int retval = 0;
  if (!song || ![song file])
    return ERROR;
  
  mpd_sendAddCommand(conn, [[song file] UTF8String]);
  if (retval = [self finishCmd])
    return retval;
  
  [currPlaylist addSong:song];
  [currPlaylist incrementPlaylistId];
  return 0;
}

-(int)addPaths:(NSArray *)paths
{
  NSEnumerator *pathEnum;
  NSString *path;
  
  if (MPD_ERROR(conn))
    return ERROR;
  
  [[paths retain] autorelease];
  
  pathEnum = [paths objectEnumerator];
  mpd_sendCommandListBegin(conn);
  while (path = [pathEnum nextObject])
  {
    mpd_sendAddCommand(conn, [path UTF8String]);
  }
  return [self finishCmdList];
}

-(int)updatePlaylist
{
  mpd_InfoEntity *entity;
  int retval = 0;
  
  if (MPD_ERROR(conn))
    return ERROR;
  
  [currPlaylist clear];
  
  mpd_sendPlaylistInfoCommand(conn, -1);
  while (entity = mpd_getNextInfoEntity(conn))
  {
    if (entity->type == MPD_INFO_ENTITY_TYPE_SONG)
    {
      MpcSong *song = [[MpcSong alloc] initWithSong:entity->info.song];
      [currPlaylist addSong:song];
      [song release];
    }
    mpd_freeInfoEntity(entity);
  }
  [currPlaylist setPlaylistId:[status playlist]];
  return [self finishCmd];      
}

-(int)updatePlaylistChanges
{
  mpd_InfoEntity *entity;
  
  if (MPD_ERROR(conn))
    return ERROR;
  
  mpd_sendPlChangesCommand(conn, [currPlaylist playlistId]);
  
  while (entity = mpd_getNextInfoEntity(conn))
  {
    MpcSong *song = [[MpcSong alloc] initWithSong:entity->info.song];
    
    if ([song plpos] < [currPlaylist count])
    {
      // Update song
      [currPlaylist replaceSongAt:[song plpos] withSong:song];
    }
    else
    {
      // Add song
      [currPlaylist addSong:song];
    }
    [song release];
    mpd_freeInfoEntity(entity);
  }

  // Remove trailing songs
  while ([status playlistLength] < [currPlaylist count])
  {
    [currPlaylist removeLastSong];
  }
  
  [currPlaylist setPlaylistId:[status playlist]];
  
  return [self finishCmd];      
}

-(int)deletePlaylist:(NSString *)name
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendRmCommand(conn, [name cString]);
  return [self finishCmd];
}

-(int)loadPlaylist:(NSString *)name
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendLoadCommand(conn, [name cString]);
  return [self finishCmd];
}

-(int)savePlaylist:(NSString *)name
{
  if (MPD_ERROR(conn))
    return ERROR;
  mpd_sendSaveCommand(conn, [name cString]);
  return [self finishCmd];
}

-(NSArray *)getPlaylistList
{
  mpd_InfoEntity *entity;
  
  if (MPD_ERROR(conn))
    return nil;
  
  NSMutableArray *playlistList = [[NSMutableArray alloc] init];
   
  mpd_sendLsInfoCommand(conn, "");
  while (entity = mpd_getNextInfoEntity(conn))
  {
    if (entity->type == MPD_INFO_ENTITY_TYPE_PLAYLISTFILE)
    {
      if (nil == entity->info.playlistFile)
      {
        // We'll just skip null playlists
        continue;
      }
      [playlistList addObject:[NSString stringWithUTF8String:entity->info.playlistFile->path]];
    }
    mpd_freeInfoEntity(entity);
  }
  if ([self finishCmd])
  {
    return nil;
  }
  else
  {
    return [playlistList autorelease];
  }
}

-(int)getLibrary
{
  mpd_InfoEntity *entity;
  
  if (MPD_ERROR(conn))
    return ERROR;
  
  [library clear];
  
  mpd_sendListallInfoCommand(conn, DB_ROOT);
  while (entity = mpd_getNextInfoEntity(conn))
  {
    if (entity->type == MPD_INFO_ENTITY_TYPE_SONG)
    {
      MpcSong *song = [[MpcSong alloc] initWithSong:entity->info.song];
      [library addSong:song];
      [song release];
    }
    mpd_freeInfoEntity(entity);
  }
  [library setUpdated];
  return [self finishCmd];      
}

-(id)song
{
  return [[currSong retain] autorelease];
}

-(id)playlist
{
  return [[currPlaylist retain] autorelease];
}

-(id)library
{
  return [[library retain] autorelease];
}

-(id)status
{
  return [[status retain] autorelease];
}
  
@end
