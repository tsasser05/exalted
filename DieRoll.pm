package DieRoll;

# $Id: DieRoll.pm,v 1.1 2003/06/25 15:33:27 moo Exp moo $


#######################################################
#
# package DieRoll
#
# Handles all random number generation functions.
#
#
#######################################################

$VERSION = 0.07;

use Carp;
use strict;
use diagnostics;
use Math::Random;
use Exporter;
use PerlUtils;

our @ISA = qw ( Exporter );
our @EXPORT = qw ( rollDie rollDice checkRoll roll rollList distribute generateList randomItem );


#######################################################

# Globals

my $random;
my @rolls;
my $debug = 0;

if ( ! defined $ENV { DEBUG } || ! defined $debug ) {

    $debug = 0;
    
} else {

    $debug = $ENV { DEBUG };

} # if


#######################################################
#
# rollDie ()
#
# Rolls one d10 and returns it.
#
#
#######################################################

sub rollDie {

    return $random = random_uniform_integer ( 1, 1, 10);

} # sub roll ()


#######################################################
#
# rollDice ( $number )
#
# Rolls two or more dice and returns reference to array.
#
#
# ARGUMENTS:
#
# $num		number of d10 dice to roll.
#
#
# OUTPUT:
#
# Returns an array reference containing the results.
#
#
#######################################################

sub rollDice {

  my ( $num ) = @_;
  
  if ( ! defined $num || $num == 0 || $num == 1 ) {

    die "DieRoll::rollDice:  must specify 2 or more dice to roll\n";

  } # if

  for ( my $i = 0; $i < $num; $i++ ) {

    $random = random_uniform_integer ( $num, 1, 10 );
    chomp ( $random );
    $rolls [ $i ] = $random;

  } # for

  return \@rolls;

} # sub rollDice



#######################################################
#
# roll ()
#
# Rolls a die with given maximum.  Used for generating
# random numbers.
#
# ARGUMENTS:
#
# $min		Minimum random value.
#
# $max		Maximum random value.
#
# OUTPUT:
#
# Returns one random number between $min and $max.
#
#
#######################################################

sub roll {

    my ( $min, $max ) = @_;

    return $random = random_uniform_integer ( 1, $min, $max );

} # roll ()


#######################################################
#
# checkRoll ( $target, $rollRef )
#
# Checks the d10 roll against a specified target number
# and reports the number of successes or botches
#
# ARGUMENTS:
#
# $target	Target number from 1 to 10
# $rollRef	Reference to array containing the current rolls
#
# OUTPUT:
#
# Returns the number of successes.  A negative number
# indicates botches.
#
#
#######################################################

sub checkRoll {

  my ( $target, $rollRef ) = @_;

  my $successes = 0;

  print "target = ", $target, "\n";

  for ( my $i = 0; $i < @$rollRef; $i++ ) {

    if ( $debug > 3 ) {
      
      print "rollref ", $i, " = ", $$rollRef [ $i ], "\n"; 

    } # if

    if ( $$rollRef [ $i ] >= $target ) {
      
      ++$successes;

    } elsif ( $$rollRef [ $i ] <= $target && $$rollRef [ $i ] > 1 ) {

      next;

    } else {  # it's a botch

      --$successes;

    } # if

  } # for


  if ( $successes >= 1 ) {

    print "number of successes = ", $successes, "\n";

  } elsif ( $successes == 0 ) {

    print "you rolled ZERO successes\n";

  } elsif ( $successes < 0 ) {

    print "number of botches rolled = ", abs ( $successes ), "\n";

  } else {

    die "DieRoll::checkRoll ():  evaluation of the roll failed\n$!\n";

  } # if

  return $successes;
  
} # sub checkRoll


#######################################################
#
# rollList ()
#
# Rolls a number of times equal to $num.  
#
# ARGUMENTS:
#
# $num		number of times to roll
#
# $min		minimum random value.
#
# $max		maximum random value.
#
# OUTPUT:
#
# Returns an array reference containing all the rolls.
#
#
#######################################################

sub rollList {

    my ( $num, $min, $max ) = @_;

    my @list = random_uniform_integer ( $num, $min, $max );

    return \@list;

} # rollList ()


#######################################################
#
# distribute ()
#
# This function receives the controlling factors from
# the routing caller and distributes its rolls over
# the entire list.
#
# ARGUMENTS:
#
# $current	hash ref containing copy of current 
#		keys/values
#
# $points	number of points to distribute
#
# $min		minimum value allowed
#
# $max		maximum value allowed
#
#
# OUTPUT:	Returns a hash reference containing the
#		distributed rolls.
#
#
#######################################################

sub distribute {

    my ( $current, $points, $min, $max ) = @_;

    my @list = keys %$current;

    my $len = @list;
    my $sum = 0;

    # verify minimum first
    foreach ( @list ) {

	last if $sum >= $points; 

	my $cv = $current -> { $_ };
	my $diff = $min - $cv;
	    
	if ( $cv < $min ) {
		
	    $current -> { $_ } += $diff;
	    $sum += $diff;
	    
	} # if
	
    } # foreach
    
    while ( $sum < $points ) {

	my $index = roll ( 0, $len - 1 );
	my $cv = $current -> { $list [ $index ] };

	if ( $cv < $max ) {

	    $current -> { $list [ $index ] } += 1;
	    ++$sum;

	} else {

	    # skip
	    next;

	} # if

    } # while

    return $current;

} # sub distribute ()


