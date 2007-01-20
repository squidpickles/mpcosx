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

#import "MpcLibrary.h"
#import "MpcSong.h"

NSString *notFound = @"NOT FOUND";

@implementation MpcLibrary
{
  NSMutableDictionary *library;
  BOOL needsUpdate;
}

-(id)init
{
  if ([super init])
  library = [[NSMutableDictionary alloc] init];
  [self setNeedsUpdate];
  return self;
}

-(void)clear
{
  [library removeAllObjects];
}

-(NSArray *)artists
{
  return [[library allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

-(NSArray *)albums
{
  return [self albumsForArtist:nil];
}

-(NSArray *)albumsForArtist:(NSString *)artist
{
  if (nil == artist || [artist length] == 0)
  {
    return [self albumsForArtists:nil];
  }
  return [self albumsForArtists:[NSArray arrayWithObject:artist]];
}

-(NSArray *)albumsForArtists:(NSArray *)artists
{
  NSArray *artistKeyList;
  NSMutableDictionary *uniqueAlbums;
  NSEnumerator *artistEnum, *albumEnum;
  NSDictionary *currentArtist;
  NSString *currentAlbum;
  
  if (nil == artists || [artists count] == 0)
  {
    // Want all albums
    artistKeyList = [library allValues];
  }
  else
  {
    artistKeyList = [library objectsForKeys:artists notFoundMarker:notFound];
  }
  // Now, for each album, we'll add the name to our unique albums list
  uniqueAlbums = [NSMutableDictionary dictionary];
  artistEnum = [artistKeyList objectEnumerator];
  while (currentArtist = [artistEnum nextObject])
  {
    if ([notFound isEqualTo:currentArtist])
    {
      continue;
    }
    // We want to go through and add each album for that artist
    albumEnum = [currentArtist keyEnumerator];
    while (currentAlbum = [albumEnum nextObject])
    {
      // The current album will contain a single key with the album name
      [uniqueAlbums setObject:@"" forKey:currentAlbum];
    }
  }
  return [[uniqueAlbums allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

-(NSDictionary *)trackPairsForArtists:(NSArray *)artists andAlbums:(NSArray *)albums
{
  NSArray *albumList, *trackList;
  NSMutableDictionary *tracks;
  NSEnumerator *artistEnum, *trackEnum;
  NSDictionary *currentArtist, *albumTracks;
  NSString *albumName;
  
  tracks = [NSMutableDictionary dictionary];
  
  // Now we get a list of albums.  Each entry in the array is a dictionary
  // of albums (album name is key, track dictionary is value).  Entries are
  // grouped by artist.
  if (nil == artists || [artists count] == 0)
    albumList = [library allValues];
  else
    albumList = [library objectsForKeys:artists notFoundMarker:notFound];
  // Okay, so we have the grouped list of all albums by the artists.  Now we
  // want to grab the tracks from each of the albums that was selected.  (We
  // don't need to worry about artists any more.)
  
  artistEnum = [albumList objectEnumerator];
  while (currentArtist = [artistEnum nextObject])
  {
    // We could get a notFound entry from earlier; this is just to be safe
    if ([notFound isEqualTo:currentArtist])
      continue;
    
    // We should now get an array of track dictionaries for albums matching
    // those specified
    if (nil == albums || [albums count] == 0)
      trackList = [currentArtist allValues];
    else
      trackList = [currentArtist objectsForKeys:albums notFoundMarker:notFound];
    trackEnum = [trackList objectEnumerator];
    while (albumTracks = [trackEnum nextObject])
    {
      if ([notFound isEqualTo:albumTracks])
        continue;
      [tracks addEntriesFromDictionary:albumTracks];
    }
  }
  
  return tracks;
}

-(NSArray *)tracksForArtists:(NSArray *)artists andAlbums:(NSArray *)albums
{
  return [[self trackPairsForArtists:artists andAlbums:albums] keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)];
}

-(NSArray *)trackPathsForArtists:(NSArray *)artists andAlbums:(NSArray *)albums onlyIncluding:(NSArray *)tracks
{
  NSDictionary *pairs;
  NSArray *retval;
  
  pairs = [self trackPairsForArtists:artists andAlbums:albums];
  if (nil == tracks || [tracks count] == 0)
    retval = [pairs allValues];
  else
    retval = [pairs objectsForKeys:tracks notFoundMarker:notFound];
  return [retval sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

-(void)addSong:(MpcSong *)song
{
  NSMutableDictionary *album, *artist;
  
  artist = [library objectForKey:[song artist]];
  if (!artist)
  {
    // No artist, album, or track exists yet; just add everything
    [library setObject:[NSMutableDictionary dictionaryWithObject:[NSMutableDictionary dictionaryWithObject:[song file] forKey:[song title]] forKey:[song album]] forKey:[song artist]];
    return;
  }
  album = [artist objectForKey:[song album]];
  if (!album)
  {
    // Add the album and track
    [artist setObject:[NSMutableDictionary dictionaryWithObject:[song file] forKey:[song title]] forKey:[song album]];
    return;
  }
  // We have an artist and album, so we'll just add the track, replacing any existing tracks
  // with the same title on that album
  [album setObject:[song file] forKey:[song title]];
}

-(BOOL)needsUpdate
{
  return needsUpdate;
}

-(void)setNeedsUpdate
{
  needsUpdate = TRUE;
}

-(void)setUpdated
{
  needsUpdate = FALSE;
}

-(void)dealloc
{
  [library release];
  library = nil;
  [super dealloc];
}

@end
