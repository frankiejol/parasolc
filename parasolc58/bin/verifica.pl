#!/usr/bin/perl

use warnings;
use strict;
use Cwd;

my %SECCIO;
my ($REVISTA) = getcwd() =~ m{.*/(.*)};

sub busca_seccions {

	my ($tex) = (shift or "$REVISTA.tex");

	my @seccions;
	open P_TEX,"<$tex" or die "$! $tex";
	while (<P_TEX>) {
		s/#.*//;
		my ($type,$include) = m[\\(include|input)\{(.*)/];
		next if ! $include;
#		push @seccions , ( $include) if $type eq 'include';
		$SECCIO{"$include/$include.tex"}++;
	}
	close P_TEX;
}

sub busca_doc {
	my $tex_file = shift or die $!;

	open TEX,"<$tex_file" or die "$! $tex_file";
	my $doc_file;
	while (<TEX>) {
		($doc_file) = /^%.*doc:\s*(.*)/;
		last if $doc_file;
	}
	close TEX;
	return $doc_file;
}

sub conte_inputs {
		
	my $tex_file = shift or die ;

	my $inputs=0;
	open TEX,"<$tex_file" or die "$! $tex_file";
	while (<TEX>) {
		s/\%.*//;
		$inputs++ if m{\\input};
	}
	return $inputs;
}

sub es_input {
		my $tex_file = shift or die $!;
		$tex_file =~ s/.tex$//;
		my ($dir) = $tex_file =~ m{(.*)/};

		my $input = 0;
		my $cmd = "grep $tex_file $dir/*tex";
		open GREP , "$cmd|" or die $!;
		while (<GREP>) {
				s{\%.*}{};
				my ($dir,$file) = m{(.*?)/(.*?):};
				$file =~ s/\..*$//;
				next if $dir eq $file;
				$input++ if m{\\input\{$tex_file};
		}
		close GREP;
		return $input;
}

sub docs_sense_tex {
	my ($tex,$doc)  =@_;
	my %doc_trobat;
	for my $tex_file (sort keys %$tex) {
		my $doc_file = busca_doc($tex_file);
		if (!$doc_file) {
				next if $tex_file =~ m{^portada/}
					|| $tex_file =~ /^$REVISTA/
					|| conte_inputs($tex_file)
					|| es_input($tex_file);
				print "  - $tex_file sense font\n";
				next;
		}
		if ($doc_trobat{$doc_file}) {
				print "Doc $doc_file a \n - $tex_file\n"
			   		."	- $doc_trobat{$doc_file}\n";
		}
		$doc_trobat{$doc_file} = $tex_file if $doc_file;
	}

	print "Docs sense tex: \n";
	my $cont = 0;
	for (sort keys %$doc) {
			next if $doc_trobat{$_};
			print "$_\n";
			$cont ++;
	}
	print "\t$cont\n";
}

####################################################################
#
busca_seccions();
my %tex;
open TEX,"find . -type f -iname \"*tex\"|" or die $!;
while (<TEX>) {
	next if /\.(lowres|bw).tex$/;
	s{^./(.*)}{$1};
	chomp;
	next if $SECCIO{$_};
	$tex{$_}++;
}
close TEX;

my %doc;
open DOC,"find fonts -type f -iname \"*doc*\"|" or die $!;
while (<DOC>) {
	next if /\.~lock.*\#$/;
	chomp;
	s{^fonts/(.*)}{$1};
	$doc{$_}++;
}
close DOC;



########################################################
#

print "He trobat ".scalar(keys %tex)." tex i ".scalar(keys %doc)." docs\n";

docs_sense_tex(\%tex, \%doc);
