#!/usr/bin/perl -w

use strict;
use Cwd;
use File::Copy;
use Image::Size;

my @SECCIONS;
my %EXT_IMG = map { $_ => 1 } qw (jpg png gif);
my @TIPUS = qw(lowres bw paper);

my %NODEP = map { $_ => 1 } qw ("portada/index.tex");

my %EXT_TEX = ( tex => 1);
my %EXT = map { $_ => 1 } keys %EXT_IMG,keys %EXT_TEX;

my ($REVISTA) = getcwd() =~ m{.*/(.*)};

my $DPI_LOWRES = 36;
my $QUALITY_LOWRES = 30;
my $WIDTH_LOWRES = "640";

my $BW_LOWRES = 0;

my $QUALITY_HIRES = 100;

my $IMG_WIDTH = 340;
my $CONF_COLOR = "etc/fotos_color.conf";

my %FOTO_COLOR;

my %FET;

sub busca_seccions {
	my ($tex) = (shift or "$REVISTA.tex");
	open P_TEX,"<$tex" or die "$! $tex";
	while (<P_TEX>) {
		s/#.*//;
		my ($type,$include) = m[\\(include|input)\{(.*)/];
		next if ! $include;
		push @SECCIONS, ( $include); 
	}
	close P_TEX;
}
sub ext {
		my $file = shift;
	my ($ext) = $file =~ /\.(\w+)$/;
	return lc($ext);
}

sub transforma_img {
	my ($file,$tipus) = @_;
	my $file_lowres = "$tipus/$file";

	die if $FET{$tipus}->{$file_lowres}++;

	my ($dir) =$file_lowres =~ m{(.*)/};
	die "No trobo el dir de $file_lowres" if !$dir;

	my ($x) = imgsize($file) or die "No trobo mida de '$file'";
	die "No trobo mida de '$file'" if !defined $x;
	my $width = '';
	$width = " -geometry $WIDTH_LOWRES "
		if $x> $WIDTH_LOWRES*1.2; 

	my $options = "";
	if ($tipus eq 'lowres'){
			$options = 
					" -density $DPI_LOWRES $width -quality $QUALITY_LOWRES ";
	} elsif ($tipus eq 'bw' || $tipus eq 'paper') {
    
			$options = "-colorspace GRAY +contrast"
                if $tipus eq 'bw' 
                        || ($tipus eq 'paper' && !$FOTO_COLOR{$file});
	} else {
            die "Unknown tipus '$tipus' for $file";
    }
	print "$file_lowres: $file\n"
			."\tmkdir -p $dir "
			." && convert $file $options $file_lowres\n"
			."\n"
	;
	return $file_lowres;
}

sub transforma_tex {
	my ($file,$tipus) = @_;
	my $file_lowres = "$tipus/$file";

	die "Repetit $file_lowres" if $FET{$tipus}->{$file_lowres}++;

	print "$file_lowres: $file\n";
	my ($dir) =$file_lowres =~ m{(.*)/};

    if ($file =~ /^parasolc/) {
            print "\t./bin/crea_tex_lowres.pl --$tipus $file\n\n";
    } else {
            print "\tmkdir -p $dir \&\& cp $file $tipus/$file\n\n"
    }
	return $file_lowres;
}

sub transforma {
	my ($file,$tipus) = @_;
	my $ext = ext($file);
	if ($EXT_IMG{$ext}) {
		return transforma_img($file,$tipus);
	} elsif ($EXT_TEX{$ext}) {
		return transforma_tex($file,$tipus);
	} else {
		die "Unknown extension '$ext' for '$file'\n";
	}
}

sub bw {
	return transforma(@_,"bw");
}

sub lowres {
		return transforma(@_,"lowres");
}

sub paper{
        return transforma(@_,"paper");
}

sub print_groups {
	my ($item,$nom) = (@_,"");
	for my $ext (sort keys %$item) {
		print uc("$ext$nom")."=";
		print join " ",sort @{$item->{$ext}};
		print "\n\n";
	}
}

sub target_pdf {
	my ($pdf,$dep,$nom) = (@_,"") or die $!;

    my ($dir,$file) = $pdf =~ m{(.*)/(.*)};

    if (!$dir || !$file) {
        $dir = '.';
        $file = $pdf;
    } else {
        print "$dir/papertex.cls: papertex.cls\n"
                ."\tcd $dir && ln -s ../papertex.cls .\n"
                ."\n".
              "$dir/portada/index.tex: portada/index.tex\n"
                ."\tcd $dir/portada && cp ../../portada/index.tex .\n"
                ."\n";
    }

	print "$pdf.pdf: ";
	for my $ext (sort keys %$dep) {
		print '$('.uc("$ext$nom").") $dir/portada/index.tex ";
	}
	print " $dir/papertex.cls $pdf.tex";
	print "\n"
		."\tcd $dir \&\& pdflatex $file.tex\n"
		."\n";
}

sub make_init {
	print "ALL: $REVISTA.pdf ".(join(" ",map { "$_/$REVISTA.pdf" } @TIPUS ))
		."\n";

	for my $tipus (@TIPUS) {

		print "$tipus/$REVISTA.tex: $REVISTA.tex\n"
		."\t./bin/crea_tex_lowres.pl --tipus=$tipus $REVISTA.tex\n"
		."\n";
	}

	papertex();

}

sub portada {
    print "portada/index.tex: \$(TEX)\n"
        ."\t./bin/busca_noticies.pl\n"
        ."\n";
}

sub papertex  {
	print "papertex.cls: papertex.ins papertex.dtx\n"
		."\trm -f papertex.cls *.aux ; latex papertex.ins\n"
		."\n";
}


sub make_clean {
    print "clean:\n"
            ."\t rm -rf $REVISTA.pdf lowres/$REVISTA.pdf bw/$REVISTA.pdf paper/$REVISTA.pdf "
			." papertex.cls "
			." *.aux *.log *.out */*.aux */*.log";

	print "realclean: clean\n"
			."\t rm -rf lowres bw paper Makefile\n";
}

sub article_color {
	my $file = shift or die $!;
	open ARTICLE,"<$file" or die "$! $file";
	while (<ARTICLE>) {
		m[(includegraphics|image|ThisCenterWallPaper|weatheritem).*\{(.*)/(.*?)\.(jpg|png).*\}]i;
		next if !($2 && $3 && $4);
		my $file = "$2/$3.$4";
		$FOTO_COLOR{$file}++;
	}
	close ARTICLE;
}

sub fotos_color {
     open CONF,"<$CONF_COLOR" or die $!;
     while (my $file=<CONF>) {
        chomp $file;
		if ($file =~ /\.tex$/) {
				article_color($file);
		} else {
             $FOTO_COLOR{$file}++;
	 	}
     }
     close CONF;
}

############################################################


busca_seccions();
fotos_color();

open MAKEFILE,">Makefile" or die $!;
select(MAKEFILE);

make_init();
my (%lowres,%all,%bw, %paper);
open FIND,"find ".join(" ",@SECCIONS)." |" or die $!;
while (my $file = <FIND>) {
	chomp $file;
    
	my $ext = ext($file);
	next if !$ext || !$EXT{$ext};


    next if $NODEP{$file};
    next if $file =~ m{portada/index.tex};

	push @{$lowres{$ext}},(lowres($file));
	push @{$bw{$ext}},(bw($file));
    push @{$paper{$ext}},(paper($file));

	push @{$all{$ext}},($file);
}
close FIND;

print_groups(\%lowres,"_LOWRES");
print_groups(\%bw,"_BW");
print_groups(\%paper,"_PAPER");

print_groups(\%all);
target_pdf($REVISTA,\%all);

portada();

target_pdf("lowres/$REVISTA",\%lowres,"_LOWRES");
target_pdf("bw/$REVISTA",\%bw,"_BW");
target_pdf("paper/$REVISTA",\%paper,"_PAPER");

make_clean();
close MAKEFILE;
