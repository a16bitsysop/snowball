#!/usr/bin/perl -w
use strict;

my $progname = $0;

if (scalar @ARGV < 3) {
  print "Usage: $progname <outfile> <C source directory> <language[=alias]> <language[=alias]> ...\n";
  exit 1;
}

my $outname = shift(@ARGV);
my $c_src_dir = shift(@ARGV);

my $arg;
my %aliases = ();
my @langs = ();
foreach $arg (@ARGV) {
  if ($arg =~ /^([a-z_]+)=([a-z_]+)$/) {
    $aliases{$2} = $1;
  } else {
    push @langs, $arg;
    $aliases{$arg} = $arg;
  }
}

open (OUT, ">$outname") or die "Can't open output file `$outname': $!\n";

print OUT <<EOS;
/* $outname: List of stemming modules.
 *
 * This file is generated by mkmodules.c from a list of module names.
 * Do not edit manually.
 *
EOS

my $lang;
my $line = " * Modules included by this file are: ";
print OUT $line;
my $linelen = length($line);

my $need_sep = 0;
foreach $lang (@langs) {
  if ($need_sep) {
    if (($linelen + 2 + length($lang)) > 77) {
      print OUT ",\n * ";
      $linelen = 3;
    } else {
      print OUT ', ';
      $linelen += 2;
    }
  }
  print OUT $lang;
  $linelen += length($lang);
  $need_sep = 1;
}
print OUT "\n */\n\n";

foreach $lang (@langs) {
  print OUT "#include \"../$c_src_dir/stem_$lang.h\"\n";
}

print OUT <<EOS;

struct stemmer_modules {
  const char * name;
  struct SN_env * (*create)(void);
  void (*close)(struct SN_env *);
  int (*stem)(struct SN_env *);
};
static struct stemmer_modules modules[] = {
EOS

for $lang (sort keys %aliases) {
  my $l = $aliases{$lang};
  print OUT "  {\"$lang\", ${l}_create_env, ${l}_close_env, ${l}_stem},\n";
}

print OUT <<EOS;
  {0,0,0,0}
};
EOS

print OUT <<EOS;
static const char * algorithm_names[] = {
EOS

for $lang (sort @langs) {
  my $l = $aliases{$lang};
  print OUT "  \"$lang\", \n";
}

print OUT <<EOS;
  0
};
EOS
close OUT or die "Can't close ${outname}: $!\n";