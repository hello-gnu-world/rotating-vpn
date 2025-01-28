#!/bin/bash

#Checks if running with root or sudo privileges
if [ "$(whoami)" != 'root' ];
then
	echo "Script must be run with sudo! Exitting.";
	exit;
fi
#Defines one time random configuration
once='false'
#Defines array that will hold the wireguard country configuration files
countries=();
#Defines the variable that holds the directory of the wireguard country configuration files
country_dir='';
#Defines the variable that holds the directory of the current wireguard configuration file
wireguard_dir="";
#Defines the variable that holds the name of the current wireguard configuration file
wireguard_name='';
#Defines the variable that holds the duration of the current wireguard configuration file 
minutes='';


#Defines function for checking the existence of a directory
dir_check(){
if [ ! -d "$1" ];
then
	echo "$1 does not exist! Exitting."
	exit;
fi
}

dir_create(){
mkdir "$1";
}
while getopts 'm:c:n:d:oh' OPTION; do
	case "$OPTION" in
		m)
			#Grabs value from command line argument and assigns it to the minute variable
			minutes="$OPTARG";
			;;
		c)
			#Grabs value from command line argument and assigns it to the country_dir variable
			country_dir="$OPTARG";
			dir_check "$country_dir";
			#Removes any trailing forward slash from directory path
			if [ "$(echo "$country_dir" | rev | cut -b1)" == '/' ];
			then
				country_dir="$(echo "$country_dir" | rev | cut -b2- | rev)";
				echo "$country_dir";
			fi
			;;
		n)
			#Grabs value from command line argument and assigns it to the wireguard_name variable
			wireguard_name="$OPTARG";
			#Sanatizes user input to remove everything except underscores, numbers and letters
			wireguard_name=${wireguard_name// /_}; wireguard_name=${wireguard_name//[^a-zA-Z0-9_]/}; 
			;;
		d)
			#Grabs value from command line argument and assigns it to the wireguard_dir variable	
			wireguard_dir="$OPTARG";
			#Checks the existence of "wireguard_dir" variable
			dir_check "$wireguard_dir";
			#Removes any trailing forward slash from directory path
			if [ "$(echo "$wireguard_dir" | rev | cut -b1)" == '/' ];
			then
				wireguard_dir="$(echo "$wireguard_dir" | rev | cut -b2- | rev)";
			fi
			;;
		o)
			once='true';
			;;
		h)
			#Displays help information about different command line arguments
			echo -e "Flags:\n-m | minutes between a country change\n-c | directory name of country directories which hold wireguard configuration files\n-n name of wireguard configuration file name\n-d | directory holding all wireguard configuration files";
			exit;
			;;
		*)
			#Directs user to "help" command line argument
			echo "Use -h for flag information."
			exit;
			;;
	esac
done

#Defines main function
main(){
	#Sets wireguard_dir variable if empty
	if [ "$wireguard_dir" == ''  ];
	then
		dir_create '/etc/wireguard';
		wireguard_dir='/etc/wireguard';
	fi

	#Sets country_dir variable if empty
	if [ "$country_dir" == ''  ];
	then
		dir_create "$wireguard_dir/countries";
		country_dir="$wireguard_dir/countries";	
	fi

	#Sets wireguard_name variable if empty
	if [ "$wireguard_name" == ''  ];
	then
		wireguard_name='wg0';
	fi

	#Sets minutes variable if empty
	if [ "$minutes" == ''  ];
	then
		minutes='5';
	fi

	#Checks the existence of "country_dir" variable
	dir_check "$country_dir"
	#Defines ammount of configuration files in "country_dir" variable
	country_count="$(find "$country_dir" -maxdepth 1 | sort | cut -d'/' -f2  | tail -n +2 | wc -l)";
	#Loops over all wireguard configuration files
	while true
	do	
		#Adds all wireguard country configuration files to an array
		i=1; 
		while [ "$i" -le "$country_count" ]; 
		do 
			countries+=("$(find "$country_dir" -maxdepth 1 | sort | rev | cut -d'/' -f1  | tail -n +2 | head -n"$i" | tail -n1 | rev)");
			i=$((i + 1)); 
		done;
		#Establishes wireguard vpn connection with random configuration file
		i=0; 
		while [ "$i" -lt "$country_count" ]; 
		do 
			#Picks random number between 0 and number of country configuration files minus 1 and adds assugns it to the "index" variable
			index=$(shuf -i 0-$((${#countries[@]} - 1)) -n1 --random-source=/dev/random); 
			#Chooses random country from the index" variable
			country="${countries[$index]}";  
			#Unsets chosen country configuration file to prevent it from being chosen again
			unset "countries[$index]"; 
			temp_countries=("${countries[@]}"); 
			countries=("${temp_countries[@]}");
			i=$((i + 1));
			#Moves chosen country configuration file to wireguard directory
			current_country_dir="$country_dir/$country/";
			current_country_dir_count="$(find "$current_country_dir" -maxdepth 1 | sort | cut -d'/' -f2  | tail -n +2 | wc -l)";
			cp "$current_country_dir$(ls "$current_country_dir" | head -n"$(shuf -i 1-"$current_country_dir_count" -n1 --random-source=/dev/random)" | tail -n1)" "$wireguard_dir/""$wireguard_name.conf";
			echo "systemctl start wg-quick@$wireguard_name";
			if [ "$once" == 'true' ];
			then
				exit;
			fi
			#Puases for "minutes" before continuing to chose another country configuration file
       			sleep "$minutes"m;	
		done;
	done;
}
#Runs main function
main
