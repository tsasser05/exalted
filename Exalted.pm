package Exalted;

# $Id: Exalted.pm,v 1.8 2003/07/02 21:23:39 moo Exp moo $

use strict;
use diagnostics;
use Carp;

use DieRoll;
use PerlUtils;

use Exporter;
our @ISA = qw ( Exporter );
our @EXPORT = qw ( abilities attributes backgrounds charms essence info init show virtues willpower );


#######################################################
#
# abilities ()
#
#
#######################################################

sub abilities {

    my ( %char ) = @_;

    # copy abilities
    my %abilities = %{ $char { meta } -> { abilities } };
    my $class = $char { info } -> { class };
    #print "class = $class\n";

    # separate class abilities from all other abilities
    my @classPool = @{ $char { meta } -> { abilities } -> { $class } };
    my @generalPool = buildGeneralPool ( $class, %abilities );

    # merge generalPool
    my @general = ();

    foreach my $t ( @generalPool ) {

	my $type = lc ( $t );
	
	#print "type = $type\tclass = $class\n";
	next if $type eq $class;

	foreach my $ability ( @{ $abilities { $type } } ) {
	    push ( @general, $ability );	    

	} # foreach

    } # foreach

    #print "classPool =  @classPool\n";
    #print "generalPool = @general\n";


    # start ability assignments
    
    foreach my $ability ( @classPool ) {
	$char { abilities } -> { $ability } = roll ( 1, 5 );
	$char { meta } -> { total } += ( $char { abilities } -> { $ability } ) * 2;

    } # foreach

    my $x = 0;

    my $numOtherAbil = roll ( 1, 20 );
    #print "number of abilities = $numOtherAbil\n";

    while ( $x < $numOtherAbil ) {
	my $length = @general;
	last if $length == 0;
#	print "general length = $length\n";
	my $index = roll ( 0, $length - 1  );
	my $ability = splice ( @general, $index, 1 );
	$char { abilities } -> { $ability } = roll ( 1, 5 );
	$char { meta } -> { total } += ( $char { abilities } -> { $ability } ) * 2;
	$x++;

    } # while

} # abilities ()


#######################################################
#
# attributes ()
#
# Populates character attributes ( key = attributes )
# with random values and updates the point total.
#
#
#######################################################

sub attributes {

    my ( %char ) = @_;

    my @attr = qw ( strength dexterity stamina
		    charisma manipulation appearance
		    perception intelligence wits );

    foreach my $attr ( @attr ) {
	$char { attributes } -> { $attr } = roll ( 1, 5 );
	$char { meta } -> { total } += ( $char { attributes } -> { $attr } ) * 4;

    } # foreach

} # attributes ()


#######################################################
#
# backgrounds ()
#
# Randomly chooses backgrounds.  Setting the backgrounds
# flag from the command line will choose that number
# of backgrounds, but the levels will still be random.
#
#
#######################################################

sub backgrounds {

    my ( %char ) = @_;

    my $temDir = $char { meta } -> { template };
    print "Exalted::backgrounds ():  temdir = $temdir\n";
    my $file = $temDir . "/backgrounds";


    my $bgList = readFile ( $file );
    my $num = 0;

    # handle commandline switch or generate random bg
    if ( defined $char { meta } -> { backgrounds } ) {
	$num = $char { meta } -> { backgrounds };

    } else {
	$num = roll ( 1, 10 );

    } # if

    my $x = 0;
    
    while ( $x < $num ) {
	my $length = @{ $bgList } - 1;
	my $index = roll ( 0, $length );
	my $bg = splice ( @{ $bgList }, $index, 1 );
	chomp $bg;
	$char { backgrounds } -> { $bg } = roll ( 1, 5 );
	$char { meta } -> { total } += $char { backgrounds } -> { $bg };
	$x++;
	
    } # while 

} # backgrounds ()


#######################################################
#
# charms ()
#
#
#######################################################