#######################################################
#
# generateList ()
#
# Generates a hash of random character attributes and
# corresponding values.
#
#
# ARGUMENTS:
#
# $list		array ref to list attributes.  the function
#		will iterate over this list.
#
# $points	number of points to assign
#
# $min		minimum value for statistic 
#
# $max		maximum value for each attribute
#
# OUTPUT:
#
# Returns a hash reference containing randomly chosen
# attributes and their random values.
#
#
#######################################################

sub generateList {

    my ( $list, $points, $min, $max ) = @_;

    my $result = {};
    my $length = @$list;

    print "DieRoll::generateList ():  points = $points\n" if $debug > 1;
    print "DieRoll::generateList () called\n" if $debug > 1;
    print "DieRoll::generateList ():  length of array \$list = $length\n" if $debug > 1;

    my @rolls = () if $debug > 1;

    while ( $points > 0 ) {

	my $index = roll ( 0, $length - 1 );

	# get an item from the list
	my $tag = @$list [ $index ];
	chomp $tag;

	# roll again if the attribute is already present
        next if exists $result -> { $tag };

	my $roll = roll ( $min, $max );

	if ( $roll > $points ) {

	    $roll = $points;
	    $points -= $roll;
	    $result -> { $tag } = $roll; 
	    push ( @rolls, $roll ) if $debug > 2;

	} else { 

	    # do not record 0 level statistics

	    if ( $roll > 0 ) { 
		
		$result -> { $tag } = $roll; 
		push ( @rolls, $roll ) if $debug > 1;
		$points -= $roll;
	
	    } # if

	} # if

    } # while

    if ( $debug > 1 ) {

	my $sum = 0;

	    foreach ( @rolls ) {

		$sum += $_;

	    } # foreach

	print "sum = $sum\n";

    } # if

    return $result;

} # sub generateList ()


#######################################################
#
# randomItem ()
#
# Grabs a random string from a template file and returns
# it. 
#
# ARGUMENTS
#
# $filename	file to read
#
# $num		number of items to return if specified
#
# OUTPUT
#
# If called in list context with $num specified, 
# randomItem () returns a list of random items from
# the file.  Otherwise, it returns a single item.
#
#
#######################################################

sub randomItem {

    my ( $filename, $num ) = @_;

    if ( wantarray && defined $num ) {

	my @items = ();

	my $content = readFile ( $filename, "RANDITEM" );

	for ( my $i = 0; $i < $num; $i++ ) {

	    my $length = @$content;
	    my $index = DieRoll::roll ( 0, $length - 1 );
	    my $item = @$content [ $index ];
	    chomp $item;
	    push ( @items, $item );

	} # for

	return @items;

    } elsif ( ! defined $num ) {

	my $content = readFile ( $filename, "RANDITEM" );
	my $length = @$content;
	my $index = DieRoll::roll ( 0, $length - 1 );
	my $item = @$content [ $index ];
	chomp $item;
	return $item;
	
    } else {

	croak "DieRoll::randomItem ():  incorrect argument pattern.  do not specify number if calling randomItem in scalar context\n";

    } # IF

} # randomItem ()


#######################################################

1;


#######################################################

__END__


#######################################################

$Log: DieRoll.pm,v $
Revision 1.1  2003/06/25 15:33:27  moo
Initial revision

Revision 1.1  2003/06/07 20:06:57  moo
Initial revision


#######################################################

=begin

    # old distribute ()
    my ( $num, $points, $currentList, $min, $max, $rollMin, $rollMax ) = @_;

    print "distribute () called\n" if $debug > 3;

    my $sum = 0;

    my $rollList = DieRoll::rollList ( $num, $rollMin, $rollMax );

    if ( $debug > 2 ) {

	foreach ( @$rollList ) {

	    print "rollList:  roll = $_\n";

	} # foreach

    } # if

    foreach ( @$rollList ) {

	$sum += $_;
	
    } # foreach

    #print "distribute ():  sum = $sum\n" if $debug > 2;

    # modify rolls to match number of points

    if ( $sum == $points ) {

	print "leaving distribute ()\n" if $debug > 3;
	return $rollList;

    } elsif ( $sum > $points ) {

	# start subtracting until $sum equals points

	while ( $sum > $points ) {
	    
	    print "DieRoll::distribute ():  subtracting points\n";
	    my $index = DieRoll::roll ( $rollMin, $num - 1 );
	    
	    die "DieRoll::distribute ():  current value is less than minimum\n" 
		if @$currentList [ $index ] < $min;
	    next if @$currentList [ $index ] == $min;
	    # next if @$rollList [ $index ] <= $min;	    

	    @$rollList [ $index ] -= 1;
	    $sum -= 1;
	    
	} # while

	if ( $debug > 2 ) {

	    print "rolls contents after SUBTRACTING\n";

	    foreach ( @$rollList ) {

		print "rolls:  roll = $_\n";

	    } # foreach

	} # if

	print "leaving distribute () after subtraction\n" if $debug > 3;

	return $rollList;

    } elsif ( $sum < $points ) {

	while ( $sum < $points ) {

	    print "DieRoll::distribute ():  adding points\n";
	    my $index = DieRoll::roll ( $rollMin, $num - 1 );
    
	    die "DieRoll::distribute ():  current value is greater than maximum\n" 
		if @$currentList [ $index ] > $max;

	    next if @$currentList [ $index ] == $max;
	    # next if @$rollList [ $index ] >= $max;

	    @$rollList [ $index ] += 1;
	    $sum += 1;

	} # while

	if ( $debug > 2 ) {

	    print "rolls contents after ADDING\n";

	    foreach ( @$rollList ) {

		print "rolls:  roll = $_\n";

	    } # foreach

	} # if

	print "leaving distribute () after addition\n" if $debug > 3;

	return $rollList;

    } # if
=cut
