#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket::INET;
use Digest::MD5 qw(md5);

# phone definition
my $phoneip = "1.2.3.4";
my $wifipin = "123456";


# all possible commands
use constant {
	PKT_MAGIC => 30537,
	# HM_Application
	CMD_APP_GET_DESCRIPT => 502,
	CMD_APP_GET_HANDLES => 501,
	CMD_APP_GET_ICON => 503,
	CMD_APP_GET_PACKAGE => 504,
	CMD_APP_GET_STATSINFO => 507,
	CMD_APP_INSTALL => 505,
	CMD_APP_UNINSTALL => 506,
	CMD_BEGIN => 500,
	# bookmarks
	CMD_BK_BOOKMARK_GET_ALL => 700,
	CMD_BK_BOOKMARK_UPDATE_ALL => 701,
	# calendar
	CMD_CAL_ADD => 217,
	CMD_CAL_BEGINSESSION => 210,
	CMD_CAL_DELETE => 219,
	CMD_CAL_ENDSESSION => 220,
	CMD_CAL_GETAT => 216,
	CMD_CAL_GETCOUNT => 213,
	CMD_CAL_GETFIRST => 214,
	CMD_CAL_GETNEXT => 215,
	CMD_CAL_GET_ACCOUNTS => 211,
	CMD_CAL_GET_CALENDARS => 212,
	CMD_CAL_MODIFY => 218,
	# contacts
	CMD_PBK_ADD => 114,
	CMD_PBK_BEGINSESSION => 100,
	CMD_PBK_DELETE => 116,
	CMD_PBK_ENDSESSION => 199,
	CMD_PBK_GETAT => 113,
	CMD_PBK_GETCOUNT => 110,
	CMD_PBK_GETFIRST => 111,
	CMD_PBK_GETNEXT => 112,
	CMD_PBK_GET_ACCOUNTS => 101,
	CMD_PBK_GET_GROUPS => 102,
	CMD_PBK_MODIFY => 115,
	# device 
	CMD_GET_BATTERY => 1,
	CMD_GET_DERESETTIME => 8,
	CMD_GET_DEVINFO => 0,
	CMD_GET_DEVINFO_EX => 7,
	CMD_GET_SIGNAL => 2,
	CMD_SET_DERESETTIME => 9,
	CMD_AUTH_PHASE => 6,
	# file access
	CMD_DELETE => 403,
	CMD_GET_DIR => 400,
	CMD_GET_FILE => 401,
	CMD_GET_PATH => 406,
	CMD_GET_PATH_STATE => 407,
	CMD_GET_STATE => 405,
	CMD_MAKE_DIR => 404,
	CMD_PUT_FILE => 402,
	# media access
	CMD_AUDIO_ADD_PLAYLIST => 610,
	CMD_AUDIO_ADD_PLAYLIST_SONG => 611,
	CMD_AUDIO_CLEAR_PLAYLIST => 613,
	CMD_AUDIO_GET_ALBUM_LIST => 606,
	CMD_AUDIO_GET_PLAYLIST_LIST => 607,
	CMD_AUDIO_GET_SONG_INFO => 609,
	CMD_AUDIO_GET_SONG_LIST => 608,
	CMD_AUDIO_RENAME_PLAYLIST => 612,
	CMD_AUDIO_SET_RINGTONE => 614,
	CMD_MEDIA_BEGIN => 600,
	CMD_IMAGE_GET_BUCKET_LIST => 601,
	CMD_IMAGE_GET_BUCKET_MEDIA => 602,
	CMD_MEDIA_DELETE => 605,
	CMD_MEDIA_GET_FILE => 603,
	CMD_MEDIA_PUT_FILE => 604,
	CMD_MIDIA_GET_DEFPATH => 615,
	CMD_MIDIA_GET_STATSINFO => 616,
	# sms
	CMD_SMS_BEGINSESSION => 300,
	CMD_SMS_DELETE => 305,
	CMD_SMS_ENDSESSION => 399,
	CMD_SMS_GETCOUNT => 301,
	CMD_SMS_GETNEXT => 306,
	CMD_SMS_SAVE => 304,
	CMD_SMS_SEND => 303,
	CMD_SMS_SET_READ => 307,
};

