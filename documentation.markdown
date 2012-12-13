### Description

<code>xgridstatus</code> is a command-line utility to retrieve information about controllers, grids, agents and jobs. It provides some of the functionality of Xgrid Admin and more: agent list, job list, agent statistics, job statistics, automatic removal of inactive agents. The report about agent statistics is for instance used to provide information for the [OpenMacGrid](http://www.macresearch.org) widget.

The features include:

* xml, plist, text or binary output (-xltb options)
* costum reports may include: details grid per grid (-g option), controller per controller (-c option), with or without agent list, job list, agent statistics or job statistics (-ajAJ options)
* periodic reports (-r) to disk (-o) or to stdout (default)
* simultaneous connection to several controllers (-hpk)
* automatic reconnections after controller crashes
* storage of controller passwords in the user keychain (-k)
* automatic removal of inactive agents (-m)

### Usage

	xgridstatus [ [-h hostname] [-p password | -k password] ]* [-r interval] [-o file] [-abcgjlmstvxAJT]


* Connection options (note that you can include several -h options, to connect to several controllers)

	    -h hostname  Bonjour name or address of an xgrid controller
	                 (default is localhost)
	    -p password  client password, only needed if one was set.
	                 A hostname is attributed the first password found
	                 after it in the list of arguments, if any.
	    -k password  when -k is used instead of the -p flag, the password
	                 will be saved in the user default Keychain, if available.
	                 Once a password is stored, it will always be tried and you
	                 do not need to include it in subsequence connections.
	                 The password is stored and may overwrite a previous value
	                 even if the connection fails.

* Output options

	    -r interval  interval at which to repeat the status report, in seconds
	                 (if 0 or unspecified, xgridstatus exits after the first report)
	    -o file      path at which to save the output (default is stdout).
	                 If interval is set, the file is overwritten at each report.
	    -b           output format is plist binary (see man page for plutil)
	    -l           output format is plist xml
	    -t           output format is text = old plist (default)
	    -x           output format is xml (compatible with Xgrid@Stanford widget)

* Report options

	    -c           include reports for individual controllers
	    -g           include reports for individual grids (implies -c)
	    -A           include agent statistics
	    -J           include job statistics
	    -a           include agent list
	    -j           include job list
	    -T           include time stamp

* Cleanup option

	    -m           remove agents that are offline with no CPU activity
                     (no effect without the -a or -A option also selected)
					 
* Verbose options (the default setting depends on the other options)

	    -v           verbose, opposite of silent
	    -s           silent, opposite of verbose

### Widget usage

For output compatible with Xgrid@Stanford widget, use the following options:

	    xgridstatus -h host1 [-h host2 ...] [-s] -xAT -r 10 -o path/to/file.xml

### User defaults

In verbose mode, progress messages are displayed every 5 secs.
This default can be changed using the following command:

    defaults write xgridstatus IntervalForLoadingProgressReports xxx

where xxx is a number of seconds.


### Acknowledgements

Many thanks to Kevin Ballard (http://kevin.sb.org) for his MethodSwizzle implementation, that xgridstatus uses to work around a bug in Xgrid. In some circumstances, the BEEP framework raises an exception because the -addObject: method of the NSCFArray class is called with a nil argument. By skipping this exception (using the MethodSwizzle trick), xgridstatus is able to get things going and continue its work.


### Examples


* Example 1 : displays the list of grids for localhost (there is only 1 grid)

		xgridstatus -g
	

		{
		    controllers = {localhost = {grids = {Xgrid = {identifier = 0; name = Xgrid; }; }; }; }; 
		}


* Example 2 : displays the list of agents (-a) and jobs (-j) for each grids (-g) in localhost

		xgridstatus -gaj
	
		{
		  controllers = {
		    localhost = {
		      grids = {
		        Xgrid = {
		          identifier = 0; 
		          name = Xgrid; 
		          agents = {
		            "John Doe's Powerbook" = {
		              ActiveCPUPower = 1500; 
		              ActiveProcessorCount = 1; 
		              Address = "121.122.123.124"; 
		              Identifier = "John Doe's Powerbook"; 
		              Name = "John Doe's Powerbook"; 
		              State = Working; 
		              TotalCPUPower = 1500; 
		              TotalProcessorCount = 1; 
		            }; 
		          }; 
		          jobs = {
		            312 = {
		              ActiveCPUPower = 0; 
		              ApplicationIdentifier = "com.apple.xgrid.cli"; 
		              CompletedTaskCount = 1; 
		              DateStarted = 2007-03-11 23:01:09 -0700; 
		              DateStopped = 2007-03-11 23:01:11 -0700; 
		              DateSubmitted = 2007-03-11 23:01:07 -0700; 
		              Identifier = 312; 
		              Name = "/bin/echo"; 
		              PercentDone = 100; 
		              State = Finished; 
		              TaskCount = 1; 
		            }; 
		            313 = {
		              ActiveCPUPower = 1500; 
		              ApplicationIdentifier = "com.apple.xgrid.cli"; 
		              CompletedTaskCount = 0; 
		              DateStarted = 2007-03-11 23:01:12 -0700; 
		              DateStopped = ""; 
		              DateSubmitted = 2007-03-11 23:01:09 -0700; 
		              Identifier = 313; 
		              Name = "/bin/echo"; 
		              PercentDone = 0; 
		              State = Running; 
		              TaskCount = 1; 
		            }; 
		           };
		        }; 
		        SpecialGrid = {
		          agents = {
		            "Steve Jobs MacBook" = {
		              ActiveCPUPower = 1830; 
		              ActiveProcessorCount = 1; 
		              Address = "73.80.79.68"; 
		              Identifier = "Steve Jobs MacBook"; 
		              Name = "Steve Jobs MacBook"; 
		              State = Working; 
		              TotalCPUPower = 1830; 
		              TotalProcessorCount = 1; 
		            }
		          }; 
		          jobs = {}; 
		        }
		      }; 
		    }; 
		  }; 
		}


* Example 3 : displays the job statistics (-J) for each of the controllers (-c), as well as the aggregated values

		xgridstatus -h localhost -h xgrid.myhost.com -p goodone -cJ
	
		{
		  controllers = {
		    "xgrid.myhost.com" = {
		      canceledJobCount = 0; 
		      failedJobCount = 0; 
		      finishedJobCount = 6; 
		      pendingJobCount = 2; 
		      runningJobCount = 1; 
		      startingJobCount = 0; 
		      suspendedJobCount = 0; 
		      totalJobCount = 9; 
		      workingJobCount = 0; 
		    }; 
		    localhost = {
		      canceledJobCount = 0; 
		      failedJobCount = 0; 
		      finishedJobCount = 7; 
		      pendingJobCount = 10; 
		      runningJobCount = 5; 
		      startingJobCount = 0; 
		      suspendedJobCount = 1; 
		      totalJobCount = 23; 
		      workingJobCount = 0; 
		    }; 
		  }; 
		  canceledJobCount = 0; 
		  failedJobCount = 0; 
		  finishedJobCount = 13; 
		  pendingJobCount = 12; 
		  runningJobCount = 6; 
		  startingJobCount = 0; 
		  suspendedJobCount = 1; 
		  totalJobCount = 32; 
		  workingJobCount = 0; 
		}


* Example 4 : displays the aggregated agent statistics (-A) for the 2 controllers listed

		xgridstatus -h localhost -h xgrid.myhost.com -k evenbetter -A
	
		{
		  availableAgentCount = 1; 
		  availableProcessorCount = 19; 
		  offlineAgentCount = 125; 
		  offlineProcessorCount = 10; 
		  onlineAgentCount = 15; 
		  onlineProcessorCount = 29; 
		  totalAgentCount = 140; 
		  unavailableAgentCount = 0; 
		  unavailableProcessorCount = 0; 
		  workingAgentCount = 14; 
		  workingAgentPercentage = 10; 
		  workingMegaHertz = 38; 
		  workingProcessorCount = 28; 
		}
