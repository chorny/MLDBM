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

require 5.004;
package MLDBM;
use strict;

$MLDBM::VERSION = $MLDBM::VERSION = '1.25';

require Tie::Hash;
@MLDBM::ISA = qw(Tie::Hash);

use Data::Dumper '2.08';
use Carp;

#
# the DB package to use (we default to SDBM since it comes with perl)
# you might want to change this default to something more efficient
# like DB_File (you can always override it in the use list)
#
$MLDBM::UseDB = "SDBM_File" unless $MLDBM::UseDB;

#
# we prefer the faster XS solution if it exists
# You can override this with the DumpMeth() method
#
$MLDBM::DumpMeth = (defined &Data::Dumper::Dumpxs) ? 'Dumpxs' : 'Dump';

$MLDBM::RemoveTaint = 0;


#
# the magic string used to recognize MLDBM data
# this has to be something unique since we try to store
# stuff natively if it is not a ref
#
$MLDBM::Key = '$MlDbM' unless $MLDBM::Key;

sub TIEHASH {
  my $c = shift;
  my $dbpack = $MLDBM::UseDB;
  $dbpack =~ s|::|/|g;
  $dbpack .= ".pm";
  eval { require $dbpack };       # delay this until they want the tie
  if ($@) {
    carp "MLDBM error: Please make sure $dbpack is a properly installed TIEHASH package.\n" .
      "\tPerl says: \"$@\"";
    return undef;
  }
  my $s = {};
  $s->{DBname} = $MLDBM::UseDB;
  $s->{removetaint} = $MLDBM::RemoveTaint;
  $s->{DB} = $MLDBM::UseDB->TIEHASH(@_) 
    or carp "MLDBM error: Second level tie failed, \"$!\"" and return undef;
  $s->{dumpmeth} = $MLDBM::DumpMeth;
  $s->{key} = $MLDBM::Key;
  return bless $s, $c;
}

sub FETCH {
  my($s, $k) = @_;
  my $ret = $s->{DB}->FETCH($k);
  if (defined($ret) and $ret =~ s|^\Q$s->{key}||o) {
    my $M = "";
    ($ret) = $ret =~ /^(.*)$/s if $s->{removetaint};
    # disambiguate hashref (perl may treat it as a block)
    my $N = eval($ret =~ /^\{/ ? '+'.$ret : $ret);
    return($M ? $M : $N) unless $@;
    carp "MLDBM error: $@\twhile evaluating:\n $ret";
  }
  return $ret;
}

sub STORE {
  my($s, $k, $v) = @_;
  if (defined($v) and (ref($v) or $v =~ m|^\Q$s->{key}|o)) {
    my $dumpmeth = $s->{dumpmeth};
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;
    local $Data::Dumper::Terse = 1;
    $v = $s->{key} . Data::Dumper->$dumpmeth([$v], ['M']);
#    print $v;
  }
  $s->{DB}->STORE($k, $v);
}

sub DELETE   { my $s = shift; $s->{DB}->DELETE(@_); }

sub FIRSTKEY { my $s = shift; $s->{DB}->FIRSTKEY(@_); }

sub NEXTKEY  { my $s = shift; $s->{DB}->NEXTKEY(@_); }

sub EXISTS  { my $s = shift; $s->{DB}->EXISTS(@_); }

sub CLEAR  { my $s = shift; $s->{DB}->CLEAR(@_); }

#
# delegate messages to the underlying DBM
#
sub AUTOLOAD {
  return if $MLDBM::AUTOLOAD =~ /::DESTROY$/;
  my $s = shift;
  if (ref $s) {                                    # twas a method call
    my $dbname = $s->{DBname};
    $MLDBM::AUTOLOAD =~ s/^.*::([^:]+)$/$dbname\:\:$1/;   # permit inheritance
    $s->{DB}->$MLDBM::AUTOLOAD(@_);
  }
}

sub import {
  my ($pack, $dbpack, $key, $removetaint) = @_;
  $MLDBM::UseDB = $dbpack if defined $dbpack and $dbpack;
  $MLDBM::Key = $key if defined $key and $key;
  $MLDBM::RemoveTaint = $removetaint if defined $removetaint and $removetaint;
}

sub DumpMeth {
  my ($s, $meth) = @_;
  (ref $s and defined $meth) ? ($s->{dumpmeth} = $meth) : $s->{dumpmeth};
}

sub Key {
  my ($s, $key) = @_;
  (ref $s) ? (($s->{key} = $key), return $s) : $s->{key};
}

sub UseDB {
  my ($s, $dbname) = @_;
  (ref $s) ? (($s->{DBname} = $dbname), return $s) : $s->{DBname};
}

sub RemoveTaint {
  my ($s, $removetaint) = @_;
  (ref $s) ? (($s->{removetaint} = $removetaint), return $s) : $s->{removetaint};
}

{ # avoid used only once warnings
  local $Data::Dumper::Terse;
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

=head2 Configuration Variables or Methods

=over 4

=item $MLDBM::UseDB  I<or>  I<$OBJ>->UseDB(I<[DBNAME]>)

You may want to set $MLDBM::UseDB to default to something other than
"SDBM_File", in case you have a more efficient DBM, or if you want to use
this with some other TIEHASH implementation.  Alternatively, you can specify
the name of the package at C<use> time.  Nested module names can be
specified as "Foo::Bar".

=item $MLDBM::Key  I<or>  I<$OBJ>->Key(I<[KEYSTRING]>)

Defaults to the magic string used to recognize MLDBM data. It is a six
character wide, unique string. This is best left alone, unless you know
what you're doing.

=item $MLDBM::DumpMeth  I<or>  I<$OBJ>->DumpMeth(I<[METHNAME]>)

This controls which of the two dumping methods available from C<Data::Dumper>
are used.  By default, this is set to "Dumpxs", the faster of the two 
methods, but only if MLDBM detects that "Dumpxs" is supported on your 
platform.  Otherwise, defaults to the slower "Dump" method.

=item $MLDBM::RemoveTaint  I<or>  I<$OBJ>->RemoveTaint(I<[BOOL]>)

This can be set to a true value to make MLDBM untaint the data retrieved
from the underlying DBM implementation.  It is not enabled by default.
Use with care.

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
    $tmp->[0] = 'foo';
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

Uses eval().  A lot.

=back

=head1 WARNINGS

Many DBM implementations have arbitrary limits on the size of records
that can be stored.  For example, SDBM and many ODBM or NDBM
implementations have a default limit of 1024 bytes for the size of a
record.  MLDBM can easily exceed these limits when storing large data
structures, leading to mysterious failures.  Although SDBM_File is
used by MLDBM by default, it is not a good choice if you're storing
large data structures.  Berkeley DB and GDBM both do not have these
limits, so I recommend using either of those instead.

=head1 AUTHOR

Gurusamy Sarathy        gsar@umich.edu

Copyright (c) 1995-97 Gurusamy Sarathy. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 1.25    7 December 1997

=head1 SEE ALSO

perl(1), perltie(1), perlfunc(1)

=cut
