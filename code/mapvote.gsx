startVote()
{
	if( !isArray( level.mapvoteMaps ) )
		return;

	level thread setHud();
	
	players = getEntarray( "player", "classname" );
	for( i = 0; i < players.size; i++ )
	{
		player = players[ i ];
		player thread playerSpecificHud();
		player thread voteThink();
	}
	
	level thread voteLogic( players );
	
	level waittill( "endVote" );
	
	players = getEntarray( "player", "classname" );
	for( i = 0; i < players.size; i++ )
	{
		if( isDefined( players[ i ].playerVoteHud ) )
			players[ i ].playerVoteHud destroy();
	}
	
	for( i = 0; i < level.mapVoteHud.size; i++ )
		level.mapVoteHud[ i ] destroy();
		
	notifyMap();
}

init()
{
	list = getDvar( "sv_mapRotation" );
	listTok = strTok( list, " " );
	
	waittillframeend;
	
	maps = [];
	j = 0;
	
	for( i = 0; i < listTok.size; i++ )
	{
		if( isSubStr( listTok[ i ], "mp_" ) )
		{
			maps[ j ] = listTok[ i ];
			j++;
		}
		
		waittillframeend;
	}
	
	if( maps.size == level.dvar[ "mapvote_mapnum" ] )
		votableMaps = maps;
	else
	{
		if( maps.size < level.dvar[ "mapvote_mapnum" ] )
		{
			if( maps.size >= 3 )
			{
				level.dvar[ "mapvote_mapnum" ] = maps.size;
				level.mapvoteMaps = maps;
				logPrint( "Mapvote ERROR: Not enough maps in map rotation for current mapnumber settings.\n" );
				return;
			}
			else
			{
				logPrint( "Mapvote CRITICAL: Not enough maps in map rotation to vote, mapvote failed.\n" );
				return;
			}
		}
		
		votableMaps = [];

		num = maps.size - level.dvar[ "mapvote_norepeat" ] - level.dvar[ "mapvote_mapnum" ];
		if( num < 0 )
		{
			level.dvar[ "mapvote_norepeat" ] += num;
			logPrint( "\nMapvote ERROR: Not enough maps in map rotation for current no-repeat setting.\n" );
		}
		
		legalMaps = getLegalMaps( maps );
		votableMaps = getVotableMaps( legalMaps );
	}
	
	level.mapvoteMaps = votableMaps;
}

playerSpecificHud()
{
	self.playerVoteHud = newClientHudElem( self );
	self.playerVoteHud.horzAlign = "center";
	self.playerVoteHud.vertAlign = "top";
	self.playerVoteHud.alignX = "center";
	self.playerVoteHud.alignY = "top";
	self.playerVoteHud.y = 110;
	self.playerVoteHud.x = 0;
	self.playerVoteHud.alpha = 0;
	self.playerVoteHud.archived = false;
	self.playerVoteHud.color = ( 153/255, 1, 235/255 );
	self.playerVoteHud setShader( "white", 200, 20 );
}

voteLogic( players )
{
	time = level.dvar[ "mapvote_time" ] * 4;
	
	level.countedVotes = [];
	
	while( time > 0 )
	{
		for( i = 0; i < level.mapvoteMaps.size; i++ )
			level.countedVotes[ i ] = 0;
		
		for( i = 0; i < players.size; i++ )
		{
			player = players[ i ];
			if( isDefined( player ) && isDefined( player.votePick ) && player.votePick >= 0 )
				level.countedVotes[ player.votePick ]++;
		}
		
		j = 0;
		for( i = 7; i < level.mapVoteHud.size; i += 2 )
		{
			level.mapVoteHud[ i ] setValue( level.countedVotes[ j ] );
			j++;
		}
		
		time--;
		wait .25;
	}
	
	helperArray = [];
	helperArray[ "num" ] = 0;
	helperArray[ "mapnum" ] = 0;
	
	for( i = 0; i < level.mapvoteMaps.size; i++ )
	{
		if( helperArray[ "num" ] < level.countedVotes[ i ] )
		{
			helperArray[ "num" ] = level.countedVotes[ i ];
			helperArray[ "mapnum" ] = i;
		}
	}
	
	level.wonMap = level.mapvoteMaps[ helperArray[ "mapnum" ] ];
	
	setDvar( "sv_mapRotationCurrent", "map " + level.wonMap );
	
	thread addIllegalMap();
	
	level notify( "endVote" );
}

mapNameCapitalised( string )
{
	trash = strTok( string, "_" );
	string = trash[ 1 ];
	new = "";
	
	new += code\common::toUpper( string[ 0 ] );
	
	for( i = 1; i < string.size; i++ )
		new += string[ i ];
		
	return new;
}

addIllegalMap()
{
	lastI = getDvar( "mapvote_lastI" );
	
	if( lastI == "" )
		lastI = -1;
	else
		lastI = int( lastI );
	
	lastI++;
	
	if( lastI >= level.dvar[ "mapvote_norepeat" ] )
		lastI = 0;
	
	setDvar( "mapvote_lastI", lastI );
	
	dvar = "mapvote_illegalmap_" + lastI;
	setDvar( dvar, level.wonMap );
}

notifyMap()
{
	map = mapNameCapitalised( level.wonMap );
	
	winningMap = createElem( "center", "middle", "center", "middle", 0, -40, 2.3, 1 );
	winningMap setText( "Next map: " + map );
	winningMap.color = ( 0, 102/255, 255/255 );
	winningMap.glowAlpha = 1;
	winningMap.glowColor = ( 1, 0, 0 );
	
	wait 5;
	
	winningMap destroy();
}

