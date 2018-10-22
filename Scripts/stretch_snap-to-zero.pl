#perl
#AUTHOR: Seneca Menard
#version 1.1
#Stretch  snap to zero script.
#(9-9-06 bugfix) : I had code in the script to snap any stretches that were below 0% to -100%, but that was failing because modo's script system doesn't allow us to modify the currently active transfmation, it
# only allows us to apply new transformations.. :(  So, if you were stretched to -40%X, it'd apply that and another -100%X and so you'd get an end transform of 140%X and that's not what was intended.  I'll put that code back in when it'll work...  :)
#(9-30-06 bugfix) : The script previously only used to work with the old stretch tool.  It now works with the Modo2 Transform and TransformScale tools.

if( lxq( "tool.set xfrm.stretch ?") eq "on" ){
    my $X = lxq("tool.attr xfrm.stretch factX ?");
    my $Y = lxq("tool.attr xfrm.stretch factY ?");
    my $Z = lxq("tool.attr xfrm.stretch factZ ?");

    if ($X != 1)    {    lx("tool.attr xfrm.stretch factX 0");    }
    if ($Y != 1)    {    lx("tool.attr xfrm.stretch factY 0");    }
    if ($Z != 1)    {    lx("tool.attr xfrm.stretch factZ 0");    }

    lx("tool.doApply");
    lx("tool.set xfrm.stretch off");
}

elsif((lxq( "tool.set TransformScale ?") eq "on") || (lxq("tool.set Transform  ?") eq "on")){
    my $X = lxq("tool.attr xfrm.transform SX ?");
    my $Y = lxq("tool.attr xfrm.transform SY ?");
    my $Z = lxq("tool.attr xfrm.transform SZ ?");

    if ($X != 1)    {    lx("tool.attr xfrm.transform SX 0");    }
    if ($Y != 1)    {    lx("tool.attr xfrm.transform SY 0");    }
    if ($Z != 1)    {    lx("tool.attr xfrm.transform SZ 0");    }

    lx("tool.doApply");
    lx("tool.set xfrm.stretch off");
}

sub popup #(MODO2 FIX)
{
    lx("dialog.setup yesNo");
    lx("dialog.msg {@_}");
    lx("dialog.open");
    my $confirm = lxq("dialog.result ?");
    if($confirm eq "no"){die;}
}