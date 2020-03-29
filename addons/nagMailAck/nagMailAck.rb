#!/usr/bin/env ruby
#####################################################################
#AiM: ACK Nagios Notification by Forwarding Notification Mail to
#	Nagios' PrivateGMail A/C with Custom Tweaked Subject
#
#####################################################################
##############################START-SCRIPT##############################
require 'net/imap'

hostname=Socket.gethostname
hostname=hostname.slice(0..hostname.index(".reachlocal.com"))
hostname=hostname.slice((hostname.index(".")+1)..-2)
uname=hostname + "ack@reachlocal.com"

# Change this - this is the auth string checked to validate the ACK

#nagID = 'STFU!'

# Change username and password for imap mailbox
CONFIG = {
  :host     => 'imap.gmail.com',
  :username => uname,
  :password => 'STFU!Pleez',
  :port     => 993,
  :ssl      => true
}

#####################################################################
###############################ACK-METHOD##############################
def nagiosACK(eMailSubject,fromuser,body)
    #machineID = machineString
    subject = eMailSubject
    from = fromuser
    ackmsg = body
    #printMsg="echo 'Subject: " + subject + "' >> /var/log/nagAck.log"
    #system(printMsg)

    # Verify that this is the path to nagios.cmd
    @commandFile = '/usr/local/nagios/var/rw/nagios.cmd'

    # Break up the subject into space-delimited tokens for HOST alerts
    @subjectTokens =subject.split(/\s/)


    #if @subjectTokens[0]!=machineID
    #  system('echo "@Error: eMail Subject has Wrong Machine ID" >> /var/log/nagAck.log')
    #  return false
    #end

    #composing acknowledgement string for nagios.cmd
    if subject.index("Host") != nil 
      #in above kind of SUBJECT Line, default HOST info is 6th Word, so
      hostNfo = @subjectTokens[5]
      #preparing host acknowledgement string
      @ackCmd="ACKNOWLEDGE_HOST_PROBLEM;"+hostNfo+";1;1;1;"+from+";ack by email - "+ackmsg
      #confirmation output  
      printMsg = from+" acknowledged the host notification of " + hostNfo + "\n" 
      printMsg = 'echo "' + printMsg + '" >> /var/log/nagAck.log'
      system(printMsg)
    elsif  subject.index("Service") != nil 
      #in above kind of SUBJECT Line, default HOST/SERVICE info is 8th Word, so
      #hostNfo=@subjectTokens[7].split(/\//)[0]
      #svcNfo=@subjectTokens[7].split(/\//)[1]  
      
      hostNfo = eMailSubject
      hostNfo = hostNfo.slice(hostNfo.index("Alert: ")..-1)
      hostNfo = hostNfo.slice(0..hostNfo.index("/"))
      hostNfo = hostNfo.gsub("Alert: ", "")
      hostNfo = hostNfo.gsub("/", "")

      svcNfo = eMailSubject
      svcNfo = svcNfo.slice(svcNfo.index("/")..-1)
      svcNfo.slice!(0)
      svcNfo = svcNfo.slice(0..svcNfo.index(" is "))
      svcNfo = svcNfo.slice(0..-2)      

      #preparing service acknowledgement string
      @ackCmd = "ACKNOWLEDGE_SVC_PROBLEM;"+hostNfo+";"+svcNfo+";1;1;1;"+from+";ack by email - "+ackmsg
      #confirmation output
      printMsg = from+" acknowledged the service notification of " + svcNfo + " on " + hostNfo + "\n"
      printMsg = 'echo "' + printMsg + '" >> /var/log/nagAck.log'
      system(printMsg)
    end

	now= Time.now.strftime("%D %T")
	runCmd="echo '[%lu] " + @ackCmd + "' " + now + " > " + @commandFile
	testruncmd = 'echo "' + runCmd + '" >> /var/log/nagAck.log'
	system(testruncmd)

