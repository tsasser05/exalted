#!/usr/bin/perl -w

# $Id: dragonBlooded.pl,v 1.5 2003/07/02 21:25:47 moo Exp moo $

use strict;
use diagnostics;
use Carp;
use Getopt::Std;
use Exalted;


#######################################################

# TBD ... fix srand so the seed comes from snarfing
# /dev/random and gzip that
srand ( time ^ $$ ^ unpack "%L*", `ps axww | gzip` );


#######################################################

# data

my %options = ();


my %char = ( 
	     'attributes'	=> {},
	     'abilities'	=> {},
	     'backgrounds'	=> {},
	     'virtues'		=> {},
	     'willpower'	=> {},
	     'essence'		=> {},
	     'charms'		=> {},
	     'meta'		=> {},
	     'info'		=> {},

	     );

my $abilities = { 'air'   => [ 'linguistics', 'lore', 'occult', 'stealth', 'thrown' ],
		  'earth' => [ 'awareness', 'craft', 'endurance','martial_arts', 'resistance' ],
		  'fire'  => [ 'athletics', 'dodge', 'melee', 'presence', 'socialize' ],
		  'water' => [ 'brawl', 'bureaucracy', 'investigation', 'larceny', 'sail' ],
		  'wood'  => [ 'archery', 'medicine', 'performance', 'ride', 'survival' ] 

		  };


#######################################################

getopts ( "a:c:C:d:D:n:N:t:T:", \%options );
setOptions ( \%options, %char );

print "before meta\n";
Exalted::init ( $abilities, %char );
print "after meta\n";

exit;

info ( %char );
attributes ( %char );
abilities ( %char );
backgrounds ( %char );
virtues ( %char );
willpower ( %char );
essence ( %char );
charms ( %char );
show ( %char );


#######################################################
#
# setOptions ()
#
# Handles the conversion of single letter command line
# options to useful arguments for characters.
#
#
#######################################################

sub setOptions {

    my ( $options, %char ) = @_;

    # aspect, caste, etc
    if ( $options -> { a } ) { $char { meta } -> { class } = $options -> { a }; }

    # number of charms to add to the character
    if ( $options -> { c } ) { 
	$char { meta } -> { numCharms }	= $options -> { c }; 

    } else {
	$char { meta } -> { numCharms }	= 7; 

    } # if

    # character concept
    if ( $options -> { C } ) { $char { meta } -> { concept } = $options -> { C }; }

    # program base directory -- contains templates dir
    if ( $options -> { d } ) {
 	$char { meta } -> { dir } = $options -> { d }; 

    } else {
	$char { meta } -> { dir } = ".";

    } # if d

    #######################################################
    #
    # Debug Levels
    #
    # 0 Quiet mode ... everything suppressed
    # 1 Normal operational messages
    # 2 Debugging markers
    # 3 Function calls
    # 4 Data validation
    # 5	TBD
    #
    #
    #######################################################
    if ( $options -> { D } ) { 
	$char { meta } -> { debug } = $options -> { D }; 

    } else {
	$char { meta } -> { debug } = 1;

    } # if D

    # character name
    if ( $options -> { n } ) { $char { meta } -> { name }	= $options -> { n }; }

    # character nature
    if ( $options -> { N } ) { $char { meta } -> { nature }	= $options -> { N }; }

    # type by game:  solar, dragon, etc
    if ( $options -> { t } ) { 
	$char { meta } -> { type } = $options -> { t }; 

    } else {
	$char { meta } -> { type } = "dragon";

    } # if t

    # template directory
    if ( $options -> { T } ) { 
	$char { meta } -> { template }	= $options -> { T }; 

    } else {
	$char { meta } -> { template }	= "./templates";

    } # if T

} # setOptions ()


#######################################################

__END__

$Log: dragonBlooded.pl,v $
Revision 1.5  2003/07/02 21:25:47  moo
Character generator works.

TBD:

1)	Make this script generic based upon game type so it looks
	in the proper templates directory.
2)	Fix the templates...currently using Vampire templates.
3)	Fix the charm generator.  It misses charms if the character
	does not meet the requirements.  However, you can get around
	this by setting -c to a high number, like 30.  This has been
	generating characters with an average of 25 charms!

Revision 1.4  2003/07/01 21:59:03  moo
added charms ()

Revision 1.3  2003/06/25 21:59:19  moo
*** empty log message ***

Revision 1.2  2003/06/25 21:37:22  moo
*** empty log message ***

Revision 1.1  2003/06/25 15:32:43  moo
Initial revision