updatePlayerSpecificHud()
{
	y = 110 + ( self.votePick * 22.5 );
	
	self.playerVoteHud.y = y;
}

voteThink()
{
	self endon( "disconnect" );
	level endon( "endVote" );
	
	self.votePick = -1;
	
	while( !self attackButtonPressed() )
		wait .05;
	
	self.playerVoteHud.alpha = 0.5;
	
	while( 1 )
	{
		self.votePick++;
		
		if( self.votePick >= level.mapvoteMaps.size )
			self.votePick = 0;
		
		self thread updatePlayerSpecificHud();
		
		wait .3;
		
		while( !self attackButtonPressed() )
			wait .05;
	}
}

setHud()
{
	level.mapVoteHud = [];
	
	box1 = int( 59 + ( level.mapvoteMaps.size * 22.5 ) );
	box2 = int( 54 + ( level.mapvoteMaps.size * 22.5 ) );
	box3 = int( 29 + ( level.mapvoteMaps.size * 22.5 ) );
	
	level.mapVoteHud[ 0 ] = createElem( "center", "top", "center", "top", 0, 70, 1.4, 0.8 );
	level.mapVoteHud[ 0 ] setShader( "white", 210, box1 );
	level.mapVoteHud[ 0 ].color = ( 0, 0, 0 );
	
	level.mapVoteHud[ 1 ] = createElem( "center", "top", "center", "top", 0, 72.5, 1.4, 0.8 );
	level.mapVoteHud[ 1 ] setShader( "white", 205, box2 );
	level.mapVoteHud[ 1 ].color = ( 0.25, 0.25, 0.25 );
	
	level.mapVoteHud[ 2 ] = createElem( "center", "top", "center", "top", 0, 95.5, 1.4, 0.6 );
	level.mapVoteHud[ 2 ] setShader( "white", 200, box3 );
	level.mapVoteHud[ 2 ].color = ( 0, 0, 0 );
	
	level.mapVoteHud[ 3 ] = createElem( "left", "top", "left", "top", 330, 74.5, 1.5, 1 );
	level.mapVoteHud[ 3 ] setText( "Vote" );
	level.mapVoteHud[ 3 ].color = ( 1, 1, 1 );
	
	level.mapVoteHud[ 4 ] = createElem( "right", "top", "right", "top", -330, 74.5, 1.5, 1 );
	level.mapVoteHud[ 4 ] setTimer( level.dvar[ "mapvote_time" ] );
	level.mapVoteHud[ 4 ].color = ( 1, 1, 1 );
	
	level.mapVoteHud[ 5 ] = createElem( "center", "top", "center", "top", 0, 40, 1.5, 1 );
	level.mapVoteHud[ 5 ] setText( "Press [{+attack}] to vote." );
	level.mapVoteHud[ 5 ].color = ( 0, 102/255, 255/255 );
	level.mapVoteHud[ 5 ].glowAlpha = 1;
	level.mapVoteHud[ 5 ].glowColor = ( 0, 102/255, 255/255 );
	
	n = 6;
	j = 7;
	for( i = 0; i < level.mapvoteMaps.size; i++ )
	{
		level.mapVoteHud[ n ] = createElem( "left", "top", "left", "top", 343.5, 110 + ( i * 22.5 ), 1.5, 1 );
		level.mapVoteHud[ n ] setText( mapNameCapitalised( level.mapvoteMaps[ i ] ) );
		level.mapVoteHud[ n ].color = ( 1, 1, 1 );
		
		level.mapVoteHud[ j ] = createElem( "right", "top", "right", "top", -343.5, 110 + ( i * 22.5 ), 1.5, 1 );
		level.mapVoteHud[ j ] setValue( 0 );
		level.mapVoteHud[ j ].color = ( 1, 1, 1 );
		
		n += 2;
		j += 2;
	}
}

getVotableMaps( maps )
{
	votableMaps = [];
	
	for( i = 0; i < level.dvar[ "mapvote_mapnum" ]; i++ )
	{
		random = randomInt( maps.size );
			
		votableMaps[ i ] = maps[ random ];
		maps = popArray( maps, random );
			
		waittillframeend;
	}
	
	return votableMaps;
}

getLegalMaps( maps )
{
	illegalMaps = getIllegalMaps();
	legalMaps = [];
	j = 0;
	
	for( i = 0; i < maps.size; i++ )
	{
		if( illegalMaps isInArray( maps[ i ] ) )
			continue;
		
		legalMaps[ j ] = maps[ i ];
		j++;
	}
	
	return legalMaps;
}

popArray( array, index )
{
	for( i = index; i < array.size; i++ )
	{
		array[ i ] = array[ i + 1 ];
	}
	
	return array;
}

getIllegalMaps()
{
	m = [];
	
	for( i = 0; i < level.dvar[ "mapvote_norepeat" ]; i++ )
		m[ i ] = getDvar( "mapvote_illegalmap_" + i );
	
	return m;
}

isInArray( s )
{
	for( i = 0; i < self.size; i++ )
	{
		if( s == self[ i ] )
			return true;
	}
	
	return false;
}

createElem( horzAlign, vertAlign, alignX, alignY, x, y, scale, alpha )
{
	hud = newHudElem();
	hud.horzAlign = horzAlign;
	hud.vertAlign = vertAlign;
	hud.alignX = alignX;
	hud.alignY = alignY;
	hud.y = y;
	hud.x = x;
	hud.fontScale = scale;
	hud.alpha = alpha;
	hud.archived = false;
	
	return hud;
}