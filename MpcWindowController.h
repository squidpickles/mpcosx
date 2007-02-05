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

#import <Cocoa/Cocoa.h>
#import "MpcServer.h"
#import "MpcLibraryMatrix.h"
#import "Growl/Growl.h"

@interface MpcWindowController : NSWindowController <GrowlApplicationBridgeDelegate>
{
    IBOutlet NSBrowser *browser;
    IBOutlet NSTableView *playlist;
    IBOutlet NSTextView *nowPlaying;
    IBOutlet NSLevelIndicator *progress;
    IBOutlet NSButton *random;
    IBOutlet NSTextField *time;
    IBOutlet NSSlider *volume;
    IBOutlet NSButton *playPause;
    IBOutlet NSWindow *prefsWindow;
    IBOutlet NSWindow *playlistNamingWindow;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSImageView *dbUpdateIcon;
    IBOutlet NSTextField *newPlaylistName;
    IBOutlet id playlistListController;
    MpcServer *server;
    NSTimer *updateTimer;
    MpcStatus *myStatus;
    NSMutableArray *playlistList;
    MpcSong *lastTrack;
    NSDate *lastNotified;
    BOOL hasRegistered;

}
- (IBAction)browser:(id)sender;
- (IBAction)clearPlaylist:(id)sender;
- (IBAction)changeSong:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)prev:(id)sender;
- (IBAction)progress:(id)sender;
- (IBAction)random:(id)sender;
- (IBAction)removeFromPlaylist:(id)sender;
- (IBAction)shufflePlaylist:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)time:(id)sender;
- (IBAction)volume:(id)sender;
- (IBAction)selectNowPlaying:(id)sender;
- (IBAction)updateDatabase:(id)sender;
- (IBAction)performSavePlaylist:(id)sender;
- (IBAction)closePlaylistNamingWindow:(id)sender;
- (IBAction)openPlaylistNamingWindow:(id)sender;
- (void)updateStatus:(id)sender;
- (void)updatePlaylist:(id)sender;
- (void)loadPlaylists:(NSArray *)listNames;
- (void)savePlaylist:(NSString *)listName;
- (void)deletePlaylist:(NSString *)listName;
- (void)updatePlaylistList:(id)sender;
+ (void)setupDefaults;
- (NSDictionary *)registrationDictionaryForGrowl;
- (NSString *)applicationNameForGrowl;
- (void)notifyNowPlaying:(MpcSong *)currentTrack;
/*
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
*/
- (NSArray *)selectedLibraryTracks;
- (void)windowWillClose:(NSNotification *)aNotification;
- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
@end
