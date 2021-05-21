#!/usr/bin/perl


#szocimotoros topic parser v1.3
#Made in Romania by "FraMZ" @ https://www.tapatalk.com/groups/mzbrothersfr/
#
#Use-case(what problem is solved?): As a Kindle user, I would like to obtain 
#and load offline a nicely formatted text file to read the discussions 
#of that forum, but grouped on topics(raised problem plus connected replies),
#not in a chain-mail manner as is native on the forum. 
#
#usage: go to http://szocimotoros.hu and download individual pages from a forum, 
#e.g. first 5 pages from  MZ (http://szocimotoros.hu/hu/forumok/topic/10) 
#save them directly in /source directory (create this directory first)
#have /result directory also created
#run the script using perl. 
#In the /result each topic will be saved as a file.
#for Kindle, the files can be concatenate
#Win cmd: copy * newfile.txt
#Linux cat * > newfile.txt

# $ perl szociparser_v1_3.pl

#Script located in the parent of /source and /result (see below)
#each discussion will result in a separate file in the /result directory. You can manipulate them further.
#I concat them into unique file then read it from Kindle

#Next version: Must put some tabs in front of it to keep indenting

use strict;
use warnings;
use Encode;

my $callFILE;	 #read-file
my $threadFILE;  #read-in thread file
my $wFILE;	 #write thread file

my @slurpstr;    #string used for slurp
my @childslurp;

my @FILES;       #list of files in directory
my $filename;	 #filename, string

my %hash = ();	 #hash that keeps the reference > file
my $child;       #iterator though the value array

my $fline;

my @splitter;

my $nickname;
my $textbody="";       #variable that stores the blabla
my $record;	       #actual record-ID
my $reference;	       #reference to older record-ID (father?)
my $counter;           #counter: 0-no record active 1-nick expected 2-textbody expected 3-record ID expected 4-reference of father that can be void or real


#my $k;
#my $v;

opendir(DIR, "source"); #source e is the path of source htmls, downloaded
@FILES= readdir(DIR); 

foreach $filename(@FILES)
{
	
if($filename =~ /.htm/) 
{

####read in record by record(line by line)

@splitter=split(/.htm/,$filename);	#$splitter[0] stores name without extension, if needed
print "$splitter[0] \n";		#debug, see name of ingested file

open (callFILE,"<:encoding(ISO-8859-2)","source\/$filename");#source e is the path of source htmls, downloaded
seek(callFILE,0,0);                     #goto beginning
$counter=0;
while($fline=<callFILE>)                #while not at the end of HTML, parse it.
{
chomp($fline);
$fline = encode('UTF-8', $fline);

#Forum-specific string encountered at the beginning of new record
if($fline =~ /^  \<div class\=\"forumhozzaszolasfejlec\"\>/) 
{ 
	$counter=1;
#   print "$fline \n"; #debug
}


#finding nickname, again a forum-specific string
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

#finding textbody start
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




#find actual record ID
if(($counter eq 3) and ($fline =~ /^   \<div class\=\"forumsorszam\"\>/) )
{
	$counter=4;
	
	@splitter=split(/\(/,$fline);
		@splitter=split(/\)/,$splitter[1]);
		$record=$splitter[0];
#print "record found: $record \n"; #debug
}

#father ID to be found next
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
     #here it ends, end of record detected,
####################################################################
# here the upside-down job follows
### print test results, the record:
#print "recID: $record\n";
#print "Nick: $nickname\n";
#print "textbody $textbody\n";
#print "father: $reference\n\n";

@slurpstr = (); #empty, will fill with content if there are discussions.

### if reference exists in hash, it means that child thread file(s) already exists, we slurp it(them) in a single array and delete their respective file(s)

if (defined $hash { $record })             #hash(record)[] contains childs list for a $record
 {
 	print "all children of $record: are: "; #debug
 	for $child ( 0 .. $#{ $hash{$record} } )
 	   {
      @childslurp =();
	   print "$hash{$record}[$child]"; #debug
      open (threadFILE,"<" ,  "result\/$hash{$record}[$child]") or die "Couldn't open file: $!"; #open read-only
      @childslurp=<threadFILE>;
     # print "."; #debug?
      close (threadFILE);
#deleting child-record file because it was incorporated    
	 my $tfname=$hash{$record}[$child];
     	 system("rm", "result\/$tfname"); #linux variant
#     	 system("del", "result\\$tfname"); #Windows variant
      print ", "; #debug

		 #stergem si copilul din rolul de father din hash
 
      @slurpstr = (@slurpstr,@childslurp);  #concat to slurpstr the contect of a child file
    }
  print "\n";
  }

### We have a recording with everything inside, saving it as independent file

{
#	print "threadfile $record established \n"; #debug
  open (threadFILE,">" ,  "result\/$record") or die "Couldn't open write file: $!"; #deschidem write
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
  print threadFILE "@slurpstr";   #add child records at the end of record
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