#puts runCmd 
	result = %x[#{runCmd}]
	system('echo ' + result + '>> /var/log/nagAck.log')
#puts "over"
    #system('echo>> /var/log/nagAck.log')
    #system('echo>> /var/log/nagAck.log')
    return true
end    
###############################################
=begin
Example MAIL-SUBJECT for Host Level ACK
  NAG-SERVER-ID ack Fwd: ** PROBLEM Host Alert: HOST-NAME is DOWN **
Example MAIL-SUBJECT for Service Level ACK
  NAG-SERVER-ID ack Fwd: ** PROBLEM Service Alert: HOST-NAME/SERVICE-NAME is CRITICAL **
=end





#####################################################################
################################MAIN-PART##############################

#puts "Prefix all acknowledgement mails with '" + nagID + " ack ' with both spaces"
#puts "Eg: '"+nagID+" ack Fwd: ** PROBLEM Host Alert testBox is DOWN **'"

## starting infinite loop
loop do

time = Time.new

$imap = Net::IMAP.new( CONFIG[:host], CONFIG[:port], CONFIG[:ssl] )
$imap.login( CONFIG[:username], CONFIG[:password] )
printMsg = 'echo "**logged in ' + CONFIG[:username] + ' at ' + time.inspect + '**" >> /var/log/nagAck.log'
system(printMsg)

# select the INBOX as the mailbox to work on
$imap.select('INBOX')

messages_to_archive = []
@mailbox = "-1"

# retrieve all messages in the INBOX that
# are not marked as DELETED (archived in Gmail-speak)
$imap.search(["NOT", "DELETED"]).each do |message_id|
  # the mailbox the message was sent to
  # addresses take the form of {mailbox}@{host}
  @mailbox = $imap.fetch(message_id, 'ENVELOPE')[0].attr['ENVELOPE'].to[0].mailbox
  mailboxRejected = "Rejected"
  # give us a prettier mailbox name -
  # this is the label we'll apply to the message
  @mailbox = @mailbox.gsub(/([_\-\.])+/, ' ').downcase
  @mailbox.gsub!(/\b([a-z])/) { $1.capitalize }  
  
  envelope = $imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
#  msg = $imap.fetch(message_id, "BODY[1]")[0].attr["BODY[1]"].split(/\r?\n/)[3] 
  msg = $imap.fetch(message_id,"BODY[1]")[0].attr["BODY[1]"]
  if ( msg.split(/\r?\n/)[3] )
    msg = msg.split(/\r?\n/)[3]
  end

  if msg.length > 255
    msg = msg[0...255]
  end
  system("echo 'ackFrom: #{envelope.from[0].mailbox}' >> /var/log/nagAck.log")
  system("echo 'Subject: #{envelope.subject}' >> /var/log/nagAck.log")
  system("echo 'ackMsg: #{msg}' >> /var/log/nagAck.log")

  # If you want to restrict the ability to ACK from the from address, uncomment this and add the short-name of the mailbox
  #if envelope.from[0].mailbox==="brian.kohler" 

  if !$imap.fetch(message_id, "BODY[1]")[0].attr["BODY[1]"].downcase.include?('ack')
    system("echo 'ERROR: Must include 'ACK' in body.  Will not ack!' >> /var/log/nagAck.log")
    messages_to_archive << message_id
    begin
       #create the ACK subfolder, unless it already exists
       $imap.create(mailboxRejected) unless $imap.list('', mailboxRejected)
       rescue Net::IMAP::NoResponseError => error
    end
    #copy the message to the proper mailbox/label
    $imap.copy(message_id, mailboxRejected)
  else
    if nagiosACK(envelope.subject,envelope.from[0].mailbox,msg)
      messages_to_archive << message_id
      system('echo "nagiosACK executed" >> /var/log/nagAck.log')
      begin
         #create the ACK subfolder, unless it already exists
         $imap.create(@mailbox) unless $imap.list('', @mailbox)
         rescue Net::IMAP::NoResponseError => error
      end
      #copy the message to the proper mailbox/label
      $imap.copy(message_id, @mailbox)
    end
  end
  #end
  #messages_to_archive << message_id
end

# archive the original messages
$imap.store(messages_to_archive, "+FLAGS", [:Deleted]) unless messages_to_archive.empty?

$imap.logout
system('echo "**************************logged out*****************************" >> /var/log/nagAck.log')
#exit(0)
# Add the time between IMAP checks here
sleep(300) #5min [time_in_sec]
##ending external loop
end
#######################################################################
##############################END-SCRIPT###############################
