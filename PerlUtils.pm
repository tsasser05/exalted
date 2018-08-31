package PerlUtils;

#######################################################

#$Id: PerlUtils.pm,v 1.16 2002/02/24 08:23:36 moo Exp moo $

#######################################################

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( readFile openFile closeFile logMessage writeFile dbug );


#######################################################
#
# PerlUtils.pm
#
# contains common utilities used in my programs
#
#
#######################################################

# readFile()
#
# reads in a file specified by $fileName.  $fh_name is the text name of
# the file handle, allowing multiple files to be read.
# 
# this subroutine returns an array containing the snarfed file.
#
# TBD ... memory management / performance issues for huge files.
#

sub readFile {

    my ( $fileName, $fh_name ) = @_;

    my $fh = openFile ( $fileName, $fh_name, "<" );

    my @fileContents = <$fh>;

    my $content = \@fileContents;

    closeFile ( $fh );

    return $content;

} # sub readFile()


#####

# TBD CODE

#####

# snarfs the file pointed to by $fileNameTag in the object hash.  it adapts
# accessors...either accessor() or accessorHOH() based upon the defined arguments.
# hashNameTag is used if the file name key exists in another hash.  it may be undefined.
#
# INPUTS:
#          $1 = object instance
#          $2 = optional name for the hash within the instance that contains $2
#          $3 = key in object hash that points to the file name
#
# OUTPUTS:
#          returns instance

#sub readFile {

#    my ( $self, $fileNameTag, $hashNameTag ) = @_;

#    if ( defined $fileNameTag && defined $hashNameTag ) {

#	my $fileName = $self -> accessorHOH( $hashNameTag, $fileNameTag );
#	my $fh_infile = openFile( $fileName, "INFILE", "<" );
#	my @fileContents = <$fh_infile>;
#	$self -> accessor( "fileContents", @fileContents );
#	return $self;

#    } elsif ( defined $fileNameTag ) {

#	my $fileName = $self -> accessor( $fileNameTag );
#	my $fh_infile = openFile( $fileName, "INFILE", "<" );
#	my @fileContents = <$fh_infile>;
    
#	$self -> accessor( "fileContents", @fileContents );
#	return $self;

#    } else {

#	print "__PACKAGE__" . "::readFile()" . "failed to access properly:\n\n$!\n";
#	exit;

#    } # if

#} # readFile()


#######################################################

# openFile() opens a file and returns a file handle
# 
# $1 = file to open

sub openFile {

    my ( $file, $fhString, $mode ) = @_;

    if ( $mode =~ />>/ ) {
	
	if ( ! -e $file ) {

	    `touch $file`;
	    open ( $fhString, "$mode$file" ) 
		or die "Cannot open data file for appending:  $!\n";
	    my $fh = *$fhString;
	    return $fh;

	} # if

    } else {

	    open ( $fhString, "$mode$file" ) 
		or die "Cannot create or open data file for writing:  $!\n";
	    my $fh = *$fhString;
	    return $fh;

    } # if 

} # sub openFile()


#######################################################

# writeFile() writes a string to an open file
# 
# $1 = file handle to write to
# $2 = string to write

sub writeFile {

    my ( $fh, $string ) = @_;

    print $fh $string;

} # sub writeFile()


#######################################################

# closeFile() closes specified file handle
#
# $1 = file handle to close

sub closeFile {
    
    my ( $fh ) = @_;

    close $fh or die "could not close filehandle:  $!";  

} # sub closeFile()


#######################################################

# dbug() echoes message to STDOUT if error's threshold 
# equals or exceeds script debug level.
#
# $1 = script's local debug level
# $2 = debug threshold for error
# $3 = error message to print

# Common Debug Levels
#
# 0     Quiet mode
# 1     Basic error output oriented toward user or program errors.
# 2     More advanced errors that show detailed problems.
# 3     Show subroutine calls.
# 4     Show data tests.
# 5     Show test data resulting from procedural / experimental code.
# 6     Blather Mode.



sub dbug {

    my ( $scriptDbugLvl, $dbugThreshold, $msg ) = @_;

    if ( $scriptDbugLvl >= $dbugThreshold ) {
	print "$msg\n";

    } # if ( $scriptDbugLvl >= $dbugThreshold )

} # sub dbug


#######################################################

# logMessage writes a specified message out to a 
# specified log file.
#
# $1 = output log file.
# $2 = message to write to log file
#

# TBD

sub logMessage {

    my ( $logfile, $message ) = @_;

    my $fh = openFile ( $logfile );
    print $fh $message;
    closeFile ( $fh );

} # sub logMessage()


#######################################################

#sub errMsg {
#    my ( $self, $code ) = @_;
#    print "$error_codes { $code }\n";

#} # sub errMsg

#%error_codes = ( 1 => "accessor():  could not get or set" );



#######################################################


1;


__END__


$Log: PerlUtils.pm,v $
Revision 1.16  2002/02/24 08:23:36  moo
modified readFile () close the fh after use

Revision 1.15  2001/12/22 01:13:31  root
*** empty log message ***

Revision 1.14  2001/12/22 00:30:02  root
fixed export problem

Revision 1.12  2001/12/20 18:40:27  root
removed all OO setup stuff

Revision 1.11  2001/12/20 17:53:13  moo
removed errMsg()

Revision 1.10  2001/12/20 17:52:22  moo
removed:  use PerlObject

Revision 1.9  2001/12/20 17:50:24  moo
*** empty log message ***

Revision 1.8  2001/12/17 13:45:04  moo
readFile() no longer adaptive.  it is the baseline tool.

Revision 1.7  2001/12/17 13:36:19  moo
adaptive readFile()

probably should develop an adaptive sub for accessor/accessorHOH for all these subroutines.

however, at this point, TBD

Revision 1.6  2001/12/13 17:03:47  moo
*** empty log message ***

Revision 1.5  2001/12/13 15:03:29  moo
*** empty log message ***

Revision 1.4  2001/12/13 15:02:46  moo
added errMsg and am expanding %error_codes

Revision 1.3  2001/12/12 15:14:55  moo
*** empty log message ***

Revision 1.2  2001/12/12 14:55:36  moo
*** empty log message ***

Revision 1.1  2001/12/12 00:50:08  moo
Initial revision

Revision 1.3  2001/11/23 16:55:02  moo
changed openFile() interface changed to allow for different file handle names.

$fileToOpen, $fileHandleName, $mode

Revision 1.2  2001/11/09 04:48:25  moo
*** empty log message ***

Revision 1.1  2001/11/04 23:37:55  moo
Initial revision