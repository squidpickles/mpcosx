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

#import "MpcWindowController.h"
#import "MpcServer.h"

@implementation MpcWindowController

#define TIMER_INTERVAL 1.0
#define FONT_SIZE [NSFont systemFontSize] - 2.00
#define MAX_CONNECT_ATTEMPTS 5
#define MPC_RETRY_DELAY 3

#define PREF_SERVER_HOST @"serverHost"
#define PREF_SERVER_PORT @"serverPort"
#define PREF_SERVER_PASSWORD @"serverPassword"
#define PREF_RUN_COUNT @"runCount"

#define ARTIST @"Artist"
#define ALBUM @"Album"
#define TRACK @"Track"
#define BROWSER_ARTIST 0
#define BROWSER_ALBUM 1
#define BROWSER_TRACK 2

NSFont *smallFont;

-(void)connect
{
  int connectCount = 0;
  int error;
  BOOL isConnected;
  NSAttributedString *connectNotice;
  
  connectNotice = [[NSAttributedString alloc] initWithString:@"Connecting to server..." attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, nil]];
  [[nowPlaying textStorage] setAttributedString:connectNotice];
  [nowPlaying display];
  do {
    error = [server connect:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_SERVER_HOST]

                           :[[NSUserDefaults standardUserDefaults] integerForKey:PREF_SERVER_PORT]
                           :10
                           :[[NSUserDefaults standardUserDefaults] stringForKey:PREF_SERVER_PASSWORD]];
    connectCount++;
    isConnected = [server isConnected];
    if (!isConnected)
      sleep(MPC_RETRY_DELAY);
  } while (!isConnected && connectCount < MAX_CONNECT_ATTEMPTS);
  if (error) {
    NSLog(@"Connection error code %d, made %d attempts", error, connectCount);
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Quit"];
    [alert setMessageText:@"Connection error"];
    [alert setInformativeText:[NSString stringWithFormat:@"Couldn't connect to the server after %d tries", connectCount]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
    [alert release];
    [[NSApplication sharedApplication] terminate:self];
  }
}

-(void)awakeFromNib
{
  int connectStatus;
  NSAttributedString *connectNotice;
  int runCount = 0;
  
  // Set playlist font
  [[[playlist tableColumnWithIdentifier:[NSString stringWithString:TIME]] dataCell] setFont:[NSFont systemFontOfSize:FONT_SIZE]];
  [[[playlist tableColumnWithIdentifier:[NSString stringWithString:TITLE]] dataCell] setFont:[NSFont systemFontOfSize:FONT_SIZE]];
  [[[playlist tableColumnWithIdentifier:[NSString stringWithString:ARTIST]] dataCell] setFont:[NSFont systemFontOfSize:FONT_SIZE]];
  [[[playlist tableColumnWithIdentifier:[NSString stringWithString:ALBUM]] dataCell] setFont:[NSFont systemFontOfSize:FONT_SIZE]];
  // Tell playlist to change song on double click
  [playlist setDoubleAction:@selector(changeSong:)];
  // Set up browser font
  [browser setMatrixClass:[MpcLibraryMatrix class]];
  smallFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
  // Make play/pause toggle with spacebar
  [playPause setKeyEquivalent:@" "];
  [[self window] orderFront:self];
  // Setup user defaults
  [MpcWindowController setupDefaults];
  runCount = [[NSUserDefaults standardUserDefaults] integerForKey:PREF_RUN_COUNT];
  if (runCount == 0)
  {
    [prefsWindow makeKeyAndOrderFront:self];
    [[NSApplication sharedApplication] runModalForWindow:prefsWindow];
  }
  [[NSUserDefaults standardUserDefaults] setInteger:++runCount forKey:PREF_RUN_COUNT];
  // Connect to MPD
  server = [MpcServer sharedInstance];
  [self connect];
  connectNotice = [[NSAttributedString alloc] initWithString:@"Fetching library..." attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, nil]];
  [[nowPlaying textStorage] setAttributedString:connectNotice];
  [nowPlaying display];
  // Grab playlist
  [server getLibrary];
  // Grab latest playlist and song
  [server update];
  [self updateStatus:self];  
  [playlist setDataSource:[[server playlist] retain]];
  // Set up drag and drop for playlist
  [playlist registerForDraggedTypes: [NSArray arrayWithObjects:PBOARD_TYPE, nil]];
  // Set up library browser
  [browser reloadColumn:BROWSER_ARTIST];
  while ([browser lastColumn] < BROWSER_TRACK)
  {
    [browser addColumn];
  }
  // Set timer to update status regularly
  updateTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(updateStatus:) userInfo:nil repeats:YES];
}

