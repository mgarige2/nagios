#Example Usage
```
ruby check_queue_jmx.rb --port 8778 --host amq.lax.reachlocal.com --attribute ConsumerCount --queue EDM.INCOMING --min-error 4
```
```
ruby check_queue_throughput.rb --port 8778 --host amq.lax.reachlocal.com --queue EDM.INCOMING --attribute DequeueCount --min-range 10 --max-range 60 --min-error 20 --datastore /rl/data/local/datastore/
```
```
ruby check_broker_jmx.rb --port 8778 --host amq.lax.reachlocal.com --attribute StorePercentUsage --max-error 90 --max-warn 80
```
```
ruby check_jmx.rb --port 8778 --host papp1002.lax.reachlocal.com --url 'java.lang:type=OperatingSystem/OpenFileDescriptorCount' --max-warn 800 --max-error 999
```
#Usage
```
Usage: check_queue_jmx [options]
    -q, --queue QUEUE                queue to check
    -m, --min-error MIN-ERROR        minimum threshold for error
    -M, --max-error MAX-ERROR        maximum threshold for error
    -w, --min-warn MIN-WARNING       minimum threshold for warning
    -W, --max-warn MAX-WARNING       maximum threshold for warning
    -a, --attribute ATTRIBUTE        attribute to check
    -f  --host HOST                  hostname running jolokia
    -p, --port PORT                  port to connect to jolokia
    -h, --help                       Returns this help message.
```

```
Usage: check_queue_throughput [options]
    -q, --queue QUEUE                queue to check
    -m, --min-error MIN-ERROR        minimum threshold for error
    -M, --max-error MAX-ERROR        maximum threshold for error
    -w, --min-warn MIN-WARNING       minimum threshold for warning
    -W, --max-warn MAX-WARNING       maximum threshold for warning
    -a, --attribute ATTRIBUTE        attribute to check
    -f, --host HOST                  hostname running jolokia
    -p, --port PORT                  port to connect to jolokia
    -r, --min-range MINRANGE         minimum number of minutes to look back for delta
    -R, --max-range MAXRANGE         maximum number of minutes to look back for delta
    -d, --datastore DATASTORE        location of datastore directory
    -h, --help                       Returns this help message.
```                   

```
Usage: check_broker_jmx [options]
    -m, --min-error MIN-ERROR        minimum threshold for error
    -M, --max-error MAX-ERROR        maximum threshold for error
    -w, --min-warn MIN-WARNING       minimum threshold for warning
    -W, --max-warn MAX-WARNING       maximum threshold for warning
    -a, --attribute ATTRIBUTE        attribute to check
    -f, --host HOST                  hostname running jolokia
    -p, --port PORT                  port to connect to jolokia
    -h, --help                       Returns this help message.
```
```
Usage: check_jmx [options]
    -m, --min-error MIN-ERROR        minimum threshold for error
    -M, --max-error MAX-ERROR        maximum threshold for error
    -w, --min-warn MIN-WARNING       minimum threshold for warning
    -W, --max-warn MAX-WARNING       maximum threshold for warning
    -u, --url URL                    jolokia read url to hit. Must return an integer!
    -f, --host HOST                  hostname running jolokia
    -p, --port PORT                  port to connect to jolokia
    -h, --help                       Returns this help message.
```
#Tips
- Queue , attribute, host and port are required for the queue related checks.  For the broker related checks queue is not required, nor an option.
- The check broker check is for accessing attributes related to the broker it self, not queues.
- min-error, max-error, min-warning and max-warning can be used in any combination necessary
- attribute must be an integer
- The generic check_jmx url check will only work for some values as the returned data structures vary wildly. If it does not work, Michael Hogg can create a fix for your case.