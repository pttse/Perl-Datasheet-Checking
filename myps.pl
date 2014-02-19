#!/usr/bin/perl   

# File Name:myps.pl
#
# This perl file displays a web form and processes the form inputs.
# It allows system programmers to make various checks on the 1)datasheets and 2)the Apache log of activity on the website.
#
# For the datasheets, currently it allows datasheets in pdf, doc format.
#
# Subroutines:
#  print_input_form()  	#print out the input form
#  handle_form_inputs() #handle form inputs on the web form
#  print_results()      #print corresponding form results on the webpage
#
#  get_file_details()   # put the pdf and doc files from the input root into corresponding hashes.
#  print_file_lists()   # print the file lists on the webpage  
#  print_apache_log_activities() #print the counts of the requests dual format datesheet in the apache log
#

##Author: Po Ting Tse (ptt1g12)
##Last modified date: 28-10-2013

use File::Find;  		#use the File find module, to list all files in the directory
use File::Basename;     #use the File Basename module, to return the file path of a file
use CGI ':standard';    #use the CGI modules and display the web form

print header;           # from CGI module sends a standard HTTP header
print start_html("Knurled Widgets Website Tools By ptt1g12");  #from CGI sends the top of the web page
print "<h1> Knurled Widgets Website Tools By ptt1g12</h1>\n";  #the header of the webpage

print_input_form();     #print the input form
handle_form_inputs();   #handle the form inputs
print_results();        #print the results

print end_html;         # CGI: sends the end of the html

#declare variables
$folderpath = "";       #the input hierarchy root
my @selectedOptions = (); #array of selected options from input
my %pdfHash         = (); #initialise a hash for the paths of required pdf files
my %docHash         = (); #initialise a hash for the paths of required doc files
my %pdfAndDocHash   = ();    #initialise a hash for the paths of both required doc and pdf files

#subroutine for printing out the input form
sub print_input_form {
	$method = "GET";    #using GET to retrieve the form entries(inputs)

	print start_form($method);

	#Textfield: input path of the hierarchy root
	print "<em>Path for the datasheet hierarchy root?</em><br>";
	print textfield('rootPath');
	print "<br/><br/>";

	#Textfield: input Apache Log file path
	print "<em>Apache Log file path name?</em><br>";
	print textfield('apacheLogPath');
	print "<br/>";

   	#Checkbox: select which datasheets would like to select: in pdf, word or both
	print "<p><em>List datasheets which occur</em><br>";
	print checkbox_group(
		-name      => 'selectedListOptions',
		-values    => [ 'in_pdf', 'in_doc', 'in_both' ],
		-linebreak => 'yes',
		-defaults  => 'in_both'
	);

	#RadioGroup: select whehther display the counts of pdf requests and doc requests for dual formal sheets or not.
	print
	"<p><em>Apache log counts of pdf requests and doc requests for dual format sheets only</em><br>";
	print radio_group(
		-name      => 'showApacheLogCount',
		-values    => [ 'yes', 'no' ],
		-linebreak => 'yes',
		-default   => 'yes'
	);

	print "<p>", reset;
	print submit( 'Action', 'Submit' );

	print end_form;
	print "<hr>\n";
}

#subroutine for handling form inputs
sub handle_form_inputs {

	#get the whole folder path from the input
	$folderpath = File::Spec->rel2abs( param('rootPath') );

	#get the selected list options from users
	@selectedOptions = param('selectedListOptions');

}



#subroutine for printing the form results
sub print_results {

	$query = $ENV{'QUERY_STRING'};    # get the query string using GET

	#print the result if the query is not empty
	if ( not( $query eq "" ) ) {      #if-1

		#find the files
		find( \&get_file_details, $folderpath );
		my $directory = param('rootPath');

		#check if the input path exist or not, then display error if it doesn't 
		unless ( -e $directory ) {
			print "<em>No such path for the datasheet hierarchy root. Please check again.</em>";
			return;
		}
		
		print_file_lists(); #print the file lists
		
		#if show apache log count is selected, then print the acitivities
		if ( param('showApacheLogCount') eq "yes" ) {    #if-2
			print_apache_log_activities();
			
		}    #end if-2

	}    #end if-1

}

