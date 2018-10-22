#perl
#AUTHOR: Seneca Menard
#version 1.81 (M5)
#This script will convert the model you have partially selected to subDs while retaining your selection
#(7-29-07) : M3 broke my optimization, so I had to revert to the slower method again.  :(
#(12-18-10) : I put in a hack to support pixar subds.  Just run the script with the "psub" argument appended.

#SCRIPT ARGUMENTS :
# psub : this argument is to tell the script that you want to toggle between pixar subds and back.  If you don't use this argument, then it will continue to use regular subds.

my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");
my @fgLayers = lxq("query layerservice layers ? fg");
my %polyList;
 
#SELECTION TYPE SAFETY CHECk.
if		(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))	{}
elsif	(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{}
elsif	(lxq( "select.typeFrom {polygon;vertex;edge;item} ?" ))	{}
else	{die("\n.\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}

#SCRIPT ARGUMENTS
foreach my $arg (@ARGV){
	if ($arg =~ /psub/i)	{	our $psub = 1;	}
}



#-----------------------------------------------------------------------------------
#MAIN ROUTINE
#-----------------------------------------------------------------------------------
#VERT MODE
if(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) && lxq( "select.count vertex ?" )){
	my @verts = lxq("query layerservice verts ? selected");
	foreach my $vert (@verts){
		my @polys = lxq("query layerservice vert.polyList ? $vert");
		$polyList{@polys[0]} = 1;
	}
	selConnectedPolys("vertex");
}

#EDGE MODE
elsif(lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) && lxq( "select.count edge ?" )){
	my @edges = lxq("query layerservice edges ? selected");
	foreach my $edge (@edges){
		my @polys = lxq("query layerservice edge.polyList ? $edge");
		$polyList{@polys[0]} = 1;
	}
	selConnectedPolys("edge");
}

#POLY MODE
elsif(lxq( "select.typeFrom {polygon;vertex;edge;item} ?" ) && lxq( "select.count polygon ?" )){
	$sel_type = polygon;
	lx("select.editSet supertempBLAH add");
	lx("select.connect");
	toggleSubdivision();
	lx("select.drop polygon");
	lx("select.useSet supertempBLAH select");
	lx("select.editSet supertempBLAH remove");
}

#NOTHING'S SELECTED
else{
	lxout("Nothing's selected, so I'm subDing everything.");
	toggleSubdivision();
}



#-----------------------------------------------------------------------------------
#TOGGLE SUBDIVISION SUBROUTINE
#-----------------------------------------------------------------------------------
sub toggleSubdivision{
	if ( ($modoVer > 500) && ($psub == 1) ){
		lx("poly.convert face psubdiv true");
	}else{
		lx("poly.convert face psubdiv true");
	}
}



#-----------------------------------------------------------------------------------
#CONVERT SUBROUTINE
#-----------------------------------------------------------------------------------
sub selConnectedPolys{
	lx("!!select.drop polygon");
	foreach my $poly (keys %polyList){lx("select.element $mainlayer polygon add $poly");}
	lx("!!select.connect");
	toggleSubdivision();
	lx("!!select.type @_[0]");
}

#-----------------------------------------------------------------------------------
#POPUP WINDOW subroutine
#-----------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
