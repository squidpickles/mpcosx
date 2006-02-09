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
#import "MpcSong.h"


@interface MpcLibrary : NSObject {
  NSMutableDictionary *library;
  BOOL needsUpdate;
}
-(void)clear;
-(NSArray *)artists;
-(NSArray *)albums;
-(NSArray *)albumsForArtist:(NSString *)artist;
-(NSArray *)albumsForArtists:(NSArray *)artists;
-(NSDictionary *)trackPairsForArtists:(NSArray *)artists andAlbums:(NSArray *)albums;
-(NSArray *)tracksForArtists:(NSArray *)artists andAlbums:(NSArray *)albums;
-(NSArray *)trackPathsForArtists:(NSArray *)artists andAlbums:(NSArray *)albums onlyIncluding:(NSArray *)tracks;
-(void)addSong:(MpcSong *)song;
-(BOOL)needsUpdate;
-(void)setNeedsUpdate;
-(void)setUpdated;
@end
