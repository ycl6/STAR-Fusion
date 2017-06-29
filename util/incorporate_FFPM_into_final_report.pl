#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use DelimParser;

my $usage = "\n\n\tusage: $0 left.fq finspector.fusion_predictions.final.abridged\n\n";

my $fq_filename = $ARGV[0] or die $usage;
my $finspector_results = $ARGV[1] or die $usage;

main: {

    my $num_frags = &get_num_total_frags($fq_filename);
    
    open (my $fh, $finspector_results) or die "Error, cannot open file $finspector_results";
    my $tab_reader = new DelimParser::Reader($fh, "\t");

    my @column_headers = $tab_reader->get_column_headers();
    push (@column_headers, "FFPM");

    my $tab_writer = new DelimParser::Writer(*STDOUT, "\t", \@column_headers);
    
    while (my $row = $tab_reader->get_row()) {
        
        my $J = $row->{JunctionReadCount};
        my $S = $row->{SpanningFragCount};
        
        my $J_FFPM = &compute_FFPM($J, $num_frags);
        my $S_FFPM = &compute_FFPM($S, $num_frags);

        $row->{FFPM} = $J_FFPM + $S_FFPM;
        
        $tab_writer->write_row($row);
    }
    close $fh;
    
    exit(0);
    
}

####
sub get_num_total_frags {
    my ($fq_file_listing) = @_;

    my @fq_files = split(',', $fq_file_listing);
    
    my $sum_lines = 0;
    foreach my $fq_file (@fq_files) {
        
        my $num_lines;
        if ($fq_file =~ /\.gz/) {
            $num_lines = `gunzip -c $fq_file | wc -l`;
        }
        else {
            $num_lines = `cat $fq_file | wc -l`;
        }
        
        $num_lines =~ /^(\d+)/ or die "Error, cannot extract line count from [$num_lines]";
        $num_lines = $1;

        $sum_lines += $num_lines;
    }

    my $num_seq_records = $sum_lines / 4;

    return($num_seq_records);
}
            

####
sub compute_FFPM {
    my ($count_frags, $total_frags) = @_;

    my $ffpm = $count_frags / $total_frags * 1e6;

    $ffpm = sprintf("%.4f", $ffpm);
    
    return($ffpm);
}

