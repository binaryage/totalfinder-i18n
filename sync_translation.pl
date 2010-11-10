#!/usr/bin/perl

my $ENDL = "\n";

use utf8;
use strict;
use warnings;

my ($path,$progname) = $0 =~ m/^(.+)\/(.+)$/;

sub usage
{
  die("Usage: $progname File1 File2".$ENDL);
}

scalar @ARGV == 2 or usage();

my ($FFILE_PATH, $TFILE_PATH) = @ARGV;

my %TFILE_HASH = ();

open(FFILE, $FFILE_PATH) or die("File not found: ".$FFILE_PATH);
open(TFILE, $TFILE_PATH) or die("File not found: ".$TFILE_PATH);

while(<TFILE>)
{
  chomp;
  s/\/\*.*\*\///g;
  m/^$/g and next;
  
  my ($key, $value) = m/^\s*"(.+)"\s*=\s*"(.*)"\s*;.*$/;
  $TFILE_HASH{$key} = $value;
}

close(TFILE);

while(<FFILE>)
{
  chomp;
  (m/\/\*.*\*\//) and print $_.$ENDL and next;
  (m/^\s*$/g) and print $ENDL and next;
  my ($key, $value, $comment) = m/^\s*"(.+)"\s*=\s*"(.*)"\s*;(.*)/;
  $comment = "" unless $comment;
  $value = $TFILE_HASH{$key} if (exists $TFILE_HASH{$key} && defined $TFILE_HASH{$key});
  print "\"$key\" = \"$value\";$comment".$ENDL ;
  delete $TFILE_HASH{$key};
}

close(FFILE);

print $ENDL;

foreach my $key (sort keys %TFILE_HASH)
{
  print "/* \"$key\" = \"$TFILE_HASH{$key}\"; */".$ENDL ;
}
