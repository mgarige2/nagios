<?php

$this->MACRO['TITLE']   = "Sales Office Latency";
$this->MACRO['COMMENT'] = "Aggregated Sales Office Latency";

$services = $this->tplGetServices("reachlocalsales","PING");

#throw new Kohana_exception(print_r($services,TRUE));

$ds_name[0] = "Sales Office Ping Times";
$opt[0]     = "--title \"Ping Times\"";
$def[0]     = "";

foreach($services as $key=>$val){
    #
    # get the data for a given Host/Service
    $data = $this->tplGetData($val['host'],$val['service']);
    #
    # Throw an exception to debug the content of $data
    # Just to get Infos about the Array Structure
    #
    #throw new Kohana_exception(print_r($data,TRUE));
    $hostname   = rrd::cut($data['MACRO']['HOSTNAME']);
    $def[0]    .= rrd::def("var$key" , $data['DS'][0]['RRDFILE'], $data['DS'][0]['DS'] );
    $def[0]    .= rrd::line1("var$key", rrd::color($key), $hostname);
    $def[0]    .= rrd::gprint("var$key", array("MAX", "AVERAGE"));
}
?>

