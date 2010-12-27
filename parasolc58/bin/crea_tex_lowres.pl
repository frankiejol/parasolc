#!/usr/bin/perl -w

use strict;
use Getopt::Long;

my $TIPUS = 'lowres';

GetOptions( 'tipus=s' => \$TIPUS);

my %SKIP_LOWRES = map { $_ => 1 } qw();

sub crea_dir {
	my $file = shift or die $!;
	my $dir = ".";
	my @item = split m{/},$file;
	pop @item;
	for (@item) {
		$dir .= "/$_";
		next if -e $dir;
		mkdir $dir or die "$! $dir";
	}
}


sub crea_lowres {
	my $tex = shift;
	my ($tipus) = (shift or 'lowres');
	my $tex_lowres = $tex;
	$tex_lowres =~ s{(.*)\.(tex)}{$tipus/$1.$2};

	crea_dir($tex_lowres);

	print "$tex -> $tex_lowres\n";

	open ORIG,"<$tex" 			or die "$! $tex\n";
	open DEST,">$tex_lowres" 	or die "$! $tex_lowres\n";
	print DEST
		"%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n".
		"%\n".
		"% Arxiu pregenerat.\n".
		"% NO EDITAR\n".
		"%\n".
		"%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n";
	while (my $line = <ORIG>) {
		$line =~ m[(.*)(includegraphics|image|ThisCenterWallPaper|weatheritem)(.*\{)(.*)/(.*?)\.(jpg|png)(.*)]i;

		my $ext = $6;
		$ext = 'eps' if $6 && $tipus eq 'bw';
		$line = "${1}${2}${3}${4}/gen/${5}_dpi_$tipus.$ext$7\n" if $6;

#		$line =~ s[(\s*\\)(include|input)(\s*\{)(.*?)(\}.*)][$1$2$3$tipus/${4}$5];

		print DEST $line;
	}
	close ORIG;
	close DEST;

}

=pod
my %requested;
for (@ARGV) {
	if ( ! ~ /\.tex$/) {
		warn "$_ no es tex\n"
	} else {
		$requested{$_}++;
	}
}

opendir LS,"." or die $!;
while (my $tex = readdir LS) {

	next if $tex !~ /\.tex$/;
	next if $tex =~ /\.lowres\./;

	next if $SKIP_LOWRES{$tex};

	next if @ARGV && !$requested{$tex};

}
closedir LS;
=cut
die "Falta argument" if !$ARGV[0];

crea_lowres($ARGV[0],$TIPUS);
