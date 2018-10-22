#perl
#BY: Seneca Menard
#version 2.1

#This script will select all of the elements on the object under your mouse.  I made it so I could quickly select a mesh from another layer without having to look thru the layer list or having to switch to item mode and back.
#So what you do is just hold your mouse over an element and it'll put you in that element's layer and select the rest of the elements for you, all in one click.  :)  Also, I just added a new feature that'll let you hide any objects
#that might be in the way before hte selection's made, such as background items.

#SCRIPT ARGUMENTS :
# "no" : if you use that argument, it'll select the item under the mouse, but won't select all of it's elements.
# "backdrop" "light" "camera" "meshInst" "txtrLocator" "groupLocator" etc.  Just type in any entity type names you wish to hide before the selection is made.  (the names have to be modo's exact names)

#(9-15-07 bugfix) : before, it would only select the verts or edges of the mesh under your mouse if your mouse was directly over one, now you can hold your mouse over the center of a poly and it'll still get it's verts or edges.
#(10-21-07 bugfix) : If you were in polygon mode and ran the script, it would accidentally put you in edge mode.  All fixed.
#(2-10-2008 feature) : sometimes, other items get in the way of what you're trying to select and so now the script has a way around that problem.  Just append any types of items you'd want to hide to the end of the script and
	#it'll temporarily hide those before it does the selections.  Here's an example : "@selectThatMesh.pl backdrop light"   That will hide all backdrops and light entities that might have been in the way before it selects the mesh.
#(4-28-08 bugfix) : if you use the arguments that lets you hide objects of certain types, it won't unhide all of the objects of that type anymoe.

#arguments
my @hideTypes;
foreach my $arg (@ARGV){
	if 		($arg eq "no")		{our $no = 1;			}
	else						{push(@hideTypes,$arg);	}
}

#selection modes
if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) 	{	our $selType = "vertex";	}
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{	our $selType = "edge";		}
else															{	our $selType = "polygon";	}

#hide the obstructions
if (@hideTypes > 0){
	our @hidItems;
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		my $type = lxq("query sceneservice item.type ? $i");
		foreach my $hideType (@hideTypes){
			if ($type eq $hideType){
				my $id = lxq("query sceneservice item.id ? $i");

				if (visibleQuery($id) == 1){
					lx("!!layer.setVisibility $id 0");
					push(@hidItems,$id);
					next;
				}
			}
		}
	}
}

#select the mesh
lx("select.type item");
lx("!!select.3DElementUnderMouse set");
if (@ARGV[0] ne "no"){
	lx("select.type polygon");
	lx("!!select.3DElementUnderMouse set");
	if ($selType ne "polygon"){lx("select.convert $selType");}
	lx("!!select.connect");
}else{
	lx("!!select.type $selType");
}

#unhide the obstructions
if (@hidItems > 0){foreach my $id (@hidItems){lx("!!layer.setVisibility $id 1");}}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ITEM VISIBILITY QUERY
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : if (visibleQuery(mesh024) == 1){}
sub visibleQuery{
	my $name = lxq("query sceneservice item.name ? @_[0]");
	my $channelCount = lxq("query sceneservice channel.n ?");
	for (my $i=0; $i<$channelCount; $i++){
		if (lxq("query sceneservice channel.name ? $i") eq "visible"){
			if (lxq("query sceneservice channel.value ? $i") ne "off"){
				return 1;
			}else{
				return 0;
			}
		}
	}
}
