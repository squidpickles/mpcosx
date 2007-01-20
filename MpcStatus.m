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

#import "MpcStatus.h"

#define ASSIGN(var, val) if (nil == val) \
var = [[NSString alloc] initWithString:@""]; \
else \
var = [[NSString alloc] initWithUTF8String:val];

@implementation MpcStatus
{
int volume, playlistLength, state, crossfade, song, elapsedTime, totalTime;
BOOL repeat, randm, updatingDb;
unsigned long playlist, songid;
NSString *error;
}

- (void)setStatus:(mpd_Status *)status
{
  volume = status->volume;
  playlistLength = status->playlistLength;
  state = status->state;
  crossfade = status->crossfade;
  song = status->song;
  songid = status->songid;
  elapsedTime = status->elapsedTime;
  totalTime = status->totalTime;
  repeat = status->repeat;
  randm = status->random;
  updatingDb = status->updatingDb;
  playlist = status->playlist;
  ASSIGN(error, status->error);
}

- (int)volume
{
  return volume;
}

- (BOOL)repeat
{
  return repeat;
}

- (BOOL)random
{
  return randm;
}

- (int)playlistLength
{
  return playlistLength;
}

- (unsigned long)playlist
{
  return playlist;
}

- (int)state
{
  return state;
}

- (int)crossfade
{
  return crossfade;
}

- (int)song
{
  return song;
}

- (unsigned long)songid
{
  return songid;
}

- (int)elapsedTime
{
  return elapsedTime;
}

- (int)totalTime
{
  return totalTime;
}

- (BOOL)updatingDb
{
  return updatingDb;
}

- (NSString*)error
{
  return [[error copy] autorelease]; 
}

- (void)dealloc
{
  [error release];
  [super dealloc];
}

@end