sub send_recv_packet(@){
	my($socket, $cmd, $status, $flags, $string) = @_;
	my $ret_cmd = 0; my $ret_status = 0; my $ret_flags = 0; my $ret_length = 0; my $ret_magic = 0;
	my $tmpdata = ''; my $ret_data ='';
	my $data=pack("n",PKT_MAGIC).pack("n",$cmd).pack('c',$status).pack('c',$flags).pack("N",length($string)).$string;
	# print "Sending data:\n";hdump($data);
	$socket->send($data);
	my $finish=0;
	my $readlen=0;
	$data=''; 
	
	# when device is busy response is devided to many packets, we need to read them all
	while($finish==0) {
		$socket->recv($tmpdata, 1024);
		$finish = 1 if length($tmpdata) == 0;
		$data.=$tmpdata;
		$readlen+=length($tmpdata);
		if($readlen >= 10) { # read header
			($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length)=unpack('n[2]ccN',$data);
			$finish = 1 if ($ret_length+10) == $readlen; # finish if packet is read
		}
	}
	# print "Got reply:\n"; hdump($data);
	
	if( length($data) >= 10) {
		$ret_cmd = $ret_cmd ^ 0x8000;
		if($ret_length) {
			$ret_data=unpack("x[12]a[$ret_length]",$data);
		}
	}
	else {
		$ret_magic=-1;
	}
	return($ret_magic, $ret_cmd, $ret_status, $ret_flags, $ret_length, $ret_data)
}


# flush after every write
$| = 1;

my ($socket,$client_socket);

# creating object interface of IO::Socket::INET modules which internally creates
# socket, binds and connects to the TCP server running on the specific port.
$socket = new IO::Socket::INET (
	PeerHost => $phoneip,
	PeerPort => '7749',
	Proto => 'tcp',
	) or die "ERROR in Socket Creation : $!\n";

print "TCP Connection Success.\n";

print "logging in...\n";
my ($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length, $ret_data) = 
	send_recv_packet($socket, CMD_AUTH_PHASE, 0, 0, md5($wifipin));

if ($ret_magic!=PKT_MAGIC || $ret_status != 0) {
	print "Error: Login failed\n";
	exit 1;
}
print "Sending information packet...\n";
($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length, $ret_data) = 
	send_recv_packet($socket, CMD_GET_DEVINFO_EX, 0, 0, '');
if($ret_length) {
	my $offset=0;
	for(my $i=0;$i<13;$i++) {
		$offset=decode_id($ret_data, $offset); # mBrandName
	}
}
if ($ret_magic!=PKT_MAGIC || $ret_status != 0) {
	print "Error: failed\n";
	exit 1;
}

print "Contact Accounts:\n";
($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length, $ret_data) = 
	send_recv_packet($socket, CMD_PBK_BEGINSESSION, 0, 0,'     ');

if ($ret_magic!=PKT_MAGIC || $ret_status != 0) {
	print "Error: Contacts failed\n";
	exit 1;
}

($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length, $ret_data) = 
	send_recv_packet($socket, CMD_PBK_GET_ACCOUNTS, 0, 0, '');
if ($ret_magic!=PKT_MAGIC || $ret_status != 0) {
	print "Error: Contacts failed\n";
	exit 1;
}
decode_contact_accounts($ret_data);

# getting first contact
($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length, $ret_data) = 
	send_recv_packet($socket, CMD_PBK_GETFIRST, 0, 0, '');
decode_contact($ret_data) if (!$ret_status);
until($ret_status){
	($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length, $ret_data) = 
		send_recv_packet($socket, CMD_PBK_GETNEXT, 0, 0, '');
	decode_contact($ret_data) if (!$ret_status);
}

($ret_magic,$ret_cmd,$ret_status,$ret_flags,$ret_length, $ret_data) = 
	send_recv_packet($socket, CMD_PBK_ENDSESSION, 0, 0, '');
if ($ret_magic!=PKT_MAGIC || $ret_status != 0) {
	print "Error: Contacts failed\n";
	exit 1;
}
$socket->close();


sub decode_contact_accounts {
	my($data) = @_;
	my $offset=0;
	# hdump($data);
	# $listsize=unpack('n',$data);
	while($offset < length($data)) {
		my($id,$nameLen)=unpack("x[$offset]Nn",$data);
		$offset+=6;
		my $name=unpack("x[$offset]a[$nameLen]",$data);
		$offset+=$nameLen;
		$nameLen=unpack("x[$offset]n",$data);
		$offset+=2;
		my $type=unpack("x[$offset]a[$nameLen]",$data);
		$offset+=$nameLen;
		printf ("  id: %X, name: '%s', type: '%s'\n", $id, $name, $type);
	}
}