sub charms {

    my ( %char ) = @_;

    my $charmPoints = $char { meta } -> { numCharms };
    my $dir = $char { meta } -> { dir };
#    print "dir = $dir\n";
    my $tem = $char { meta } -> { template };
#    print "tem = $tem\n";
    my $file = $dir . "/$tem" . "/dragonCharms.db";
#    print "file = $file\n";
    my $charmsDB = load ( $file );
#    print "charmsDB = $charmsDB\n";
    #no strict 'refs';
    # get list of character abilities
    my @abilityList = keys %{ $char { abilities } };
#    print "abilityLIst = ";
#    print "@abilityList\n";
    my $abilityListLen = @abilityList - 1;
#    print "abilityListLen = $abilityListLen\n";

    while ( $charmPoints > 0 ) {
	
	# random charm type from character's abilities
	my $ability = lc ( $abilityList [ roll ( 0, $abilityListLen ) ] );
	#print "setCharms ():  charm ability = $ability\n";
	
	# random root charm code
	my $rootCode = getRootCharm ( $charmsDB, $ability );
	#print "setCharms ():  code = $rootCode\n";

	# set start of track
	if ( validate ( $rootCode, $ability, $charmsDB, %char ) ) {
	    #print "setCharm ():  setting charm\n";
	    $char { charms } -> { $ability } -> { $rootCode } = $charmsDB -> { $ability } -> { $rootCode };
	    --$charmPoints;

	} else {
	    # bail out to next iteration and ( hopefully ) a new track
	    #print "setCharm ():  skipping charm due to validate failure ()\n";
	    next;

	} # if

	my @trackCodes = sort keys %{ $charmsDB -> { $ability } };


	# slice out $rootCode
	my $index;
	for ( my $i = 0; $i < @trackCodes; $i++ ) {
	    $index = $i;
	    last if ( $trackCodes [ $i ] == $rootCode );
	    
	} # for
	
	#print "trackCodes before splice--->@trackCodes\n";
	splice ( @trackCodes, $index, 1 );
	#print "trackCodes AFTER splice--->@trackCodes\n";



	my $trackSize = keys %{ $charmsDB -> { $ability } };
	#print "track size = $trackSize\n";

	if ( $trackSize > $charmPoints ) {
	    $trackSize = $charmPoints;

	} # if
	     
	# MAX points to spend, but stop spending once charms stop qualifying.
	# Using trackpoints makes for a more random character.  Not using it
	# means that the program will go as far down the track as possible.
	my $trackPoints = roll ( 0, $trackSize  );
	#print "track points = $trackPoints\n";
	next if $trackPoints == 0;

	# Walk the track, setting qualifying charms up to the number
	# of track points

	my $counter = 0;
	while ( $counter < $trackPoints ) {

	    #print "setCharm ():  track handler iteration\n";

	    # BUG:  using $i < $trackPoints will be subtle because it will only
	    # iterate on the array up to track points and
	    # disregards subsequent tracks that would normally
	    # qualify
	    #
	    # using sizeof @trackCodes so it has the possibility to
	    # check the entire track

	    # BUG:  will grab another rootCode.

	    for ( my $i = 0; $i < @trackCodes; $i++ ) {
		my $code = $trackCodes [ $i ];
		last if ( $code == 0 );
		#print "setCharm ():  track handler:  current code = $code\n";
		my $val = validate ( $code, $ability, $charmsDB, %char );

		last if ( ! $val || $i >= $trackPoints );

		#print "setCharm ():  setting VALIDATED charm\n";
		$char { charms } -> { $ability } -> { $code } = $charmsDB -> { $ability } -> { $code };
		$counter++;

	    } # for

	    # counter is now X charms larger
	    $charmPoints -= $counter;

	    # break the while loop
	    $counter = $trackPoints;

	} # while flag

    } # while charmPoints

} # charms ()


#######################################################
#
# essence ()
#
#
#######################################################

sub essence {

    my ( %char ) = @_;

    $char { essence } -> { essence } = roll ( 1, 5 );

} # essence ()


#######################################################
#
# info ()
#
#
# Data:
# -n	name
# -t	type	solar | dragon 
# -c	class	this is the aspect/caste, etc
# -n	nature	
# -C	concept
#
#
#######################################################

sub info {

    my ( %char ) = @_;
    
    # for handling command line args
    if ( defined $char { meta } -> { name } ) {
	$char { info } -> { name } = $char { meta } -> { name };

    } else {
	print "What is the character's name?  ";
	my $name = <STDIN>;
	chomp $name;
	$char { info } -> { name } = $name;

    } # if

    # character type
    # TBD ... sanitize $type

    # setting of type should determine available classes and randomly
    # assign one.
    if ( exists $char { meta } -> { type } && defined $char { meta } -> { type } ) {
	$char { info } -> { type } = $char { meta } -> { type };

    } else {
	print "solar | dragon\n";
	print "What type of Exalted character do you want to create?  ";
	my $type = lc ( <STDIN> );
	chomp $type;
	$char { info } -> { type } = $type;

    } # if
    
    # aspect or caste
    # TBD ... sanitize $class
    if ( defined $char { meta } -> { class } ) {
	$char { info } -> { class } = $char { meta } -> { class };

    } else {

	# TBD ... random choice of class goes here based upon type of exalted
	print "what is the class ( caste, aspect, etc ) of the character?  ";
	my $class = lc ( <STDIN> );
	chomp $class;
	$char { info } -> { class } = $class;

    } # if

    my $temDir = $char { meta } -> { template };
    my $natureFile = $temDir . "/personality";
    my $conceptFile = $temDir . "/concepts";

    # nature
    if ( exists $char { meta } -> { nature } && defined $char { meta } -> { nature } ) {
	$char { info } -> { nature } = $char { meta } -> { nature };

    } else {
	my $natureList = readFile ( $natureFile );
	my $length = @{ $natureList };
	my $index = roll ( 0, $length - 1 );
	my $nature = @{ $natureList } [ $index ];
	chomp $nature;
	$char { info } -> { nature } = $nature;
	
    } # if

    # concept
    if ( exists $char { meta } -> { concept } && defined $char { meta } -> { concept } ) {
	$char { info } -> { concept } = $char { meta } -> { concept };

    } else {
	my $conceptList = readFile ( $conceptFile );
	my $length = @{ $conceptList };
	my $index = roll ( 0, $length - 1 );
	my $concept = @{ $conceptList } [ $index ];
	chomp $concept;
	$char { info } -> { concept } = $concept;

    } # if

} # info ()


