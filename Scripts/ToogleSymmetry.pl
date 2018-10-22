#perl
#symmetry is laid out like this: (0=x), (1=y), (2=z),(3=off)
my $symmAxis = lxq("select.symmetryAxis ?");

if ($symmAxis != 3)
{
    $symmAxis = 3;
}
else
{
    $symmAxis = 0;
}
lx("select.symmetryAxis $symmAxis");