- (IBAction)browser:(id)sender
{
  while ([browser lastColumn] < BROWSER_TRACK)
    [browser addColumn];
}

- (IBAction)clearPlaylist:(id)sender
{
  [server clearPlaylist];
}

- (IBAction)changeSong:(id)sender
{
  MpcSong *song = [[server playlist] getSong:[playlist selectedRow]];
  [server playSong:song];
}

- (IBAction)next:(id)sender
{
  [server next];
}

- (IBAction)playPause:(id)sender
{
  switch ([myStatus state])
  {
    case MPD_STATUS_STATE_PAUSE:
      [server pause:FALSE];
      break;
    case MPD_STATUS_STATE_PLAY:
      [server pause:TRUE];
      break;
    default:
      [server playSongId:[myStatus songid]];
  }
}

- (IBAction)prev:(id)sender
{
  [server prev];
}

- (IBAction)progress:(id)sender
{
  int pos = [progress intValue] * [myStatus totalTime] / 100;
  [server seek:[myStatus song]:pos];
}

- (IBAction)random:(id)sender
{
  [server random:(NSOnState == [random state])];
}

- (IBAction)removeFromPlaylist:(id)sender
{
  NSIndexSet *selected;
  NSMutableArray *songs;
  unsigned int idx;
  
  selected = [playlist selectedRowIndexes];
  if ([selected count] == 0)
    return; // TODO -- auto menu enable/disable
  songs = [NSMutableArray arrayWithCapacity:[selected count]];
  
  idx = [selected firstIndex];
  do
  {
    [songs addObject:[[server playlist] getSong:idx]];
    idx = [selected indexGreaterThanIndex:idx];
  } while (idx != NSNotFound);
  [server removeSongs:songs];
  [self updatePlaylist:sender];
  [self selectNowPlaying:sender];
}

- (IBAction)shufflePlaylist:(id)sender
{
  [server shuffle];
}

- (IBAction)stop:(id)sender
{
  [server stop];
}

- (IBAction)time:(id)sender
{
}

- (IBAction)volume:(id)sender
{
  [server setVolume:[volume intValue]];
}

- (IBAction)selectNowPlaying:(id)sender
{
  int index = [[playlist dataSource] getIndex:[server song]];
  [playlist selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
       byExtendingSelection:FALSE];
  [playlist scrollRowToVisible:index];
}

- (IBAction)updateDatabase:(id)sender
{
  [dbUpdateIcon setHidden:FALSE];
  [server updateDb];
}

