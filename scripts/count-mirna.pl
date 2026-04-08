#!/usr/bin/perl

# Usage: perl scripts/count-mirna.pl projects/small-genes/intermediates/05_blast/*_blast.txt > projects/small-genes/results/count-matrix.csv

use strict;
use warnings;

# ── Configuration ────────────────────────────────────────────
# Number of underscore-delimited fields to keep as sample ID
# 1 = mouse (BB366)
# 2 = human (AKTS_PRE)
my $ID_FIELDS = 1;
# ─────────────────────────────────────────────────────────────

my %counts;  # counts{miRNA}{sample} = count
my @samples;
foreach my $file (@ARGV) {
    # Strip path and suffixes, keep only first $ID_FIELDS fields
    (my $basename = $file) =~ s{.*/}{};        # strip path
    $basename =~ s/_blast\.txt$//;             # strip _blast.txt
    $basename =~ s/\.collapsed$//;             # strip .collapsed
    $basename =~ s/_R1$//;                     # strip _R1
    my $sample = join("_", (split(/_/, $basename))[0..$ID_FIELDS-1]);
    push @samples, $sample;
    open(my $fh, '<', $file) or die "Can't open $file: $!";
    while (<$fh>) {
        chomp;
        my @cols = split(/\t/, $_);
        my $miRNA = $cols[1];
        my ($n) = $cols[0] =~ /_x(\d+)$/;
        $n //= 1;
        $counts{$miRNA}{$sample} += $n;
    }
    close $fh;
}
# Remove duplicates from @samples
my %seen;
@samples = grep { !$seen{$_}++ } @samples;
# Print header
print "miRNA," . join(",", @samples) . "\n";
# Print counts per miRNA per sample (0 if none)
foreach my $miRNA (sort keys %counts) {
    print $miRNA;
    foreach my $sample (@samples) {
        my $c = $counts{$miRNA}{$sample} // 0;
        print ",$c";
    }
    print "\n";
}
