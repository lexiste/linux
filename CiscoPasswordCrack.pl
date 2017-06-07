#!/usr/bin/perl
#
# script to crack Cisco's Type 7 passwords
#
# usage: perl CiscoPasswordCrack.pl < config-file > config-file-decrypt
#

$k='dsfd;fkoA,.iyewrkldJKDHSUB';

# translate key ($k) into array of hex ($ks)
for ($i=0; $i<length($k); $i++) { 
	$ks[$i] = ord(substr($k, $i, 1)); 
#	printf "key: " . substr($k, $i, 1) . " == $ks[$i]\n";
}

# reading the piped in file...
while (<STDIN>) {
	# looking for a string password 7 with next char either 0 or 1, store the encrypted string in $C
	if(/ord 7 [01]/) {
		chop; $w=$_;
	       	s/.* //g; 
		$C = $_;
		
		# print string then start decrypting
		printf "$w (decrypted: ";

		# first 2 characters are the offset, storing them in $o
		$o=substr($C, 0, 2);
#		printf "\toffset is: $o making key $ks[$o]\n";

		# now that we have offset, walk through 2 char at a time converting to hex storing in $cs[]
		for ($i=0; $i < (length($C)-1)/2; $i++) { 
			$cs[$i]=hex(substr($C,2*$i,2)); 
#			printf "i = $i ";
		}

#		printf "\tlen(C) is " . length($C) . " and i is $i\n";
		# decryption is simply XOR between offset in the key ($o) and converted scrint $cs[]
		for ($j=1; $j < $i; $j++) { 
			printf("%c", $ks[$o+$j-1] ^ $cs[$j]); 
		}
		
		printf ")\n";
	}
#       	else {
#		printf $_;
#	}
}
