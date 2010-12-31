#!/usr/bin/perl -w

use strict;
use Cwd;
use File::Copy;
use Text::Diff;

my $FILE_OUT = "portada/index.tex";

my @SECCIONS;
my ($REVISTA) = getcwd() =~ m{.*/(.*)};
my %PLANA;
my %FOTO;
my %REPE;
my %PAGESOF;

sub busca_seccions {
	open P_TEX,"<$REVISTA.tex" or die "$! $REVISTA.tex";
	while (<P_TEX>) {
		s/#.*//;
		my ($include) = m[\\include\{(.*)/];
		push @SECCIONS, ( $include) if $include;
		print "$include\n" if $include;
	}
	close P_TEX;
}

sub inputs {
	my $seccio = shift or die ;
	my @input;
	open SECCIO,"<$seccio/$seccio.tex" or do {
			warn "$! $seccio/$seccio.tex";
		next;
	};
	while (<SECCIO>) {
		s/\%.*//;
		my ($arxiu ) = m[\\input{(.*)}];
		next if !$arxiu;
		$arxiu .= ".tex" if $arxiu !~ /\.tex$/;
		push @input,($arxiu);
	}
	close SECCIO;
	return @input;
}

sub guarda_index {
	my ($titol,$pagesof,$seccio) = @_;
	return if ! ($titol && $pagesof && $pagesof =~ /^\d+$/ && $pagesof !~ /^0/ );

	die "$titol repetit a $seccio"
		if $REPE{$titol}++;

	die "pagesof '$pagesof' repetit a '$PAGESOF{$pagesof}' i '$titol'"
				." en $seccio"
		if $PAGESOF{$pagesof};

	$PAGESOF{$pagesof}=$titol;
#	print '\indexitem{'."$titol}{\\pageref{$pagesof}}\n";
	if (!$PLANA{$seccio}) {
				$PLANA{lc($seccio)} = $pagesof;
				$FOTO{$seccio} = "portada/img/blank.png";
				my $foto_idx = "$seccio/img/index.png";
				$FOTO{$seccio} = $foto_idx if -e $foto_idx;
	}
}

sub mostra_index {
    print '\begin{'."indexblock}{}\n";
    for (sort { $a <=> $b } keys %PAGESOF) {
#        	print '\indexitem{'.$PAGESOF{$_}."}{\\pageref{$_}}\n";
        print '\indexitem{'.$PAGESOF{$_}."}{$_}\n";
    }
    print '\end{'."indexblock}\n\n";
}

##############################################################

busca_seccions();

open INDEX,">$FILE_OUT.new" or die $!;
select(INDEX);

for my $seccio (@SECCIONS) {

	my @input = inputs($seccio);
	die "No hi ha inputs per $seccio " if !@input;

	for my $input (@input) {
      next if $input eq 'portada/index.tex';
	  open SECCIO,"<$input" or die "$! $input";
	  while (<SECCIO>) {
		next if !m[\\begin\{news\}];
		<SECCIO>;
		my $titol=<SECCIO>;
		chomp $titol;
		$titol =~ s/{(.*)}/$1/;
		$titol =~ s/".*?"(.*)/$1/;
		$titol =~ s/\.//;
		my $titol2 = <SECCIO>;
		if ($titol2 =~ /^\%\s*index:\s*(.*?)\s*$/) {
			$titol = $1;
			<SECCIO>;
		}
		<SECCIO>;
		my $pagesof;
		for (1..3) {
			my $line=<SECCIO>;
			chomp $line;
			($pagesof) = $line =~ /\{(\d+)\}/;
			last if $pagesof && $pagesof =~ /^\d+$/;
		}
		warn "Error a '$input'\n'$seccio . $titol', pagesof = '$pagesof'"
			if $pagesof && $pagesof !~ /^\d+$/;
		guarda_index($titol,$pagesof,$seccio);
	  }
	  close SECCIO;
	} # for inputs
}

mostra_index();

print '%titol de les seccions en blanc {}'."\n";
print '\begin{'."weatherblock}{}\n";
for (qw(fem_escola parvulari primaria eso)) {
	next if /ampa/;
	next if !$FOTO{$_};
	my $seccio = $_;
	$seccio =~ s/_/ /g;
	print '\weatheritem{'
		.$FOTO{$_}."}{$seccio}{ pàg. \\pageref{".$PLANA{$_}."}}\n";
}
print '\end{'."weatherblock}\n\n";
close INDEX;

my $diff = 1;
$diff = diff $FILE_OUT, "$FILE_OUT.new" if -f $FILE_OUT;
if ($diff) {
	warn "noticies canviat\n";
	copy("$FILE_OUT.new",$FILE_OUT) or die $!;
}
