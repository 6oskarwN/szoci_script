#!/usr/bin/perl


#szocimotoros topic parser v1.2

#usage: go to szocimotoros and download html page only
#put it in /source
#run the script


#IN WORK: Change Request: assemble the output into single page
#SOLVED Change Request: <br>, <br \> to be replaced by \n in result text.
#SOLVED printf bug
#not done: Must put some tabs in front of it to keep indenting

#SOLVED fault: &percent;  to be replaced by % in result text.
#Change request: sa produca outputul direct in fisier.txt

use strict;
use warnings;

my $callFILE;			#read-file
my $threadFILE;  #read-in thread file
my $wFILE;			#write thread file

my @slurpstr;  #string used for slurp
my @childslurp;

my @FILES;                      #list of files in directory
my $filename;			#nume fisier, string

my %hash = ();			#hash cu legatura referinta > fisier
my $child;          #iterator prin array-ul de valoare

my $fline;

my @splitter;

my $nickname;
my $textbody="";       #variabila ce tine blabla-ul
my $record;			#actual record-ID
my $reference;			#reference to older record-ID (father?)
my $counter;                    #counter: 0-no record active 1-nick expected 2-textbody expected 3-record ID expected 4-reference of father that can be void or real


#my $k;
#my $v;

opendir(DIR, "source"); #source e calea sursa
@FILES= readdir(DIR); 

foreach $filename(@FILES)
{
	
if($filename =~ /.htm/) 
{

####read in record by record(line by line)

@splitter=split(/.htm/,$filename);	#obtinem in $splitter[0] numele fara extensie, daca e nevoie
print "$splitter[0] \n";			#debug, see name of ingested file

open (callFILE,"<" ,  "source\\$filename"); #source e calea sursa
seek(callFILE,0,0);                        #goto beginning
$counter=0;
while($fline=<callFILE>)                   #cat timp nu ai ajuns la sfastitul HTML-ului, il parsezi
{
chomp($fline);

#daca incepe un nou record
if($fline =~ /^  \<div class\=\"forumhozzaszolasfejlec\"\>/) 
{ 
	$counter=1;
#   print "$fline \n"; #debug
}


#gasim nick-ul
if(($counter eq 1) and ($fline =~ /^   \<span class\=\"forumhozzaszolasnick\"\>/))
{
	$nickname="NOBODY";
	$counter=2;
	@splitter=split(/<span class\=\"forumhozzaszolasnick\"\>/,$fline);
		@splitter=split(/\<\/span\>/,$splitter[1]);
if (defined $splitter[0]) 
   {		$nickname=$splitter[0];
  }
# print "$nickname \n"; #debug

}

#gasim textbody start
if(($counter eq 2) and ($fline =~ /^  \<div class\=\"forumhozzaszolasszoveg\"\>/))
{
  $textbody="";
	$counter=31; #body with or w/o end of textbody should be next
}

if ($counter eq 31)
{

if ($fline =~ /\<\/div\>/)
   {	$counter=3; #record ID is expected next
  }


    $fline =~ s/\&percent\;/\%/g;
    $fline =~ s/\<\/div\>//g;
    $fline =~ s/\<div class\=\"forumhozzaszolasszoveg\"\>//g;
    $fline =~ s/\<br \/\>/\n/g;
    $fline =~ s/\<br\>/\n/g;
    $textbody = "$textbody$fline";
   
#print "$textbody \n"; #debug
#print "textbody blabla \n"; #debug


}




#gasim actual record ID
if(($counter eq 3) and ($fline =~ /^   \<div class\=\"forumsorszam\"\>/) )
{
	$counter=4;
	
	@splitter=split(/\(/,$fline);
		@splitter=split(/\)/,$splitter[1]);
		$record=$splitter[0];
#print "record found: $record \n"; #debug
}

#gasim father ID
if(($counter eq 4) and ($fline =~ /^   \<div class\=\"forumreferrer\"\>/))
{
  $reference = "null";
	$counter=51; #end of ref should be next
}

if ($counter eq 51)                    #father ID can be extracted
{
if($fline =~ /hu\/forumok\/topic/)
  {
	@splitter=split(/\#/,$fline);
		@splitter=split(/\"/,$splitter[1]);
		$reference=$splitter[0];
		
#print "fatherID: $reference \n"; #debug
   }
elsif ($fline =~ /\<\/div\>/)          #end of record will be detected
   {	
#   	print "EOrecord, father ID is: $reference \n\n"; #debug
     $counter=0;  
     #aici se termina, end of record detected,
####################################################################
# aici se face treaba upside-down
### print test results, the record:
#print "recID: $record\n";
#print "Nick: $nickname\n";
#print "textbody $textbody\n";
#print "father: $reference\n\n";

@slurpstr = (); #initializam la empty, se va umple cu continut de fisier, daca se gaseste thread, daca nu, ramane empty.


### if reference exists in hash, it means that child thread file(s) already exists, we slurp it(them) in a single array and delete their respective file(s)

if (defined $hash { $record }) #hash(record)[] contine lista child-urilor pentru $record
 {
 	print "all children of $record: are: "; #debug
 	for $child ( 0 .. $#{ $hash{$record} } )
 	   {
      @childslurp =();
	   print "$hash{$record}[$child]"; #debug
      open (threadFILE,"<" ,  "result\\$hash{$record}[$child]") or die "Couldn't open file: $!"; #deschidem read-only
      @childslurp=<threadFILE>;
     # print "."; #debug?
      close (threadFILE);
#stergem fisierul copil-record, fiindca a fost inglobat     
	 my $tfname=$hash{$record}[$child];
     	 system("del", "result\\$tfname"); #sterge fisierul original(rm in linux)
      print ", "; #debug

		 #stergem si copilul din rolul de father din hash
#print "forget $hash{$record}[$child]\n";
#stergem apoil copilul din rolul de copil	 
#	 pop @{$hash{$record}},$hash{$record}[$child];  #stergem apoil copilul din rolul de copil	 - linie de cod defecta
 
      @slurpstr = (@slurpstr,@childslurp);  #se concateneaza la slurpstr continutul fisierului unui child
    }
  print "\n";
  }

### Avem un nou record, cu ce trebuie in el, si-l salvam ca fisier independent

{
#	print "threadfile $record established \n"; #debug
  open(threadFILE,">" ,  "result\\$record") or die "Couldn't open write file: $!"; #deschidem write
  seek(threadFILE,0,0); 
if ($reference eq "null") {
  print threadFILE "=================================\n";
                           }
 else {						   
  print threadFILE "$reference\n";
      }
  print threadFILE "$nickname\n";
  print threadFILE "$textbody\n"; 
  print threadFILE "$record\n";
  print threadFILE "\n"; 	
  print threadFILE "@slurpstr";   #adaugam la sfarsitul fisierului cu recordul, si continutul child-record-urilor
  close (threadFILE);
}


############################
#update hash table arrays

if ($reference ne "null")   #there is a father for current $record 
 {  
 	 push @{$hash{$reference}},$record;  #add new (eventually first) child for the reference
 
#print "hash status: %hash \n";
 } #.references added in hash

   } #.end of a record detected, all stuff with the record done
} #. end of if ($counter eq 51), means end of record content detection









} #.end reading actual input .htm file
close(callFILE);

} #.end parsing actual input htm file

} #.end parsing last input file

#print $hash;

#print "hash status: %hash \n";

#while ( ($k,$v) = each %hash ) {
#    print "$k <= $v\n";
#       }



################ END ################

