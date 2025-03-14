#!/usr/bin/perl
=b
usage: perl QEoutput2data.pl [sout dir]

if no sout dir, the current dir will be used to find sout files.
=cut

#density (g/cm3), arrangement, mass, lat a , lat c
    #my @temp = 
#    @{$used_element{$_}} = &elements::eleObj("$_");
use strict;
use warnings;
use Data::Dumper;
use POSIX;
use lib '/opt/qe_perl/';
use elements;#all setting package
use Cwd;

my $currentPath = getcwd();
my @md_out = `find -L $currentPath -type f -name  *.sout`;#sout in current folder
map { s/^\s+|\s+$//g; } @md_out;
if(!@md_out){die "no sout files to convert\n";}
###need folders in loop 
`rm -rf output`;
for my $file (@md_out){
    #check for relax or vc-relax
    my $file_path = `dirname $file`;
    my $file_name = `basename $file`;
    $file_path =~ s/^\s+|\s+$//g;   
    $file_name =~ s/^\s+|\s+$//g;    
    my $prefix = $file_name;
    $prefix =~ s/^\s+|\s+$//g;   
    $prefix =~ s/\.sout//g;
    my @relax = `grep "relax" $file_path/$prefix.in`;#relax or vc-relax
    map { s/^\s+|\s+$//g; } @relax;
    #print "@relax\n";
    my @scfNu = `grep "^!" $file`;
    my $scfNu = @scfNu;
   # print "SCF NO: $scfNu\n";
    my $multi_frame = "no";
    my $md_path = `dirname $file`;
    $md_path =~ s/^\s+|\s+$//g;
    my $md_name = `basename $file`;
    $md_name =~ s/^\s+|\s+$//g;
    $md_name =~ s/\..*//g;
    my $natom = `grep -m 1 "number of atoms/cell" $file|awk '{print \$5}'`;
    die "No atom number was found in $file" unless ($natom); 
    $natom =~ s/^\s+|\s+$//g;
    my $ntype = `grep -m 1 "number of atomic types" $file|awk '{print \$6}'`;
    die "No atom type was found in $file" unless ($ntype); 
    $ntype =~ s/^\s+|\s+$//g;

    #get cell information of all frames
    #CELL_PARAMETERS (angstrom)
    #5.631780735   0.001261244   0.001887268
    my @AllCELL_PARAMETERS = `grep -A3 "CELL_PARAMETERS (angstrom)" $file|grep -v "CELL_PARAMETERS (angstrom)"|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
   
    unless(@AllCELL_PARAMETERS){
        @AllCELL_PARAMETERS = `grep -A3 'CELL_PARAMETERS {angstrom}' $file|grep -v 'CELL_PARAMETERS {angstrom}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
    }    
    unless(@AllCELL_PARAMETERS){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @AllCELL_PARAMETERS = `grep -A3 "CELL_PARAMETERS (angstrom)" $path/$filename.in|grep -v 'CELL_PARAMETERS (angstrom)'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
    }
    
    unless(@AllCELL_PARAMETERS){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @AllCELL_PARAMETERS = `grep -A3 "CELL_PARAMETERS {angstrom}" $path/$filename.in|grep -v 'CELL_PARAMETERS {angstrom}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @AllCELL_PARAMETERS; 
    }

    die "No CELL_PARAMETERS were found in $file" unless (@AllCELL_PARAMETERS); 
    #my @box;#array of array, equal to frame numbers
    my $frameNo =  @AllCELL_PARAMETERS/3;
    if($frameNo < $scfNu){
       $frameNo =  $scfNu;
       $multi_frame = "yes";
    }
    
    if($multi_frame eq "yes"){@AllCELL_PARAMETERS = (@AllCELL_PARAMETERS) x $frameNo}

    #get atom coords information of all frames
    #ATOMIC_POSITIONS (angstrom)
    #Co            2.7414458575        2.7928470261        2.8314219861
    my @Allcoords = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $file|grep -v "ATOMIC_POSITIONS (angstrom)"|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @Allcoords;

    unless(@Allcoords){
        @Allcoords = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $file|grep -v "ATOMIC_POSITIONS {angstrom}"|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Allcoords; 
    }    
    unless(@Allcoords){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Allcoords = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $path/$filename.in|grep -v 'ATOMIC_POSITIONS (angstrom)'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Allcoords; 
    }
    
    unless(@Allcoords){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Allcoords = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $path/$filename.in|grep -v 'ATOMIC_POSITIONS {angstrom}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Allcoords; 
    }

    #print "@Allcoords\n";
    #if($multi_frame eq "yes"){@extended_array = (@original_array) x 100}
    #die;
    #my @coords_set;#array of array using slicing, equal to frame numbers
    #if($multi_frame eq "yes"){@Allcoords = (@Allcoords) x $frameNo}
    my $coordSetNo =  @Allcoords/$natom;
    #print "$frameNo $coordSetNo\n";
    if(!@relax){
  #      die "cell number is not equal to coord set number - 1 in $file for relax\n" if($coordSetNo != $frameNo - 1 );
  #  }
  #  else{
        die "cell number is not equal to coord set number in $file\n" if($coordSetNo != $frameNo);
    }
    #element types of atoms for all frames

    my @Alltypes = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $file|grep -v "ATOMIC_POSITIONS (angstrom)"|awk '{print \$1}'|grep -v -- '--'`;
    map { s/^\s+|\s+$//g; } @Alltypes;


    unless(@Alltypes){
        @Alltypes = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $file|grep -v "ATOMIC_POSITIONS {angstrom}"|awk '{print \$1}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Alltypes; 
    }    
    unless(@Alltypes){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Alltypes = `grep -A $natom "ATOMIC_POSITIONS (angstrom)" $path/$filename.in|grep -v "ATOMIC_POSITIONS (angstrom)"|awk '{print \$1}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Alltypes; 
    }
    
    unless(@Alltypes){
        my $path = `dirname $file`;
        $path =~ s/^\s+|\s+$//g;
        my $filename = `basename $file`;
        $filename =~ s/^\s+|\s+$//g;
        $filename =~ s/\..*//g;
        #print "\$filename: $filename\n";
        #print "$path/$filename\n";
        @Alltypes = `grep -A $natom "ATOMIC_POSITIONS {angstrom}" $path/$filename.in|grep -v "ATOMIC_POSITIONS {angstrom}"|awk '{print \$1}'|grep -v -- '--'`;
        map { s/^\s+|\s+$//g; } @Alltypes; 
    }

    die "No element types in $file\n" unless(@Alltypes);

    my @element4atoms = @Alltypes[0..$natom -1];#only need the first set information
    my @used_ele = sort keys %{{ map{$_=>1} @element4atoms}};#filer out duplicate ones 
    my %ele2id = map { $used_ele[$_] => $_ + 1  } 0 .. $#used_ele;#make a hash for element -> type id for lmp
    #1 65.409  # Co
    #2 15.9994  # Ni
    my $mass4data;#mass for each element
    for my $t (0..$#used_ele){
        my $ele = $used_ele[$t];
        #print " $t $ele\n";
        #density (g/cm3), arrangement, mass        
        my $mass = &elements::eleObj("$ele")->[2];
        $mass4data .= $t+1 . " $mass  \# $ele\n";
    }
   
    chomp $mass4data;#move the new line for the last line
    # making data files below:
    #create the output folder
    `rm -rf $md_path/data_files`;
    `mkdir -p $md_path/data_files`;
    my $final_number;
    if(@relax){
        $final_number = $frameNo - 2;#from 0 to the last but last one skipped for relax
    }
    else{
        $final_number = $frameNo - 1;
    }

    for my $fr (0..$final_number){#loop over all frames
        my @box;
        for my $d (0..2){#loop over cell vectors
            my @temp = split (/\s+/,$AllCELL_PARAMETERS[$fr * 3 + $d]);
            map { s/^\s+|\s+$//g; } @temp;
            for my $i (@temp){ #loop over each component of each vector
                push @{$box[$d]},$i;
            }
        }  
        
        my $a = ( ${$box[0]}[0]**2 + ${$box[0]}[1]**2 + ${$box[0]}[2]**2 )**0.5;
        my $b = ( ${$box[1]}[0]**2 + ${$box[1]}[1]**2 + ${$box[1]}[2]**2 )**0.5;
        my $c = ( ${$box[2]}[0]**2 + ${$box[2]}[1]**2 + ${$box[2]}[2]**2 )**0.5;
        my $cosalpha = (${$box[1]}[0]*${$box[2]}[0] + ${$box[1]}[1]*${$box[2]}[1] + ${$box[1]}[2]*${$box[2]}[2])/($b*$c);
        my $cosbeta  = (${$box[2]}[0]*${$box[0]}[0] + ${$box[2]}[1]*${$box[0]}[1] + ${$box[2]}[2]*${$box[0]}[2])/($c*$a);
        my $cosgamma = (${$box[0]}[0]*${$box[1]}[0] + ${$box[0]}[1]*${$box[1]}[1] + ${$box[0]}[2]*${$box[1]}[2])/($a*$b);
        my $lx = sprintf("%.6f",$a);
        my $xy = sprintf("%.6f",$b*$cosgamma);
        my $xz = sprintf("%.6f",$c*$cosbeta);
        my $ly = sprintf("%.6f",sqrt($b**2 - $xy**2));
        my $yz = sprintf("%.6f",($b*$c*$cosalpha-$xy*$xz)/$ly);
        my $lz = sprintf("%.6f",sqrt($c**2 - $xz**2 - $yz**2));
        my @cell4data = (
            "0.000000 $lx xlo xhi",
            "0.000000 $ly ylo yhi",
            "0.000000 $lz zlo zhi",
            "$xy $xz $yz xy xz yz"
        );
        map { s/^\s+|\s+$//g; } @cell4data;     
        my $cell4data = join("\n",@cell4data);
        my $coords4data;
        #print "$cell4data\n";
        for my $d (0..$natom -1){#loop over coords
            my $string = ($fr * $natom + $d) .": $Allcoords[$fr * $natom + $d]";
             #print "$string\n";
             my @tempQEcoord = split (/\s+/,$Allcoords[$fr * $natom + $d]);
             map { s/^\s+|\s+$//g; } @tempQEcoord;
             #print "@tempQEcoord[1..3]\n";
            # for my $i (@temp){ #loop over each component of each vector
                 my $temp_coord = eval($d + 1)." $ele2id{$tempQEcoord[0]} @tempQEcoord[1..3]\n";
                 #my $temp_coord = ($d + 1) . " "."$ele2id{$tempQEcoord[0]}" . " ". "@tempQEcoord[1..3]\n";
                 $coords4data .= $temp_coord;
             # }
            }#over QE atom coords
            chomp $coords4data;
### set hash for heredoc
            my $temp_id = sprintf("%03d",$fr);
            my %hash_para = (
            output_file => " $md_path/data_files/$temp_id.data",
            natom => "$natom",
            ntype => "$ntype",
            cell => "$cell4data",
            masses => "$mass4data",            
            coords => "$coords4data"
            );
            &make_data_file(\%hash_para);
            
            #print "$coords4data\n";
    }#all frames of a sout file  
  
}#all sout files

sub make_data_file{

my ($para_hr) = @_;
my $here_doc =<<"END_MESSAGE";
# LAMMPS data file written by OVITO Basic 3.7.8

$para_hr->{natom} atoms
$para_hr->{ntype} atom types

$para_hr->{cell}

Masses

$para_hr->{masses}

Atoms  # atomic

$para_hr->{coords}
END_MESSAGE
my $temp = $para_hr->{output_file};
chomp $temp;
open(FH, "> $temp") or die $!;
print FH $here_doc;
close(FH);
#`cat << $QEinput > $temp`;
}