#######################################################
#
# init ()
#
#
#######################################################

sub init {

    my ( $abilities, %char ) = @_;

    print "Exalted::meta () called\n";
=begin
    $char { meta } -> { abilities } = $abilities;
    $char { meta } -> { total } = 0;

    # now reset where the code looks for templates
    my $dir = $char { meta } -> { dir };
    print "dir = $dir\t";
    my $template = $char { meta } -> { template };
    print "template = $template\t";
    my $game = $char { meta } -> { type };
    print "game = $game\t";
    my $temdir = "$dir/$template/$game"; 
    $char { meta } -> { template } = $temdir;
    print "temdir = $temdir\n";

    print "exiting Exalted::meta ()\n";
=cut

} # init ()


#######################################################
#
# show ()
#
#
#######################################################

sub show {

    my ( %char ) = @_;

    foreach my $type ( keys %char ) {

	next if $type eq 'meta';

	print "\n$type:\n\n";

	if ( $type eq 'charms' ) {

	    foreach my $ability ( sort keys %{ $char { charms } } ) {
		print "\t$ability:\n";

		foreach my $code ( sort keys %{ $char { charms } -> { $ability }} ) { 
		    print "\t\t", $char { charms } -> { $ability } -> { $code } -> { 'name' }, "\n";

		} # foreach code

	    } # foreach ability

	} else {
	    foreach my $key ( keys %{ $char { $type } } ) {
		print "\t$key = ", $char { $type } -> { $key }, "\n";
		
	    } # foreach
	    
	} # if

    } # foreach

} # show ()


#######################################################
#
# virtues ()
#
#
#######################################################

sub virtues {

    my ( %char ) = @_;

    my @virtues = qw ( compassion conviction temperance valor );

    foreach my $v ( @virtues ) {
	$char { virtues } -> { $v } = roll ( 1, 5 );
	$char { meta } -> { total } += ( $char { virtues } -> { $v } ) * 3;

    } # foreach

} # virtues ()


#######################################################
#
# willpower ()
#
#
#######################################################

sub willpower {

    my ( %char ) = @_;

    my %vir = %{ $char { virtues } };
    my @sorted = sort { $vir { $b } <=> $vir { $a } } keys %{ $char { virtues } };
    my $sum = $char { virtues } -> { $sorted[0] } + $char { virtues } -> { $sorted[1] };
    $char { willpower } -> { willpower } = $sum;
#    print "willpower = ", $char { willpower } -> { willpower }, "\n";

    if ( $sum < 10 ) {
	my $max = 10 - $sum;
	my $add = roll ( 0, $max );
	$char { willpower } -> { willpower } += $add;

	if ( $add > 0 ) { 
	    $char { meta } -> { total } += $add * 2;

	} # if

    } # if

} # willpower ()


#######################################################

# local functions

#######################################################


#######################################################
#
# buildGeneralPool ()
#
# local utility function
#
#
#######################################################

sub buildGeneralPool {

    my ( $class, %abilities ) = @_;

    my @generalAbilityPool = ();

    foreach my $key ( keys %abilities ) {
	next if ( $key eq $class );
	push ( @generalAbilityPool, $key );

    } # foreach

    return @generalAbilityPool;

} # buildGeneralPool ()


#######################################################
#
# getRootCharm ()
#
# This function will return a random charm code from
# an ability's charm track list.
#
#
#######################################################

