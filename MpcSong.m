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

#import "MpcSong.h"

#define UNKNOWN @"[unknown]"
#define ASSIGN(var, val) if (nil == val) \
    var = [[NSString alloc] initWithString:UNKNOWN]; \
  else \
    var = [[NSString alloc] initWithUTF8String:val]; \

@implementation MpcSong
{
  NSString *file, *title, *artist, *album, *track;
  int length, plpos, songid;
}

-(id)initWithSong:(mpd_Song *)song
{
  [super init];
  ASSIGN(file, song->file);
  if (song->title)
  {
    ASSIGN(title, song->title);
  }
  else
  {
    title = [[NSString alloc] initWithString:[file lastPathComponent]];
  }
  ASSIGN(artist, song->artist);
  ASSIGN(album, song->album);
  if (song->track)
  {
    ASSIGN(track, song->track);
  }
  else
  {
    track = [[NSString alloc] initWithString:@"0"];
  }
  length = song->time;
  plpos = song->pos;
  songid = song->id;
  return self;
}

- (NSString *)file
{
  return [[file copy] autorelease]; 
}

- (NSString *)title
{
  return [[title copy] autorelease]; 
}

- (NSString *)artist
{
  return [[artist copy] autorelease]; 
}

- (NSString *)album
{
  return [[album copy] autorelease]; 
}

- (NSString *)track
{
  return [[track copy] autorelease]; 
}

- (int)trackLength
{
  return length;
}

- (BOOL)isEqual:(id)object
{
  BOOL equal = TRUE;
  equal &= [artist isEqualToString:[object artist]];
  equal &= [album isEqualToString:[object album]];
  equal &= [track isEqualToString:[object track]];
  equal &= [title isEqualToString:[object title]];
  return equal;
}

- (NSString *)formattedLength
{
  int minutes = length/60;
  int seconds = length - (minutes * 60);
  return [NSString stringWithFormat:@"%0d:%02d", minutes, seconds];
}
  

- (int)plpos
{
  return plpos;
}

- (int)songid
{
  return songid;
}

- (void)dealloc
{
  [file release];
  [title release];
  [artist release];
  [album release];
  [track release];
  
  file = nil;
  title = nil;
  artist = nil;
  album = nil;
  track = nil;
  [super dealloc];
}

@end
