#
# MLDBM.pm
#
# store multi-level hash structure in single level tied hash (read DBM)
#
# Documentation at the __END__
#
# Gurusamy Sarathy
# gsar@umich.edu
#

require 5.002;
package MLDBM;
$VERSION = $VERSION = '1.21';

require Tie::Hash;
@ISA = qw(Tie::Hash);

use Data::Dumper;
use Carp;

#
# the DB package to use (we default to SDBM since it comes with perl)
# you might want to change this default to something more efficient
# like DB_File (you can always override it in the use list)
#
$UseDB = "SDBM_File";

#
# we prefer the faster XS solution if it exists
# You can override this with the DumpMeth() method
#
$DumpMeth = (defined &Data::Dumper::Dumpxs) ? 'Dumpxs' : 'Dump';


#
# the magic string used to recognize MLDBM data
# this has to be something unique since we try to store
# stuff natively if it is not a ref
#
$Key = '$MlDbM';

sub TIEHASH {
  my $c = shift;
  my $dbpack = $UseDB;
  $dbpack =~ s|::|/|g;
  $dbpack .= ".pm";
  eval { require $dbpack };       # delay this until they want the tie
  if ($@) {
    carp "MLDBM error: Please make sure $dbpack is a properly installed TIEHASH package.\n" .
      "\tPerl says: \"$@\"";
    return undef;
  }
  my $s = {};
  $s->{DBname} = $UseDB;
  $s->{DB} = $UseDB->TIEHASH(@_) 
    or carp "MLDBM error: Second level tie failed, \"$!\"" and return undef;
  $s->{dumpmeth} = $DumpMeth;
  return bless $s, $c;
}

sub FETCH {
  my($s, $k) = @_;
  my $M;
  my $ret = $s->{DB}->FETCH($k);
  if ($ret =~ s|^\Q$Key||o) {
    eval $ret; 
    if ($@) {
      carp "MLDBM error: $@\twhile evaluating:\n $ret";
      $ret = undef;
    }
    else {
      $ret = $M;
    }
  }
  return $ret;
}

sub STORE {
  my($s, $k, $v) = @_;
  if (ref($v) or $v =~ m|^\Q$Key|o) {
    my $dumpmeth = $s->{dumpmeth};
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    $v = $Key . Data::Dumper->$dumpmeth([$v], ['M']);
#    print $v;
  }
  $s->{DB}->STORE($k, $v);
}

sub DELETE   { my $s = shift; $s->{DB}->DELETE(@_); }

sub FIRSTKEY { my $s = shift; $s->{DB}->FIRSTKEY(@_); }

sub NEXTKEY  { my $s = shift; $s->{DB}->NEXTKEY(@_); }

#
# delegate messages to the underlying DBM
#
sub AUTOLOAD {
  return if $AUTOLOAD =~ /::DESTROY$/;
  my $s = shift;
  if (ref $s) {                                    # twas a method call
    my $dbname = $s->{DBname};
    $AUTOLOAD =~ s/^.*::([^:]+)$/$dbname\:\:$1/;   # careful, must permit inheritance
    $s->{DB}->$AUTOLOAD(@_);
  }
}

sub import {
  my ($pack, $dbpack, $key) = @_;
  $UseDB = $dbpack if defined $dbpack and $dbpack;
  $Key = $key if defined $key and $key;
}

sub DumpMeth {
  my ($s, $meth) = @_;
  (ref $s and defined $meth) ? ($s->{dumpmeth} = $meth) : $s->{dumpmeth};
}

1;
__END__

=head1 NAME

MLDBM - store multi-level hash structure in single level tied hash

=head1 SYNOPSIS

    use MLDBM;                   # this gets the default, SDBM
    #use MLDBM qw(DB_File);
     
    $dbm = tie %o, MLDBM [..other DBM args..] or die $!;

=head1 DESCRIPTION

This module, intended primarily for use with DBM packages, can serve as a
transparent interface to any TIEHASH package that must be used to
store arbitrary perl data, including nested references.

It works by converting the values in the hash that are references, to their
string representation in perl syntax.  When using a DBM database, it is this
string that gets stored.

It requires the Data::Dumper package, available at any CPAN site.

See the B<BUGS> section for important limitations.

=head2 Configuration Variables/Methods

=over 4

=item $MLDBM::UseDB

You may want to set $MLDBM::UseDB to default to something other than
"SDBM_File", in case you have a more efficient DBM, or if you want to use
this with some other TIEHASH implementation.  Alternatively, you can specify
the name of the package at C<use> time.  Nested module names can be
specified as "Foo::Bar".

=item $MLDBM::Key

Defaults to the magic string used to recognize MLDBM data. It is a six
character wide, unique string. This is best left alone, unless you know
what you're doing.

=item $MLDBM::DumpMeth  I<or>  $I<OBJ>->DumpMeth(I<[METHNAME]>)

This controls which of the two dumping methods available from C<Data::Dumper>
are used.  By default, this is set to "Dumpxs", the faster of the two 
methods, but only if MLDBM detects that "Dumpxs" is supported on your 
platform.  Otherwise, defaults to the slower "Dump" method.

=back

=head1 EXAMPLE

    use MLDBM;                            # this gets SDBM
    #use MLDBM qw(DB_File);
    use Fcntl;                            # to get 'em constants
     
    $dbm = tie %o, MLDBM, 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
     
    $c = [\ 'c'];
    $b = {};
    $a = [1, $b, $c];
    $b->{a} = $a;
    $b->{b} = $a->[1];
    $b->{c} = $a->[2];
    @o{qw(a b c)} = ($a, $b, $c);
     
    #
    # to see what wuz stored
    #
    use Data::Dumper;
    print Data::Dumper->Dump([@o{qw(a b c)}], [qw(a b c)]);

    #
    # to modify data in a substructure
    #
    $tmp = $o{a};
    $tmp[0] = 'foo';
    $o{a} = $tmp;
     
    #
    # can access the underlying DBM methods transparently
    #
    #print $dbm->fd, "\n";                # DB_File method

=head1 BUGS

=over 4

=item 1.

Adding or altering substructures to a hash value is not entirely transparent
in current perl.  If you want to store a reference or modify an existing
reference value in the DBM, it must first be retrieved and stored in a
temporary variable for further modifications.  In particular, something like
this will NOT work properly:

    $mldb{key}{subkey}[3] = 'stuff';  # won't work

Instead, that must be written as:

    $tmp = $mldb{key};                # retrieve value
    $tmp->{subkey}[3] = 'stuff';
    $mldb{key} = $tmp;                # store value

This limitation exists because the perl TIEHASH interface currently has no
support for multidimensional ties.

=item 2.

MLDBM was first released along with the Data::Dumper package as an 
example.  If you got serious with that and have a DBM file from that 
version, you can do something like this to convert the old records 
to the new format:

    use MLDBM (DB_File);              # be sure it's the new MLDBM
    use Fcntl;
    tie %o, MLDBM, 'oldmldbm.file', O_RDWR, 0640 or die $!;
    for $k (keys %o) {
      my $v = $o{$k};
      if ($v =~ /^\$CrYpTiCkEy/o) {
	$v = eval $v;
	if ($@) { warn "Error: $@\twhile evaluating $v\n"; }
	else    { $o{$k} = $v; }
      }
    }
    

=back

=head1 AUTHOR

Gurusamy Sarathy        gsar@umich.edu

Copyright (c) 1995 Gurusamy Sarathy. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 1.21    9 April 1996

=head1 SEE ALSO

perl(1)

=cut