sub getRootCharm {
	
    my ( $charmsDB, $abil ) = @_;

    my $ability = lc ( $abil );
#    print "getRootCharm arg check:  charmsDB = $charmsDB\n";
#    print "getRootCharm arg check:  ability = $ability\n";

    #showCharmsDB ( $charmsDB );
#    print "getRootCharm: before charm types\n";

    my @charmTypes = ();
    foreach my $code ( sort keys %{ $charmsDB -> { $ability } } ) {

	#print "charmsDB code = $code\n";
	
	if ( @{$charmsDB -> { $ability } -> { $code } -> { pre }}[0] == 0 ) {
	    
	    #print "getRootCharm ():  root charm code = $code\n";
	    push ( @charmTypes, $code );
	    
	} # 
	
    } # foreach code

    #print "getRootCharm:  after charm type\n";
    #print "Exalted::getRootCharm ():  charm types = @charmTypes\n";
    my $len = @charmTypes - 1;
    
    if ( $len == 0 ) {
	#print "getRootCharm ():  only 1 root charm: ", $charmTypes[0], "\n";
	return $charmTypes [ 0 ];
	
    } else {
	my $type = $charmTypes [ roll ( 0, $len ) ];
	#print "getRootCharm (): charm type = $type\n";
	return $type;
	
    } # if
    
} # getRootCharm ()


#######################################################
#
# load ()
#
# Loads and returns charms contained within $file.
#
#
#######################################################

sub load {
	
    my ( $file ) = @_;
    
    my $content = readFile ( $file );
    my $charms = {};
    
    foreach ( @{ $content } ) {
	next if $_ =~ /^[\#|\n]\d*/;
	chomp;
	my ( $code, $name, $ability, $min, $ess, @pre ) = split ( /\t+/, $_ );
	
	# load charm data
	$charms -> { $ability } -> { $code } = { 'name' => $name,
						 'min'  => $min,
						 'ess'  => $ess,
						 'pre'  => \@pre
						     
						 };
	
	#print "$code\t$name\t$ability\t$min\t$ess\t-->@pre\n";
	
    } # foreach
    
    return $charms;
    
} # load ()


#######################################################
#
# showCharmsDB ()
#
#
#######################################################

sub showCharmsDB {

    my ( $charmsDB ) = @_;

    print "\n\nCharms DB:\n\n";
    
    foreach my $ability ( sort keys %{$charmsDB} ) {
	
	print "\n$ability:\n";
	
	foreach my $code ( sort keys %{ $charmsDB -> {$ability} } ) {
	    
	    print "\t$code:\n";
	    
	    foreach my $key ( sort keys %{ $charmsDB -> { $ability } -> { $code } } ) {
		
		print "\t\t", $charmsDB -> { $ability } -> { $code } -> { $key }, "\n";
		
	    } # foreach
	    
	} # foreach
	
	
    } # foreach
    
    print "\n\nEnd Charms db\n\n\n";

} # showCharmsDB ()


#######################################################
#
# validate ()
#
#
#######################################################

sub validate {

    my ( $code, $ability, $charmsDB, %char ) = @_;
    #my $ability = ucfirst ( $abil );
    my $abilityMin = $charmsDB -> { $ability } -> { $code } -> { min };
    my $essenceMin = $charmsDB -> { $ability } -> { $code } -> { ess };
    my @prereq = $charmsDB -> { $ability } -> { $code } -> { pre };

    my $statsFlag = 0;
    my $preFlag = 0;

    if ( not exists $char { abilities } -> { $ability } ||
	 $char { abilities } -> { $ability } < $abilityMin ||
	 $char { essence } -> { essence } < $essenceMin ) {

	print "validate ():  failed validation\n";
	return 0;

    } elsif ( $char { abilities } -> { $ability } >= $abilityMin &&
	 $char { essence } -> { essence } >= $essenceMin ) {

	$statsFlag = 1;

    } # if

    foreach my $pre ( @prereq ) {

	if ( exists $char { charms } -> { $ability } -> { $pre } ) {

	    $preFlag += 1;

	} else {

	    next;

	} # if

    } # foreach


    my $preLen = @prereq;

    if ( $statsFlag < 1 && $preFlag < $preLen ) {

	return 0;

    } else { 

	return 1;

    } # if

} # validate ()


#######################################################

1;

__END__

$Log: Exalted.pm,v $
Revision 1.8  2003/07/02 21:23:39  moo
Working character generator with command line args.

BUG:  The generator misses some charms when the character does not
meet the charm's prerequisites.  This could be due to a problem with
the points or in how the getRootCharms () works.  I'm working on
it....

Revision 1.7  2003/07/02 20:10:36  moo
Fully functional script.  However, bugs in the charm handler result in
no depth or in too few charms.  It fails to properly handle charms that do not
validate against the character's attributes.

Revision 1.6  2003/07/01 22:09:31  moo
adding charms ().  need to test.

Revision 1.5  2003/06/25 21:59:19  moo
*** empty log message ***

Revision 1.4  2003/06/25 21:49:59  moo
added essence

Revision 1.3  2003/06/25 21:20:58  moo
everything working except command line arguements, charms and
sorceries.

Revision 1.2  2003/06/25 19:12:56  moo
added attributes, backgrounds, info, show.  the program is setup to
handle command line arguments through the meta hash.

Revision 1.1  2003/06/25 15:32:54  moo
Initial revision

