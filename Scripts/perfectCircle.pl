#perl
#Perfect Circle
#AUTHOR: Seneca Menard
#version 1.97 (modo2)

#This script is for taking a POLY(s) or EDGELOOP(s) and moving the vertices so they form a perfect circle.
#This script was made because I often STENCIL or KNIFE a CIRCLE onto a mesh, and waste a lot of time tweaking the verts to try to get it perfectly round...
#-If you have MULTIPLE POLYGONS selected, it'll only pay attention to the BORDER VERTS.
#-If you have VERTS selected it will convert the selection to EDGES, so if converting the selection to edges didn't result in EDGELOOPS, then this script won't work
#-(7-18-05) bugfix: the script will work If you're using centimeters, millimeters, etc now.
#(2-2-06) MODO2 FIX and the script now works in symmetry!
#(7-3-07) fixed a small workplane restoration bug.
#(5-21-08 fix) : put in a proper radius determination
#(5-22-08 fix) : put in a proper axis determination
#(5-24-08 fix) : removed spin from corrections and fixed symmetry.
#(7-24-08 fix) : restored selection after script is done and swapped the layer reference/workplane alterations to stop the modo viewport hiccup.
#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.

#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#SAFETY CHECKS
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO2 FIX))
#-----------------------------------------------------------------------------------
#sets the ACTR preset
my $pi=3.1415926535897932384626433832795;
my $mainlayer = lxq("query layerservice layers ? main");
my $polyCount = lxq("query layerservice poly.n ? all");
my $seltype;
my $selAxis;
my $selCenter;
my $actr = 1;
if( lxq( "tool.set actr.select ?") eq "on")				{	$seltype = "actr.select";		}
elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
elsif( lxq( "tool.set actr.local ?") eq "on")			{	$seltype = "actr.local";		}
elsif( lxq( "tool.set actr.pivot ?") eq "on")			{	$seltype = "actr.pivot";		}
elsif( lxq( "tool.set actr.auto ?") eq "on")			{	$seltype = "actr.auto";			}
else
{
	$actr = 0;
	lxout("custom Action Center");
	if( lxq( "tool.set axis.select ?") eq "on")			{	 $selAxis = "select";			}
	elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
	elsif( lxq( "tool.set axis.view ?") eq "on")		{	 $selAxis = "view";				}
	elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
	elsif( lxq( "tool.set axis.local ?") eq "on")		{	 $selAxis = "local";			}
	elsif( lxq( "tool.set axis.pivot ?") eq "on")		{	 $selAxis = "pivot";			}
	elsif( lxq( "tool.set axis.auto ?") eq "on")		{	 $selAxis = "auto";				}
	else												{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

	if( lxq( "tool.set center.select ?") eq "on")		{	 $selCenter = "select";			}
	elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
	elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
	elsif( lxq( "tool.set center.origin ?") eq "on")	{	 $selCenter = "origin";			}
	elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
	elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
	elsif( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
	else												{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
	#popup("AC ($selAxis <> $selCenter)");
}
#popup("seltype = $seltype");


#Remember what the workplane was and turn it off
my @backupWP;
@backupWP[0] = lxq ("workPlane.edit cenX:? ");
@backupWP[1] = lxq ("workPlane.edit cenY:? ");
@backupWP[2] = lxq ("workPlane.edit cenZ:? ");
@backupWP[3] = lxq ("workPlane.edit rotX:? ");
@backupWP[4] = lxq ("workPlane.edit rotY:? ");
@backupWP[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset ");

#set the main layer to be "reference" to get the true vert positions.
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $layerReference = lxq("layer.setReference ?");
lx("!!layer.setReference $mainlayerID");


#IF in EDGE mode
if(lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) && lxq( "select.count edge ?" )){
	our $sel_type= "edge";
}

#IF in POLY mode
elsif(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) && lxq( "select.count polygon ?" )){
	lx("select.drop edge");
	lx("select.type polygon");
	lx("!!select.editSet senePC add");
	lx("select.boundary");
	our $sel_type= "polygon";
}

#IF in VERTEX mode
elsif(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) && lxq( "select.count vertex ?" )){
	lx("!!select.editSet senePC add");
	lx("select.convert edge");
	our $sel_type= "vertex";
}

else{
	die("You must have some polys or verts or edges selected");
}


#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#SYMMETRY CODE
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#Turn off and protect Symmetry
my $symmAxis = lxq("select.symmetryState ?");
#CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}
if ($symmAxis != 3)				{	lx("select.symmetryState none");	}

our %vertPosTable;

#create a table for all vert positions if symmetry is on.
if ($symmAxis != 3){
	#figure out what the NON symm axes are.
	our $nonSymmAxis1;
	our $nonSymmAxis2;
	if ($symmAxis == 0)		{$nonSymmAxis1 = 1; $nonSymmAxis2 = 2;}
	elsif ($symmAxis == 1)	{$nonSymmAxis1 = 0; $nonSymmAxis2 = 2;}
	elsif ($symmAxis == 2)	{$nonSymmAxis1 = 0; $nonSymmAxis2 = 1;}

	#throw the verts into the vertPosTable.
	my @edges  = lxq("query layerservice edges ? selected");
	foreach my $edge (@edges)	{
		my @verts = split (/[^0-9]/, $edge);
		my @vert1Pos = lxq("query layerservice vert.pos ? @verts[1]");
		my @vert2Pos = lxq("query layerservice vert.pos ? @verts[2]");

		$vertPosTable{@verts[1]} = \@vert1Pos;
		$vertPosTable{@verts[2]} = \@vert2Pos;
	}
}



#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#SORT THE ROWS
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#CREATE AND EDIT the edge list.  [remove ( )] (FIXED FOR M2.  I'm not using the multilayer query anymore)
our @origEdgeList = lxq("query layerservice edges ? selected");
s/\(// for @origEdgeList;
s/\)// for @origEdgeList;


our @origEdgeList_edit = @origEdgeList;
our @vertRow = split(/,/, @origEdgeList_edit[0]);
shift(@origEdgeList_edit);
our @vertRow;
our @vertRowList;
our @OrigWPmem;
our @WPmem;
our %vertRowTable;

while (@origEdgeList_edit != 0){
	#this is a loop to go thru and sort the edge loops
	@vertRow = split(/,/, @origEdgeList_edit[0]);
	shift(@origEdgeList_edit);
	&sortRow;

	#take the new edgesort array and add it to the big list of edges.
	push(@vertRowList, "@vertRow");
}


#build the vertRow table
for ($i = 0; $i < @vertRowList ; $i++){
	my @verts = split (/[^0-9]/, @vertRowList[$i]);
	if (@verts[0] == @verts[-1]){pop(@verts);}
	push(@{$vertRowTable{$i}},@verts);
}




#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#BEGIN THE WORK for (EACH) vertrow
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------
our %skipRows;
foreach my $key (keys %vertRowTable){
	#whether or not to skip a SYMM moved row
	if ($skipRows{$key} != 1){
		lxout("[->] : running row ($key)");
		my $foundSymmetricalRow = -1;

		#don't select from this vertRow ever again..
		$skipRows{$key} = 1;

		#--------------------------------------------
		#SELECT THE (CURRENT) VERTROW
		#--------------------------------------------
		lx("select.drop vertex");
		my @verts = @{$vertRowTable{$key}};
		lx("select.element [$mainlayer] vertex add $_") for @verts;

		#--------------------------------------------
		#FIND THE (CURRENT) VERTROW's CENTER
		#--------------------------------------------
		my @center=(0,0,0);
		foreach my $vert (@verts){
			my @pos = lxq("query layerservice vert.pos ? $vert");
			@center = arrMath(@center,@pos,add);
		}
		@center = arrMath(@center,($#verts+1),($#verts+1),($#verts+1),div);


		#--------------------------------------------
		#FIND THE (CURRENT) VERTROW's AXIS
		#--------------------------------------------
		my @avgCP=(0,0,0);
		for (my $i=0; $i<@verts; $i++){
			my @pos1 = lxq("query layerservice vert.pos ? @verts[$i]");
			my @pos2 = lxq("query layerservice vert.pos ? @verts[$i-1]");  #TEMP : if you have verts in the same place, the script dies because it can't run a unitVector on that..
			my @vector1 = unitVector(arrMath(@pos1,@pos2,subt));
			my @vector2 = unitVector(arrMath(@pos1,@center,subt));
			my @cp = unitVector(crossProduct(\@vector1,\@vector2));
			@avgCP = arrMath(@avgCP,@cp,add);
		}
		my @normal = unitVector(arrMath(@avgCP,($#avgCP+1),($#avgCP+1),($#avgCP+1),div));
		my @lastVertPos = lxq("query layerservice vert.pos ? @verts[0]");
		my @vertToCenterVector = unitVector(arrMath(@lastVertPos,@center,subt));
		my @cp = unitVector(crossProduct(\@normal,\@vertToCenterVector));


		#--------------------------------------------
		#FLATTEN THE (CURRENT) VERTROW
		#--------------------------------------------
		lx("tool.set actr.element on");
		lx("tool.set xfrm.stretch on");
		lx("tool.reset");
		lx("tool.setAttr center.element cenX {@center[0]}");
		lx("tool.setAttr center.element cenY {@center[1]}");
		lx("tool.setAttr center.element cenZ {@center[2]}");
		lx("tool.setAttr axis.element axisX {@cp[0]}");
		lx("tool.setAttr axis.element axisY {@cp[1]}");
		lx("tool.setAttr axis.element axisZ {@cp[2]}");
		lx("tool.setAttr axis.element axis {-1}");
		lx("tool.setAttr axis.element upX {@normal[0]}");
		lx("tool.setAttr axis.element upY {@normal[1]}");
		lx("tool.setAttr axis.element upZ {@normal[2]}");
		lx("tool.setAttr xfrm.stretch factX {1}");
		lx("tool.setAttr xfrm.stretch factY {0}");
		lx("tool.setAttr xfrm.stretch factZ {1}");
		lx("tool.doApply");
		lx("tool.set xfrm.stretch off");


		#--------------------------------------------
		#FIND THE (CURRENT) VERTROW's RADIUS
		#--------------------------------------------
		my $radiusAverage;
		for (my $i=0; $i<@verts; $i++){$radiusAverage += distance(@verts[$i],@verts[$i-1]);}
		$radiusAverage = $radiusAverage / ($pi*2);


		#--------------------------------------------
		#CREATE THE (CURRENT) TEMP DISC THAT WILL BE USED FOR VERT PLACEMENTS
		#--------------------------------------------
		#my @angles = headingPitch(@normal);
		#lxout("angles = @angles");
		my $cylVerts = @verts;
		lx("tool.set prim.cylinder on");
		lx("tool.setAttr prim.cylinder sides {$cylVerts}");
		lx("tool.setAttr prim.cylinder cenX {@center[0]}");
		lx("tool.setAttr prim.cylinder cenY {@center[1]}");
		lx("tool.setAttr prim.cylinder cenZ {@center[2]}");
		lx("tool.setAttr prim.cylinder sizeX {$radiusAverage}");
		lx("tool.setAttr prim.cylinder sizeY {0}");
		lx("tool.setAttr prim.cylinder sizeZ {$radiusAverage}");
		lx("tool.setAttr prim.cylinder axis {1}");
		lx("tool.doApply");
		lx("tool.set prim.cylinder off");

		#--------------------------------------------
		#ROTATE THE TEMP DISC TO MATCH THE NORMAL
		#--------------------------------------------
		my @angles = headingPitch(@normal);

		#rotate the current row to be flat on Y
		lx("tool.set actr.auto on");
		rotateFlat(\@center,@angles[0]+90,@angles[1]);
		my $newestPoly = lxq("query layerservice poly.n ? all") - 1;
		my @newestPolyVerts = lxq("query layerservice poly.vertList ? $newestPoly");
		my @pos1 = lxq("query layerservice vert.pos ? @newestPolyVerts[0]");
		my @pos2 = lxq("query layerservice vert.pos ? @verts[0]");
		my @disp1 = arrMath(@pos1,@center,subt);
		my @disp2 = arrMath(@pos2,@center,subt);
		my $radian1 = atan2(@disp1[2],@disp1[0]);
		my $radian2 = atan2(@disp2[2],@disp2[0]);
		my $angle1 = ($radian1*180)/$pi;
		my $angle2 = ($radian2*180)/$pi;

		#rotate the new disc to match the vert pos of the current row
		lx("select.type polygon");
		lx("select.element $mainlayer polygon set $newestPoly");
		rotateY(\@center,-1*($angle2-$angle1));

		#rotate both of those back to where they were originally
		lx("select.type vertex");
		lx("select.element $mainlayer vertex add $_") for @newestPolyVerts;
		rotateUnFlat(\@center,-1*(@angles[0]+90),-@angles[1]);



		#--------------------------------------------
		#MAKE SURE the (CURRENT) vertrow is flowing in the same dir as the current disc
		#--------------------------------------------
		my $distCheck1 = fakeDistance(@newestPolyVerts[1],@verts[1]);
		my $distCheck2 = fakeDistance(@newestPolyVerts[1],@verts[-1]);

		#lxout("distCheck1 = $distCheck1 <><> distCheck2 = $distCheck2");
		if ($distCheck2 < $distCheck1)
		{
			my $initialVert = @verts[0];
			@verts = reverse(@verts);
			pop(@verts);
			splice(@verts, 0, 0, $initialVert);
			#lxout("I'M REVERSING THE VERTROW!");
		}


		#--------------------------------------------
		#MOVE THE (CURRENT) VERTROW TO THE CURRENT DISC
		#--------------------------------------------
		my $vertRowCount=0;
		for (my $i = 0; $i < @newestPolyVerts ; $i++){
			my @moveToPos = lxq("query layerservice vert.pos ? @newestPolyVerts[$i]");
			lx("vert.move @verts[$i] {@moveToPos[0]} {@moveToPos[1]} {@moveToPos[2]}");

			#MOVE THE SYMMETRICAL VERTROW
			if ($symmAxis != 3){
				#find the symmetrical Vert
				my $symmetricalVert = -1;

				if ($foundSymmetricalRow != -1){
					foreach my $vert (@{$vertRowTable{$foundSymmetricalRow}}){
						if (($vertPosTable{$vert}[$symmAxis] == (($vertPosTable{@verts[$i]}[$symmAxis])*-1)) && ($vertPosTable{$vert}[$nonSymmAxis1] == ($vertPosTable{@verts[$i]}[$nonSymmAxis1])) && ($vertPosTable{$vert}[$nonSymmAxis2] == ($vertPosTable{@verts[$i]}[$nonSymmAxis2]))){
							$symmetricalVert = $vert;
							last;
						}
					}
				}elsif ($i == 0){
					foreach my $key2 (keys %vertRowTable){
						if (($skipRows{$key2} != 1) && ($foundSymmetricalRow == -1)){
							foreach my $vert (@{$vertRowTable{$key2}}){
								if (($vertPosTable{$vert}[$symmAxis] == (($vertPosTable{@verts[$i]}[$symmAxis])*-1)) && ($vertPosTable{$vert}[$nonSymmAxis1] == ($vertPosTable{@verts[$i]}[$nonSymmAxis1])) && ($vertPosTable{$vert}[$nonSymmAxis2] == ($vertPosTable{@verts[$i]}[$nonSymmAxis2]))){
									$symmetricalVert = $vert;
									$foundSymmetricalRow = $key2;
									#lxout("vertRow $key <> foundSymmetricalRow = $foundSymmetricalRow");
									$skipRows{$key2} = 1;
									last;
								}
							}
						}
					}
				}

				#move the symmetrical vert.
				if ($symmetricalVert != -1){
					if ($symmAxis == 0) 	{	@moveToPos[0] *= -1;	}
					elsif ($symmAxis == 1) 	{	@moveToPos[1] *= -1;	}
					elsif ($symmAxis == 2) 	{	@moveToPos[2] *= -1;	}
					lx("vert.move $symmetricalVert {@moveToPos[0]} {@moveToPos[1]} {@moveToPos[2]}");
				}else{
					lxout("couldn't find the symmetrical vert for @verts[$i]");
				}
			}
		}
	}
	else{lxout("[->] : skipping row ($key) because it was symmetrical");}
}





#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------[SCRIPT IS FINISHED] SAFETY REIMPLEMENTING-----------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#Set the action center settings back
if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

#Set the layer reference back
lx("!!layer.setReference [$layerReference]");

#Set the workplane back
if ((@backupWP[0] == 0) && (@backupWP[1] == 0) && (@backupWP[2] == 0) && (@backupWP[3] == 0) && (@backupWP[4] == 0) && (@backupWP[5] == 0))
{
	lxout("RESETTING THE WORKPLANE");
	lx("workplane.reset");
}
else
{
	lxout("PUTTING THE ORIGINAL (CUSTOM) WORKPLANE BACK");
	lx("workplane.reset");
	lx("workPlane.edit {@backupWP[0]} {@backupWP[1]} {@backupWP[2]} {@backupWP[3]} {@backupWP[4]} {@backupWP[5]}");
}

#delete the temp polys
my $newPolyCount = lxq("query layerservice poly.n ? all");
my $newPolys = $newPolyCount - $polyCount;
lx("select.drop polygon");
for (my $i=1; $i<$newPolys+1; $i++){
	$poly = $newPolyCount-$i;
	lx("select.element $mainlayer polygon add $poly");
}
if ($newPolys > 0){lx("delete");}

#Set the selection back if in VERT or POLY mode.
if (($sel_type eq "vertex") || ($sel_type eq "polygon")){
	lx("!!select.drop $sel_type");
	lx("!!select.useSet senePC select");
	lx("!!select.editSet senePC remove");
}else{
	lx("!!select.type $sel_type");
}


#Set the symmetry mode back
if ($symmAxis != 3)
{
	#CONVERT MY OLDSCHOOL SYMM AXIS TO MODO's NEWSCHOOL NAME
	if 		($symmAxis == "3")	{	$symmAxis = "none";		}
	elsif	($symmAxis == "0")	{	$symmAxis = "x";		}
	elsif	($symmAxis == "1")	{	$symmAxis = "y";		}
	elsif	($symmAxis == "2")	{	$symmAxis = "z";		}
	lxout("turning symm back on ($symmAxis)"); lx("!!select.symmetryState $symmAxis");
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------------SUBROUTINES---------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------------------------------
#THREE ROTATE subroutines that are temp subs just for this script alone.
#-----------------------------------------------------------------------------------------------------------
sub rotateY{
	lx("tool.set xfrm.rotate on");
	lx("tool.reset");
	lx("tool.setAttr center.auto cenX {@{@_[0]}[0]}");
	lx("tool.setAttr center.auto cenY {@{@_[0]}[1]}");
	lx("tool.setAttr center.auto cenZ {@{@_[0]}[2]}");

	lx("tool.setAttr axis.auto axisX {0.0}");
	lx("tool.setAttr axis.auto axisY {1.0}");
	lx("tool.setAttr axis.auto axisZ {0.0}");
	lx("tool.setAttr axis.auto axis {1}");
	lx("tool.setAttr axis.auto upX {0.0}");
	lx("tool.setAttr axis.auto upY {0.0}");
	lx("tool.setAttr axis.auto upZ {1.0}");
	lx("tool.setAttr xfrm.rotate angle {@_[1]}");
	lx("tool.doApply");
}

sub rotateUnFlat{
	lx("tool.set xfrm.rotate on");
	lx("tool.reset");
	lx("tool.setAttr center.auto cenX {@{@_[0]}[0]}");
	lx("tool.setAttr center.auto cenY {@{@_[0]}[1]}");
	lx("tool.setAttr center.auto cenZ {@{@_[0]}[2]}");

	lx("tool.setAttr axis.auto axisX {1.0}");
	lx("tool.setAttr axis.auto axisY {0.0}");
	lx("tool.setAttr axis.auto axisZ {0.0}");
	lx("tool.setAttr axis.auto axis {0}");
	lx("tool.setAttr axis.auto upX {0.0}");
	lx("tool.setAttr axis.auto upY {1.0}");
	lx("tool.setAttr axis.auto upZ {0.0}");
	lx("tool.setAttr xfrm.rotate angle {@_[2]}");
	lx("tool.doApply");

	lx("tool.setAttr axis.auto axisX {0.0}");
	lx("tool.setAttr axis.auto axisY {1.0}");
	lx("tool.setAttr axis.auto axisZ {0.0}");
	lx("tool.setAttr axis.auto axis {1}");
	lx("tool.setAttr axis.auto upX {0.0}");
	lx("tool.setAttr axis.auto upY {0.0}");
	lx("tool.setAttr axis.auto upZ {1.0}");
	lx("tool.setAttr xfrm.rotate angle {@_[1]}");
	lx("tool.doApply");

	lx("tool.set xfrm.rotate off");
}

sub rotateFlat{
	lx("tool.set xfrm.rotate on");
	lx("tool.reset");
	lx("tool.setAttr center.auto cenX {@{@_[0]}[0]}");
	lx("tool.setAttr center.auto cenY {@{@_[0]}[1]}");
	lx("tool.setAttr center.auto cenZ {@{@_[0]}[2]}");

	lx("tool.setAttr axis.auto axisX {0.0}");
	lx("tool.setAttr axis.auto axisY {1.0}");
	lx("tool.setAttr axis.auto axisZ {0.0}");
	lx("tool.setAttr axis.auto axis {1}");
	lx("tool.setAttr axis.auto upX {0.0}");
	lx("tool.setAttr axis.auto upY {0.0}");
	lx("tool.setAttr axis.auto upZ {1.0}");
	lx("tool.setAttr xfrm.rotate angle {@_[1]}");
	lx("tool.doApply");

	lx("tool.setAttr axis.auto axisX {1.0}");
	lx("tool.setAttr axis.auto axisY {0.0}");
	lx("tool.setAttr axis.auto axisZ {0.0}");
	lx("tool.setAttr axis.auto axis {0}");
	lx("tool.setAttr axis.auto upX {0.0}");
	lx("tool.setAttr axis.auto upY {1.0}");
	lx("tool.setAttr axis.auto upZ {0.0}");
	lx("tool.setAttr xfrm.rotate angle {@_[2]}");
	lx("tool.doApply");

	lx("tool.set xfrm.rotate off");
}



#-----------------------------------------------------------------------------------------------------------
#DIST check subroutine
#-----------------------------------------------------------------------------------------------------------
sub distance
{
	my ($vert1,$vert2) = @_;
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");

	my $disp0 = @vertPos1[0] - @vertPos2[0];
	my $disp1 = @vertPos1[1] - @vertPos2[1];
	my $disp2 = @vertPos1[2] - @vertPos2[2];

	my $dist = sqrt(($disp0*$disp0)+($disp1*$disp1)+($disp2*$disp2));
	return $dist;
}



#-----------------------------------------------------------------------------------------------------------
#cheap DIST check subroutine
#-----------------------------------------------------------------------------------------------------------
sub fakeDistance
{
	my ($vert1,$vert2) = @_;
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");

	my $disp0 = @vertPos1[0] - @vertPos2[0];
	my $disp1 = @vertPos1[1] - @vertPos2[1];
	my $disp2 = @vertPos1[2] - @vertPos2[2];

	my $fakeDist = (abs($disp0)+abs($disp1)+abs($disp2));
	return $fakeDist;
}



#-----------------------------------------------------------------------------------------------------------
#popup subroutine
#-----------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}



#-----------------------------------------------------------------------------------------------------------
#sort Rows subroutine
#-----------------------------------------------------------------------------------------------------------
sub sortRow()
{
	#this first part is stupid.  I need it to loop thru one more time than it will:
	my @loopCount = @origEdgeList_edit;
	unshift (@loopCount,1);
	#lxout("How many fucking times will I go thru the loop!? = $#loopCount");

	foreach(@loopCount)
	{
		#lxout("[->] USING sortRow subroutine----------------------------------------------");
		#lxout("original edge list = @origEdgeList");
		#lxout("edited edge list =  @origEdgeList_edit");
		#lxout("vertRow = @vertRow");
		my $i=0;
		foreach my $thisEdge(@origEdgeList_edit)
		{
			#break edge into an array  and remove () chars from array
			@thisEdgeVerts = split(/,/, $thisEdge);
			#lxout("-        origEdgeList_edit[$i] Verts: @thisEdgeVerts");

			if (@vertRow[0] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[0] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			else
			{
				$i++;
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];

	my @newArray;
	if		($math eq "add")	{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif	($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif	($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif	($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CROSSPRODUCT SUBROUTINE (in=2vec out=1vec)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @crossProduct = crossProduct(\@vector1,\@vector2);
sub crossProduct{
	my @vector1 = @{$_[0]};
	my @vector2 = @{$_[1]};

	#create the crossproduct
	my @cp;
	@cp[0] = (@vector1[1]*@vector2[2])-(@vector2[1]*@vector1[2]);
	@cp[1] = (@vector1[2]*@vector2[0])-(@vector2[2]*@vector1[0]);
	@cp[2] = (@vector1[0]*@vector2[1])-(@vector2[0]*@vector1[1]);
	return @cp;
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#UNIT VECTOR SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector = unitVector(@vector);
sub unitVector{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1),(@_[2]/$dist1));
	return @_;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS GETS A HEADING AND PITCH FROM A UNIT VECTOR subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires ACOS sub
#my @angles = headingPitch(@unitVector);
sub headingPitch  #use this with a unit vector.  #NEEDS acos subroutine
{
	my @unitVector = @_;
	my $pi=3.14159265358979323;

	#heading=theta <><> pitch=phi
	my $heading = atan2(@unitVector[2],@unitVector[0]);
	my $pitch = acos(@unitVector[1]);
	#convert radians to euler angles.
	$heading = ($heading*180)/$pi;
	$pitch = ($pitch*180)/$pi;

	#lxout("heading = $heading");
	#lxout("pitch = $pitch");
	return ($heading,$pitch);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ACOS subroutine (radians)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
##heading=theta <><> pitch=phi <><> Also, by default, (heading 0 = X+) <><> (pitch0 = Y+)
#my $heading = atan2(@disp[2],@disp[0]);
#my $pitch = acos(@disp[1]);
#$heading = ($heading*180)/$pi;
#$pitch= ($pitch*180)/$pi;
sub acos {
	atan2(sqrt(1 - $_[0] * $_[0]), $_[0]);
}

