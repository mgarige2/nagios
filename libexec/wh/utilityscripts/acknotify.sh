#!/bin/sh -x 

SUBJECT="Nagios Acknowledged & Disabled Hosts/Services"
EMAIL"shyamji.pillai@reachlocal.com,mark.stafford@reachlocal.com"
EMAILMESSAGE="/tmp/tmpemailout"

echo "From: nagios@reachlocal.com" >> $EMAILMESSAGE
echo "To: $EMAIL" > $EMAILMESSAGE
echo "MIME-Version: 1.0" >> $EMAILMESSAGE
echo "Content-Type: text/html;" >> $EMAILMESSAGE
echo "Subject: $SUBJECT" >> $EMAILMESSAGE
echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">" >> $EMAILMESSAGE
echo "<HTML><HEAD></HEAD></BODY>" >> $EMAILMESSAGE
 
echo "The following services and hosts are not sending notifications either because they are disabled or they've been acknowledged:<BR>" >> $EMAILMESSAGE
echo "<BR>" >> $EMAILMESSAGE

for i in AMS IAD LAX NRT PHX SYD 
do
        echo "<U><H2>$i DATACENTER<BR></H2></U>"  >> $EMAILMESSAGE

	echo "<H3>SERVICES:<BR></H3>"  >> $EMAILMESSAGE
	echo "<B>host_name;display_name;notifications_enabled;acknowledged;last_time_ok<BR></B>" >> $EMAILMESSAGE
	echo -e "GET services\nFilter: notifications_enabled = 0\nFilter: acknowledged = 1\nOr: 2\nColumns: host_name display_name notifications_enabled acknowledged last_time_ok\n" | nc monitoring.$i.reachlocal.com 6557 | sort | awk -F';' 'BEGIN {FS=OFS=";"}{$5=strftime("%D",$5)} {print}' | sed 's/12\/31\/69/NEVER/g' | sed ':a;N;$!ba;s/\n/<BR>/g' >> $EMAILMESSAGE

	echo "<BR>" >> $EMAILMESSAGE
	echo "<H3>HOSTS:<BR></H3>"  >> $EMAILMESSAGE
	echo "<B>host_name;display_name;notifications_enabled;acknowledged;last_time_ok<BR></B>" >> $EMAILMESSAGE
	echo -e "GET hosts\nFilter: notifications_enabled = 0\nFilter: acknowledged = 1\nOr: 2\nColumns: host_name display_name notifications_enabled acknowledged last_time_ok\n" | nc monitoring.$i.reachlocal.com 6557 | sort | awk -F';' 'BEGIN {FS=OFS=";"}{$5=strftime("%D",$5)} {print}' | sed 's/12\/31\/69/NEVER/g' | sed ':a;N;$!ba;s/\n/<BR>/g' >> $EMAILMESSAGE 

	echo "<BR>" >> $EMAILMESSAGE
done

echo "<H3>SERVICES:<BR></H3>"  >> $EMAILMESSAGE
echo "<B>host_name;display_name;notifications_enabled;acknowledged;last_time_ok<BR></B>" >> $EMAILMESSAGE
echo -e "GET services\nFilter: notifications_enabled = 0\nFilter: acknowledged = 1\nOr: 2\nColumns: host_name display_name notifications_enabled acknowledged last_time_ok\n" | nc monitoring.wh.reachlocal.com 6557 | sort | awk -F';' 'BEGIN {FS=OFS=";"}{$5=strftime("%D",$5)} {print}' | sed 's/12\/31\/69/NEVER/g' | sed ':a;N;$!ba;s/\n/<BR>/g' >> $EMAILMESSAGE

echo "<BR>" >> $EMAILMESSAGE
echo "<H3>HOSTS:<BR></H3>"  >> $EMAILMESSAGE
echo "<B>host_name;display_name;notifications_enabled;acknowledged;last_time_ok<BR></B>" >> $EMAILMESSAGE
echo -e "GET hosts\nFilter: notifications_enabled = 0\nFilter: acknowledged = 1\nOr: 2\nColumns: host_name display_name notifications_enabled acknowledged last_time_ok\n" | nc monitoring.wh.reachlocal.com 6557 | sort | awk -F';' 'BEGIN {FS=OFS=";"}{$5=strftime("%D",$5)} {print}' | sed 's/12\/31\/69/NEVER/g' | sed ':a;N;$!ba;s/\n/<BR>/g' >> $EMAILMESSAGE

echo "<BR>" >>$EMAILMESSAGE

echo "</BODY></HTML>" >> $EMAILMESSAGE

cat $EMAILMESSAGE | /usr/sbin/sendmail -t

#rm -f $EMAILMESSAGE 

