#!/usr/bin/perl -w

use strict;
use File::Copy;
use Cwd;

my $IMG_BLANK = "img/blank.png";
my ($REVISTA) = getcwd() =~ m{.*/(.*)};

my @SECCIONS;

sub busca_seccions {
	open P_TEX,"<$REVISTA.tex" or die "$! $REVISTA.tex";
	while (<P_TEX>) {
		s/#.*//;
		my ($include) = m[\\include\{(.*)/];
		push @SECCIONS, ( $include) if $include;
	}
	close P_TEX;
}

sub crea_dir {
	my $arxiu = shift or die;
	my ($dir) = $arxiu =~ m{(.*)/};
	return if -d $dir;
	my $dst = "";
	for my $item (split /\//,$dir) {
		$dst .= "/$item";
		next if -d $dst;
		mkdir $dst or die "$! $dst";
	}
}

sub crea_img_seccions {
	my $orig = shift;
	for my $seccio (@SECCIONS) {
		my $arxiu = "$seccio/$orig";
		next if -e $arxiu;
		crea_dir("$arxiu");
		print "faig $arxiu\n";
		copy($IMG_BLANK,$arxiu) or die "$! $arxiu";
	}
}

sub crea_img {
	my $arxiu = shift;
	return if -e $arxiu;
	print "faig $arxiu\n";
	copy($IMG_BLANK,$arxiu) or die "$! $arxiu";
}

#############################################################################
busca_seccions();
crea_img_seccions("img/index.png");
crea_img("portada/portada.png");
