<?php
class Builds {

  protected static $db;

  protected static $DB_NAME = 'releng';
  protected static $DB_HOST = 'localhost';
  protected static $DB_USER = 'relengro';
  protected static $DB_PASS = 'releng';

  protected static $colors = array("0022ff", "22ff22", "ff0000", "00aaaa", "ff00ff",
                "ffa500", "cc0000", "0000cc", "0080C0", "8080C0",
                "FF0080", "800080", "688e23", "408080", "808000",
                "000000", "00FF00", "0080FF", "FF8000", "800000",
                "FB31FB");

  public static function init() {
    if(!self::$db) {
      self::$db = new mysqli(self::$DB_HOST, self::$DB_USER, self::$DB_PASS, self::$DB_NAME);
      if(!self::$db) {
        throw new Exception('Unable to connect to database [' . self::$db->connect_error . ']');
      }
    }
  }

  public static function fetchReleaseData($hostname) {
    self::init();
    $i = 0;
    $output = array();
    if(!$result = self::$db->query('select env,country,farm,time,buildname,product from releng.release where servers like \'%' . $hostname . '%\' order by time desc limit 25;')) {
        throw new Exception('There was an error running the query [' . self::$db->error . ']');
    }
    while($row = $result->fetch_assoc()) {
        $output[] = array("time"=>$row['time'], "buildname"=>$row['buildname'], "color"=>self::$colors[($i % count(self::$colors))]);
        $i++;
    }
    return $output;
  }
}