sub decode_id {
	my @tags;
	$tags[272]="TAG_AGENT_CID";
	$tags[274]="TAG_AGENT_VERCODE";
	$tags[273]="TAG_AGENT_VERNAME";
	$tags[256]="TAG_DEVICE_BRAND";
	$tags[261]="TAG_DEVICE_BUILDNUM";
	$tags[260]="TAG_DEVICE_DID";
	$tags[259]="TAG_DEVICE_IDESIGN";
	$tags[265]="TAG_DEVICE_KERNEL_VERNAME";
	$tags[257]="TAG_DEVICE_MANFR";
	$tags[258]="TAG_DEVICE_MODEL";
	$tags[263]="TAG_DEVICE_OS_VERCODE";
	$tags[262]="TAG_DEVICE_OS_VERNAME";
	$tags[264]="TAG_DEVICE_RADIO_VERNAME";
	my($data, $offset) = @_;
	my $text='';
	my $code=unpack("x[$offset]n",$data);
	my $length=unpack("x[".($offset+2)."]n",$data);
	if($code == 272 || $code == 274 || $code == 263) {
		$text=unpack("x[".($offset+4)."]N",$data);
	}
	else {
		
		$text=unpack("x[".($offset+4)."]a[$length]",$data);
		$text =~ s/\n/ /g;
	}
	printf("  %-30s %s\n", $tags[$code],$text);
	return $offset+$length+4;
}

sub decode_contact {
	my($data) = @_;
	# read record id
	my $id=unpack('N',$data);
	print "contact: id=$id\n";
	my $offset = 4;
	while ($offset > 0) {
		$offset=decode_contact_item($data,$offset);
	}
	# saving contacts
	open(CONTACT, "> contacts/${id}.bin")
	    or die "Couldn't open contacts/${id} for writing: $!\n";
	print CONTACT $data;
	close(CONTACT);
	# hdump($data);
}

sub decode_contact_item {
	# there are 2 different models - for strings and for array of bytes.
	# array of bytes:
	# 3332 - mOwnerAccount.mId;
	# 3333 - this.mId (group related??)
	# 65104 - photo
	#
	# strings
	# 1802   AggregateName
	# 3334   LookupKey
	# 65120  Ringtone
	# 65089  FLAG_SEND_TO_VOICEMAIL 
	# 1808   FLAG_FAVORITE_STARTED 
	# vnd.android.cursor.item/email_v2 { 2055, 2048, 2052, 2053, 2054 };
	# vnd.android.cursor.item/contact_event" { 1828, 1826, 1827, 1824 }
	# vnd.android.cursor.item/im" { 3087, 3072, 3073, 3074, 3075, 3076, 3077, 3078, 3079, 3080 } 
	# vnd.android.cursor.item/name" { 1792 }, { 1793 }, { 1794 }, { 1798 }, { 1799 }, { 1800 }, { 8193 }, { 8213 }, { 8194 }
	# vnd.android.cursor.item/nickname { 1795, 1795, 1795, 1795, 1795, 1795 }
	# vnd.android.cursor.item/note { 2560 }
	# vnd.android.cursor.item/organization { 65046, 65040, 65043 }, { 65047, 65041, 65044 }, { 65048, 65042, 65045 }
	# vnd.android.cursor.item/phone_v2 { 2841, 2818, 2819, 2822, 2820, 2830, 2827, 2826, 2842, 2843, 2844, 2845, 2846, 2831, 2847, 2848, 2849, 2829, 2837, 2850, 2851 }
	# vnd.android.cursor.item/website { 65063, 65056, 65060, 65061, 65057, 65058, 65062, 65059 }
	# 
	my($data,$offset) = @_;
	my $length = 0;
	my($paramL,$code) = unpack("x[$offset]Nn", $data);
	$offset+=6;
	my @bytearrays = (3332, 3333, 65104); # all packets with "bytearray" structure
	print "  code=$code ";
	if (grep {$_ == $code} @bytearrays) {
		($length) = unpack("x[$offset]N", $data);
		$offset+=4;
		# XXX read content
		$offset+=$length;
		print "byte array, length=$length\n";
	}
	else {
		my $paramI2;
		($paramI2, $length) = unpack("x[$offset]nn", $data);
		$offset+=4;
		## XXX read content
		$offset+=$length;
		print "string array, length: $length\n";
	}
	$offset = -1 if $offset>=length($data);
	return $offset;
	# hdump($data);
}

# for debugging
sub hdump {
	my $offset = 0;
	my(@array,$format);
	foreach my $data (unpack("a16"x(length($_[0])/16)."a*",$_[0])) {
		my($len)=length($data);
		if ($len == 16) {
			@array = unpack('N4', $data);
			$format="0x%08x (%05d)   %08x %08x %08x %08x   %s\n";
		} else {
			@array = unpack('C*', $data);
			$_ = sprintf "%2.2x", $_ for @array;
			push(@array, '  ') while $len++ < 16;
			$format="0x%08x (%05d)" .
				"   %s%s%s%s %s%s%s%s %s%s%s%s %s%s%s%s   %s\n";
			
		} 
		$data =~ tr/\0-\37\177-\377/./;
		printf $format,$offset,$offset,@array,$data;
		$offset += 16;
	}
}
