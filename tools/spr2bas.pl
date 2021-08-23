#!/usr/bin/env perl
#  
#  Takes a PNG file as an argument, sends it through
#  bin2c.py, and reformats the output into BASIC DATA
#  statements.
#  
my $pngfile = shift || die "SYNOPSIS: $0 [PNG file]\n";
my $tmpfile = "$pngfile.tmp";

print STDERR "creating [$tmpfile]\n";
my $ret = system './bin2c.py', 'ary', $pngfile, $tmpfile;
die "ERROR invoking bin2c.py on [$pngfile]\n" if $ret;

open my $in, '<', $tmpfile || die "ERROR: could not open tempfile '$tmpfile'\n";

#
# uncomment this if you want line numbers 
#
#my $line = 10000;


print "$line " if defined $line;
print uc "REM $pngfile\n";
++$line if defined $line;

for (<$in>)
{
   next unless /0x/;
   s/0x/\$/g;
   s/,$//;
   s/\};//; 
   print "$line " if defined $line;
   print uc "DATA $_";
   ++$line if defined $line;
}
close $in;
unlink $tmpfile;

