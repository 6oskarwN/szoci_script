# szoci_script
perl script that splits the continous thread from szocimotoros.hu forums 

Made in Romania by "FraMZ" @ https://www.tapatalk.com/groups/mzbrothersfr/

Use-case(what problem is solved?): As a Kindle user, I would like to load a nicely formatted text file to read offline the discussions 
of that forum, but grouped on topics(raised problem plus connected replies), not in a chain-mail manner as is native on the forum. 

Usage: go to http://szocimotoros.hu and download individual pages from a forum, e.g. first 5 pages from  MZ (http://szocimotoros.hu/hu/forumok/topic/10) 
That would amount the discussions of the last 2 years
-save them directly in /source directory (create this directory first)
-have /result directory also created
-run the script using perl. 
In the /result each topic will be saved as a numbered file, where the name is the code of the topic

For Kindle, the files can be concatenated 
Windows cmd: copy * newfile.txt
Linux cat * > newfile.txt

