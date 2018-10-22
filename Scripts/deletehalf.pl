#perl
#AUTHOR: Seneca Menard
#version 1.2  (modo2)
#(3-17-07 fix) : the warning window wasn't working properly.

#This script will look at all the polygons you have selected and delete whichever are below zero in whatever axis you picked
#You have to append "x","y",or "z" to the script, and "-" if you want to delete the negative half of the axis
#ex: @deletehalf.pl z -


my $mainlayer = lxq("query layerservice layers ? main");
my @arrVertex;
my @posA;
my $num;
my $half=1;

#---------------------------------------------------------------------------------------------------
#Look thru the variables to choose the proper axis
#---------------------------------------------------------------------------------------------------
foreach $arg(@ARGV)
{
	if ($arg eq "x")
	{
		$num = 0;
	}
	if ($arg eq "y")
	{
		$num = 1;
	}
	if ($arg eq "z")
	{
		$num = 2;
	}
	if ($arg eq "-")
	{
		$half=2;
	}
}


#---------------------------------------------------------------------------------------------------
#check if you have polygons selected and warn you if you don't
#---------------------------------------------------------------------------------------------------
if(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) && lxq( "select.count polygon ?" ))
{
	#If there's a polygon selection, the script will run on that selection
	lx("select.connect"); #select rest of model
	lx("select.convert vertex");
	@arrVertex = lxq("query layerservice verts ? selected");
}
elsif(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) && lxq( "select.count vertex ?" ))
{
	lxout("[->] VERT SELECTION MODE");
	#lx("select.connect");
	@arrVertex = lxq("query layerservice verts ? selected");
}
else
{
	#This will bring up the warning window
	lx("dialog.setup yesNo");
	lx("dialog.msg {You have no polygons selected.  Are you sure you want to delete one half of all that's visible?}");
	lx("dialog.open");
	$confirm = lxq("dialog.result ?");
	if($confirm eq "no")
	{
		die("Script Aborted.");
	}
	#Runs the script because you said "yes"
	lx("select.drop vertex");
	lx("select.invert");
	@arrVertex = lxq("query layerservice verts ? selected");
}


#---------------------------------------------------------------------------------------------------
#select all verts on one side of the chosen axis
#---------------------------------------------------------------------------------------------------
#start selection from scratch and reselect one half
lx("select.drop vertex");

foreach my $arrVert(@arrVertex)
{
	@posA = lxq("query layerservice vert.pos ? $arrVert");
	if($num == 2) #fixes Z bug
	{
		if($half == 1)
		{ #delete lesser half
			if($posA[$num] <= 0.00000001)
			{
				lx("select.element [$mainlayer] vertex add index:$arrVert");
			}
		}
		else
		{ #delete greater half
			if($posA[$num] >= -0.00000001)
			{
				lx("select.element [$mainlayer] vertex add index:$arrVert");
			}
		}
	}
	else #fixes Z bug
	{
		if($half == 2)
		{ #delete lesser half
			if($posA[$num] <= 0.00000001)
			{
				lx("select.element [$mainlayer] vertex add index:$arrVert");
			}
		}
		else
		{ #delete greater half
			if($posA[$num] >= -0.00000001)
			{
				lx("select.element [$mainlayer] vertex add index:$arrVert");
			}
		}
	}
}


#---------------------------------------------------------------------------------------------------
#convert selected verts to polygons and delete 'em
#---------------------------------------------------------------------------------------------------
lx("select.convert polygon");
if (lxq("select.count polygon ?"))
{
	lx("delete");
}



#-----------------------------------------------------------------------------------------------------------
#POPUP SUBROUTINE
#-----------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
