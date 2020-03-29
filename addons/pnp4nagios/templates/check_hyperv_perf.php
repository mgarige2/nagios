<?php
# File    : check_hyperv_perf.php
# Version : 0.1
# Date    : 2/8/13
# Author  : Nathan Lewis <natewlew@gmail.com>
# Summary : Template to Show Hyper-V Performance. Works with check_hyperv_perf plugin.
# Licence : GPL http://www.gnu.org/licenses/gpl.txt

$green = "#33FF00E0";
$yellow = "#FFFF00E0";
$red = "#F83838E0";
$blue = "#0066FF";
$grey = "#FF00FF";

$mycolors = array($green,$red,$blue,$grey,$yellow);

$myservice = $this->MACRO['AUTH_SERVICEDESC'];

//////////////////////////////
// Hyper-V Guest CPU Usage
if($myservice == "Hyper-V Guest CPU Usage") {

    $ds_name[1] = "Guest";
    $opt[1] = "--vertical-label \"%\" --title \"Guests on $hostname\" ";
      
    $ds_name[2] = "Host";
    $opt[2] = "--vertical-label \"%\" --title \"Host - $hostname\" ";
          
    $def[1] = "";
    $def[2] = "";

    $mycount1 = 0;
    $mycount2 = 0;

    foreach ($this->DS as $KEY=>$VAL) {

        $myname = $VAL['NAME'];
        $mylabel = $VAL['LABEL'];
        $myrddfile = $VAL['RRDFILE'];
        $myds = $VAL['DS'];
        
        if(preg_match('/Virtual/', $myname)) {
        
            $mycolor = $mycolors[$mycount1];
            
            $def[1] .= "DEF:$myname=$myrddfile:$myds:AVERAGE " ;
            $def[1] .= "AREA:$myname$mycolor:\"$mylabel\: \t\t\g\":STACK  " ;
            $def[1] .= "GPRINT:$myname:LAST:\"%6.1lf last\" " ;
            $def[1] .= "GPRINT:$myname:AVERAGE:\"%6.1lf avg\" " ;
            $def[1] .= "GPRINT:$myname:MAX:\"%6.1lf max\\n\" " ;
                    
            $mycount1++;
        }
        
        if(preg_match('/Hypervisor/', $VAL['NAME'])) {
            
            $mycolor = $mycolors[$mycount2];
            
            $def[2] .= "DEF:$myname=$myrddfile:$myds:AVERAGE " ;
            $def[2] .= "AREA:$myname$mycolor:\"$mylabel\: \t\t\g\":STACK  " ;
            $def[2] .= "GPRINT:$myname:LAST:\"%6.1lf last\" " ;
            $def[2] .= "GPRINT:$myname:AVERAGE:\"%6.1lf avg\" " ;
            $def[2] .= "GPRINT:$myname:MAX:\"%6.1lf max\\n\" " ;
            
            $mycount2++;
        }
        
    }

}

//////////////////////////////
// Hyper-V Host CPU
else if($myservice == "Hyper-V Host CPU") {

    $ds_name[1] = "Logical";
    $opt[1] = "--vertical-label \"%\" --title \"Logical on $hostname\" ";
      
    $ds_name[2] = "Root";
    $opt[2] = "--vertical-label \"%\" --title \"Root on $hostname\" ";
          
    $def[1] = "";
    $def[2] = "";

    $mycount1 = 0;
    $mycount2 = 0;

    foreach ($this->DS as $KEY=>$VAL) {

        $myname = $VAL['NAME'];
        $mylabel = $VAL['LABEL'];
        $myrddfile = $VAL['RRDFILE'];
        $myds = $VAL['DS'];
        
        if(preg_match('/Logical/', $myname)) {
        
            $mycolor = $mycolors[$mycount1];
            
            $def[1] .= "DEF:$myname=$myrddfile:$myds:AVERAGE " ;
            $def[1] .= "AREA:$myname$mycolor:\"$mylabel\: \t\t\g\":STACK  " ;
            $def[1] .= "GPRINT:$myname:LAST:\"%6.1lf last\" " ;
            $def[1] .= "GPRINT:$myname:AVERAGE:\"%6.1lf avg\" " ;
            $def[1] .= "GPRINT:$myname:MAX:\"%6.1lf max\\n\" " ;
                    
            $mycount1++;
        }
        
        if(preg_match('/Root/', $VAL['NAME'])) {
            
            $mycolor = $mycolors[$mycount2];
            
            $def[2] .= "DEF:$myname=$myrddfile:$myds:AVERAGE " ;
            $def[2] .= "AREA:$myname$mycolor:\"$mylabel\: \t\t\g\":STACK  " ;
            $def[2] .= "GPRINT:$myname:LAST:\"%6.1lf last\" " ;
            $def[2] .= "GPRINT:$myname:AVERAGE:\"%6.1lf avg\" " ;
            $def[2] .= "GPRINT:$myname:MAX:\"%6.1lf max\\n\" " ;
            
            $mycount2++;
        }
        
    }

}

//////////////////////////////
// Hyper-V Guest Network Usage or Hyper-V Guest Storage Perf
else {

    $mystartcount = 0;
    $mychartcount = 1;
    $myguestcount = 1;

    //Create a new chart every 2 DataSources.
    foreach ($this->DS as $KEY=>$VAL) {

        $myname = $VAL['NAME'];
        $mylabel = $VAL['LABEL'];
        $myrddfile = $VAL['RRDFILE'];
        $myds = $VAL['DS'];
        
        $guestname = explode(" ", $mylabel);
        
        // Create the chart Header
        if($myguestcount > 2 || $mystartcount == 0) {
        
            // If this is not the first loop, increase the chart count.
            if($mystartcount > 0) {
                $mychartcount++;
                $myguestcount = 1;
            }
            
            $ds_name[$mychartcount] = $guestname;
            $opt[$mychartcount] = "--vertical-label \"Bytes\" --title \"$myservice on $guestname[0]\" ";     
            $def[$mychartcount] = "";
        }
    
        $mycolor = $mycolors[$myguestcount];
        
        array_shift($guestname);
        $mylabel = implode(" ", $guestname);
        
        $def[$mychartcount] .= "DEF:$myname=$myrddfile:$myds:AVERAGE " ;
        $def[$mychartcount] .= "LINE1:$myname$mycolor:\"$mylabel\: \t\t\g\"  " ;
        $def[$mychartcount] .= "GPRINT:$myname:LAST:\"%6.1lf last\" " ;
        $def[$mychartcount] .= "GPRINT:$myname:AVERAGE:\"%6.1lf avg\" " ;
        $def[$mychartcount] .= "GPRINT:$myname:MAX:\"%6.1lf max\\n\" " ;
                   
        $myguestcount++;
        $mystartcount = 1;
    }

}





















?>