#subroutine for printing the file lists on the webpage
sub print_file_lists {

	#hashtable for storing all list options
	my %listOptions = (
		in_pdf  => 'pdf',
		in_doc  => 'doc',
		in_both => 'dual format'
	);

	#array storing the key of the display list options
	my @allOptions = ( "in_pdf", "in_doc", "in_both" );

	#foreach avialable listing options
	foreach my $optionKey (@allOptions) {
		$currentOption = $listOptions{$optionKey};
		my @requiredPathList = ();

		if ( $optionKey eq "in_pdf" ) {
			@requiredPathList = sort ( keys(%pdfHash) );

		}elsif ( $optionKey eq "in_doc" ) {
			@requiredPathList = sort ( keys(%docHash) );
			
		}elsif ( $optionKey eq "in_both" ) {
			@requiredPathList = sort ( values(%pdfAndDocHash) );
		}

		#if select to list the files, print the datasheet lists
		if ( grep( /^$optionKey$/, @selectedOptions ) ) {
			print "<H2>List of " . $currentOption . " datasheets</H2>";
			print join( "<br/> ", @requiredPathList );
		}

		#print the number of the required data sheets
		print "<H2>Number of ", $currentOption, " data sheets = ",
		  scalar(@requiredPathList), "</H2>";

	}    #end foreach

}

#subroutine for printing apache log activities
sub print_apache_log_activities{
	#get the apache log path from the input
	$apacheLogPath = param('apacheLogPath');

	#open the required file
	open( INFILE, "<" . dirname(__FILE__) . "/" . $apacheLogPath . ".log" );

	#check if the apache log file path name is not valid
	if ( tell(INFILE) == -1 ) {
		print "<em>No such Apache Log file path name. Please check again.</em>";
		return;
		
	}else {    #else-2 apache log file reads succesffully

		#initial dual log counts variable
		my $pdfDualLogCount = 0;
		my $docDualLogCount = 0;

		#Read line by line of the log file
		while (<INFILE>) {
			my $currentLine = $_;
			chomp $currentLine;

			#search the line if it accessed a file
			my @fileStringMatch = ( $currentLine =~ m/.*\/(\w*\/)+(\w+)\.(pdf|doc)/i );

			#if no file found, continue to the next line
			if ( @fileStringMatch == 0 ) {
				next;
			}

			#get the whole hierarchy root of the file
			$viewedFilePath = $fileStringMatch[-2];

			#check if the file is in the dual format hash
			if ( exists $pdfAndDocHash{$viewedFilePath} ) {    #if-2
				my $fileExtension = uc( $fileStringMatch[-1] ) ; #set the file extension to upper case
				
				#if the file is in PDF, increment the pdf count by 1
				if ( $fileExtension eq "PDF" ) {
					$pdfDualLogCount++;

				#else if the file is in doc, increment the doc count by 1
				}elsif ( $fileExtension eq "DOC" ) {
							$docDualLogCount++;
				}

			}    #end if-2
		}    #end while

		#print the requests for dual format datasheets
		print "<H2>Number of pdf requests for dual format datasheets = ". $pdfDualLogCount . "</H2>";
		print "<H2>Number of doc requests for dual format datasheets = ". $docDualLogCount . "</H2>";

	}   # end else-2 apache log file reads succesffully	
	
}


#subroutine for getting the relative filename and path,
#put the pdf and doc files into corresponding hashes.
sub get_file_details {

	#use regular expression to filter files
	# File Name:
	# - (\w)+ -> at least one word contains  [0-9a-zA-Z_]
	# -> check the file extension
	# File extension:
	# - \.(pdf|doc)  -> only pdf and doc files are allowed
	# -  /i-> in a case-insenstive way
	my @matchedFiles = ( $_ =~ /(\w+)\.(pdf|doc)$/i );

	#if there is no matched file, return
	if ( @matchedFiles == 0 ) {
		return;
	}

	my $fileName      = $matchedFiles[0];    #retrieve the file name
	my $fileExtension =
	  uc( $matchedFiles[1] );    #convert the file type(pdf/doc) to upper case

	#display the full directory path
	$directoryStr = (
		substr $File::Find::dir,
		index( $File::Find::dir, $folderpath ) + ( length $folderpath ) + 1
	);


	my $datasheetName = "";
	#if the file is in the root 
	if ($directoryStr eq ""){
		$datasheetName = $fileName;
	}else{
			#combine the whole path of the datasheet
		$datasheetName = $directoryStr . "/" . $fileName;
	}
	

	#print $datasheetName;
	#if it is a PDF file, put it to pdfHash
	if ( $fileExtension eq "PDF" ) {
		$pdfHash{$datasheetName} = "EXIST";

		#if the file name also exists in doc format, put the filename in the pdfAndDocHash
		if ( exists( $docHash{$datasheetName} ) ) {
			$pdfAndDocHash{$fileName} = $datasheetName;
		}

	#else if it is a DOC file, put it to docHash
	}elsif ( $fileExtension eq "DOC" ) {
		$docHash{$datasheetName} = "EXIST";

		#if the file name also exists in pdf format, put the filename in the pdfAndDocHash
		if ( exists( $pdfHash{$datasheetName} ) ) {
			$pdfAndDocHash{$fileName} = $datasheetName;
		}
	}

}    #end sub
