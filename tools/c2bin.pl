#!/usr/bin/env perl
#
#  Takes a PNG file as an argument, sends it through
#  png2sprite.py, and writes it as a binary file, complete
#  with initial two null bytes, ready to load.
#

{
   my $pngfile = shift || die "SYNOPSIS: $0 [PNG file]\n";
   my $tmpfile = "$pngfile.tmp";
   my $outfile = "$pngfile.bin";

   $outfile =~ s/.png//;

   print STDERR "creating $tmpfile\n";
   my $ret = system './png2sprite.py', $pngfile, $tmpfile;

   die "ERROR invoking png2sprite.py on [$pngfile]\n" if $ret;

   open my $in, '<', $tmpfile || die "ERROR: could not open tempfile '$tmpfile'\n";
   open my $fp, '>', uc $outfile;
   print $fp pack 'xx';

   print STDERR "creating $outfile\n";
   for(<$in>)
   {
      next unless /0x/;
      chomp;
      s/0x/\$/g;
      s/,$//;
      s/\$//g; # remove dollar sign please
   
      my @numbers = map { hex $_ } split /,/; # these should all be nice and hexy

      print $fp pack 'C*', @numbers;
   }

   close $fp;
   close $in;
   unlink $tmpfile;

   redo;
}