-(void)updateStatus:(id)sender
{
  MpcSong *current;
  NSString *songInfo;
  NSAttributedString *playing;
  int elapsed, minutes, seconds;
  unsigned long playlistId;
  
  playlistId = [[server playlist] playlistId];
  if (![server isConnected])
    [self connect];
  [server update];
  if (![server isConnected])
    return;
  if (myStatus)
  {
    [myStatus release];
    myStatus = nil;
  }
  myStatus = [[server status] retain];
  
  elapsed = minutes = seconds = 0;
  
  // Random checkbox
  if ([myStatus random])
  {
    [random setState:NSOnState];
  }
  else
  {
    [random setState:NSOffState];
  }
  
  // Updating database
  if ([myStatus updatingDb])
  {
    [dbUpdateIcon setHidden:FALSE];
  }
  else
  {
    [dbUpdateIcon setHidden:TRUE];
  }
  
  // Volume slider
  [volume setIntValue:[myStatus volume]];
  
  // Play/pause button, song title
  switch ([myStatus state])
  {
    case MPD_STATUS_STATE_STOP:
      [playPause setState:NSOffState];
      songInfo = [NSString stringWithString:@"Stopped"];
      break;
    case MPD_STATUS_STATE_UNKNOWN:
      songInfo = [NSString stringWithString:@"Unknown status"];
      break;
    case MPD_STATUS_STATE_PLAY:
      [playPause setState:NSOnState];
    case MPD_STATUS_STATE_PAUSE:
      current = [server song];
      songInfo = [NSString stringWithFormat:@"%@ - %@\n%@",[current artist], [current title], [current album]];
      minutes = [myStatus elapsedTime] / 60;
      seconds = [myStatus elapsedTime] % 60;
      elapsed = [myStatus elapsedTime] * 100 / [myStatus totalTime];
  }
  playing = [[NSAttributedString alloc] initWithString:songInfo attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor purpleColor], NSForegroundColorAttributeName, nil]];
  [[nowPlaying textStorage] setAttributedString:playing];
  [playing release];
  
  // Time counter
  [time setStringValue:[NSString stringWithFormat:@"%d:%02d", minutes, seconds]];
  
  // Elapsed time progress bar
  [progress setIntValue:elapsed];
  
  // Playlist
  if (playlistId != [[server playlist] playlistId])
  {
    [self updatePlaylist:self];
  }
  
  // Update the library if it needs it (and DB is not currently updating)
  if (![myStatus updatingDb] && [[server library] needsUpdate])
  {
    [server getLibrary];
  }
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
{
  NSMutableArray *selectedArtists, *selectedAlbums;
  NSArray *items;
  NSEnumerator *objEnum;
  NSString *item;
  id cell;
  int i, count;
  BOOL leaf;
  id obj;
  
  objEnum = [[[sender matrixInColumn:BROWSER_ARTIST] selectedCells] objectEnumerator];
  selectedArtists = [NSMutableArray array];
  while (obj = [objEnum nextObject])
  {
    [selectedArtists addObject:[obj stringValue]];
  }
  objEnum = [[[sender matrixInColumn:BROWSER_ALBUM] selectedCells] objectEnumerator];
  selectedAlbums = [NSMutableArray array];
  while (obj = [objEnum nextObject])
  {
    [selectedAlbums addObject:[obj stringValue]];
  }
  
  switch (column)
  {
    case BROWSER_ARTIST:
      items = [[server library] artists];
      leaf = FALSE;
      break;
    case BROWSER_ALBUM:
      items = [[server library] albumsForArtists:selectedArtists];
      leaf = FALSE;
      break;
    case BROWSER_TRACK:
      items = [[server library] tracksForArtists:selectedArtists andAlbums:selectedAlbums];
      leaf = TRUE;
      break;
  }
  count = [items count];
  [(MpcLibraryMatrix *)matrix setColumn:column];
  [matrix renewRows:count columns:1];
  [matrix setFont:smallFont];
  for (i = 0; i< count; i++)
  {
    cell = [matrix cellAtRow:i column:0];
    [cell setLeaf:leaf];
    [cell setStringValue:[items objectAtIndex:i]];
    [cell setLoaded:TRUE];
  }
}

-(NSArray *)selectedLibraryTracks
{
  NSArray *cells;
  NSMutableArray *names;
  NSMutableDictionary *selected;
  NSEnumerator *cellEnum;
  NSCell *cell;
  int column;
  
  selected = [NSMutableDictionary dictionary];
  for (column = 0; column < BROWSER_TRACK+1; column++)
  {
    cells = [[browser matrixInColumn:column] selectedCells];
    names = [NSMutableArray arrayWithCapacity:[cells count]];
    cellEnum = [cells objectEnumerator];
    while (cell = [cellEnum nextObject])
    {
      [names addObject:[cell stringValue]];
    }
    [selected setObject:[names copy] forKey:[NSNumber numberWithInt:column]];
  }
  return [[server library] trackPathsForArtists:[selected objectForKey:[NSNumber numberWithInt:BROWSER_ARTIST]] andAlbums:[selected objectForKey:[NSNumber numberWithInt:BROWSER_ALBUM]] onlyIncluding:[selected objectForKey:[NSNumber numberWithInt:BROWSER_TRACK]]];
}

-(void)updatePlaylist:(id)sender
{
  [playlist reloadData];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  [updateTimer invalidate];
  [server disconnect];
  return NSTerminateNow;
}

- (void)windowWillClose:(NSNotification *)aNotification
{
  if ([prefsWindow isEqualTo:[aNotification object]])
  {
    [[NSApplication sharedApplication] stopModal];
  }
}

+ (void)setupDefaults
{
  NSString *userDefaultsValuesPath;
  NSDictionary *userDefaultsValuesDict;
  NSDictionary *initialValuesDict;
  NSArray *resettableUserDefaultsKeys;
  
  // load the default values for the user defaults
  userDefaultsValuesPath=[[NSBundle mainBundle] pathForResource:@"UserDefaults" 
                                                         ofType:@"plist"];
  userDefaultsValuesDict=[NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
  
  // set them in the standard user defaults
  [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
  
  // if your application supports resetting a subset of the defaults to 
  // factory values, you should set those values 
  // in the shared user defaults controller
  resettableUserDefaultsKeys=[NSArray arrayWithObjects:PREF_SERVER_HOST, PREF_SERVER_PORT, PREF_SERVER_PASSWORD, nil];
  initialValuesDict=[userDefaultsValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
  
  // Set the initial values in the shared user defaults controller 
  [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}

- (void)dealloc
{
  [server disconnect];
  [server release];
  server = nil;
  [super dealloc];
}

@end
