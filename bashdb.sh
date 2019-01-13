#!/bin/bash

# DB_TABLE CONSTANTS
declare -r ID=0
declare -r BRAND=1
declare -r MODEL=2
declare -r RAM=3
declare -r STORAGE=4
declare -r OS=5
declare -r SERIAL=6

declare -r TABLE=("ID" "BRAND" "MODEL" "RAM" "STORAGE" "OS" "SN")

# DB_TABLE META CONSTANTS
declare -r NUM_FIELDS=7

# COLORS AND EFFECTS
declare -r BLUE="\033[0;34m"
declare -r YELLOW="\033[0;33m"
declare -r LYELLOW="\033[0;93m"
declare -r LGREEN="\033[0;92m"
declare -r RESET="\033[0;0m"
declare -r BOLD="\033[0;1m"
declare -r DIM="\033[0;2m"
declare -r BLINK="\033[0;5m"
declare -r CYAN="\033[0;36m"

# GLOBAL CONSTANTS
declare -r SEP_CHAR='-'
declare -r BAN_CHAR1='#'
declare -r BAN_CHAR2=' '
declare -r BAN_TEXT="Computer DB V.0"

# Color vars
BT=$BLUE
COM=$YELLOW
EXP=$DIM

# Db env vars
DB_NAME='default.db'

# Buffers
db_buff=()
s_buff=""
i_buff=0
a_buff=()
id_buff=0
err_buff=false

# Flags
menu_mode=0

#PRINT FUNCTIONS

#Print spearator line
function print_separator(){
    
    cols=$(tput cols)
    
    x=0;
    while [[ $x -lt $cols ]]; do 
	echo -n "$SEP_CHAR" 
	(( x++ ))
    done
}

#Print banner
function print_banner(){
    
    #clear screen
    echo `clear`
    
    #Calculate row dimensions
    field1_p=10
    field2_p=40
    text_len=${#BAN_TEXT}
    cols=$(tput cols)
    rem=$(( cols - text_len ))
    field1=$(( (rem * field1_p) / 100 ))
    field2=$(( (rem * field2_p) / 100 ))
    
    #print the banner
    x=0;while [[ $x -lt $cols ]];do echo -n "$BAN_CHAR1";(( x++ ));done 
    x=0;while [[ $x -lt $field1 ]];do echo -n "$BAN_CHAR1";(( x++ ));done
    x=0;while [[ $x -lt $field2 ]];do echo -n "$BAN_CHAR2";(( x++ ));done
    echo -n -e "${BT}$BAN_TEXT${RESET}"
    x=0;while [[ $x -lt $field2 ]];do echo -n "$BAN_CHAR2";(( x++ ));done
    x=0;while [[ $x -lt $field1 ]];do echo -n "$BAN_CHAR1";(( x++ ));done;echo 
    x=0;while [[ $x -lt $cols ]];do echo -n "$BAN_CHAR1";(( x++ ));done;echo 
}

#print database
function print_db(){
    
    echo "name: $DB_NAME"

    print_separator

    counter=0
    for(( i = 0; i < ${#db_buff[@]}; i++ )); do
	if [[ $counter -eq $(( NUM_FIELDS -1 )) ]]; then
	    echo "${TABLE[$counter]}: ${db_buff[$i]}"
	    print_separator
	    counter=0
	else
	    echo "${TABLE[$counter]}: ${db_buff[$i]}"
	    (( counter++ ))
	fi
    done

    read -p "Press Enter to continue."
}

#print entry from database
function print_entry(){
    
    buff_len=${#db_buff[@]}
    num_entries=$(( buff_len / NUM_FIELDS ))

    get_last_id
    if [ $err_buff != false ]; then
	err_buff="get_last_id failed : $err_buff"
    else
	#get input from user
	read -p "Entry ID: " usr_in

	#check if usr_in is out of range
	if [[ $usr_in -lt 0 || $usr_in -gt $i_buff ]]; then
	    err_buff="Entry ID is out of range"
	    echo $err_buff
	else
	    for(( i = 0; i < num_entries; i++ )); do
		
		val=${db_buff[$i * $NUM_FIELDS]}
		
		if [ $val == $usr_in ]; then
		    print_separator
		    for(( j = 0; j < ${#TABLE[@]}; j++ )); do
			echo "${TABLE[$j]}: ${db_buff[$i * $NUM_FIELDS + $j]}"
		    done
		    print_separator
		fi
	    done
	fi
    fi

    read -p "Press Enter to continue."
}

#print quit message
function print_quit_msg(){
    echo "Quiting.."
    echo `clear`
}

#print info bar
function print_info_bar(){
        
    cols=$(tput cols)
    current_db="file: $DB_NAME"

    if [ $menu_mode == 0 ]; then
	menu_head="[SHORT OPTIONS]"
    elif [ $menu_mode == 1 ]; then
	menu_head="[LONG OPTIONS]"
    elif [ $menu_mode == 2 ]; then
	menu_head="[LONG SPLIT]"
    elif [ $menu_mode == 3 ]; then
	menu_head="[SHORT_SPLIT]"
    elif [ $menu_mode == 4 ]; then
	menu_head="[TOGGLE OPTIONS - ${COM}t${RESET}]"
    fi
    
    db_name_field=${#current_db}
    menu_field=${#menu_head}
    empty_field=$(( $cols - $db_name_field - $menu_field ))


    echo -n -e $menu_head
    
    x=0
    while [ $x -lt $empty_field ]; do
	echo -n ' '
	(( x++ ))
    done

    echo $current_db; echo

}

#print menu options
function print_menu(){
    
    print_info_bar

    if [ $menu_mode == 0 ]; then
	echo -e "${COM}o${RESET}        ${EXP}: open file${RESET}"
	echo -e "${COM}new${RESET}      ${EXP}: new entry${RESET}" 
	echo -e "${COM}p${RESET}        ${EXP}: print db${RESET}" 
	echo -e "${COM}pe${RESET}       ${EXP}: print entry${RESET}" 
	echo -e "${COM}del${RESET}      ${EXP}: delete entry${RESET}" 
	echo -e "${COM}s${RESET}        ${EXP}: save workspace${RESET}" 
	echo -e "${COM}l${RESET}        ${EXP}: load from file${RESET}"
	echo -e "${COM}new db${RESET}   ${EXP}: create new database${RESET}"
	echo -e "${COM}c${RESET}        ${EXP}: clear workspace${RESET}"
	echo -e "${COM}t${RESET}        ${EXP}: toggle menu on/off${RESET}"
	echo -e "${COM}q${RESET}        ${EXP}: quit${RESET}"
	echo
    elif [ $menu_mode == 1 ]; then
	echo -e "${COM}open${RESET}          ${EXP}: open file${RESET}"
	echo -e "${COM}new entry${RESET}     ${EXP}: new entry${RESET}" 
	echo -e "${COM}print${RESET}         ${EXP}: print db${RESET}" 
	echo -e "${COM}print entry${RESET}   ${EXP}: print entry${RESET}" 
	echo -e "${COM}delete entry${RESET}  ${EXP}: delete entry${RESET}" 
	echo -e "${COM}save${RESET}          ${EXP}: save workspace${RESET}" 
	echo -e "${COM}load${RESET}          ${EXP}: load from file${RESET}"
	echo -e "${COM}new db${RESET}        ${EXP}: create new database${RESET}"
	echo -e "${COM}clear${RESET}         ${EXP}: clear workspace${RESET}"
	echo -e "${COM}toggle${RESET}        ${EXP}: toggle menu on/off${RESET}"
	echo -e "${COM}quit${RESET}          ${EXP}: quit${RESET}"
	echo
    elif [ $menu_mode == 2 ]; then
	echo -e "${COM}open${RESET}          ${EXP}: open file${RESET}     |  ${COM}new entry${RESET}    ${EXP}: new entry${RESET}" 
	echo -e "${COM}print${RESET}         ${EXP}: print db${RESET}      |  ${COM}print entry${RESET}  ${EXP}: print entry${RESET}" 
	echo -e "${COM}delete entry${RESET}  ${EXP}: delete entry${RESET}  |  ${COM}save${RESET}         ${EXP}: save workspace${RESET}" 
	echo -e "${COM}load${RESET}          ${EXP}: load file${RESET}     |  ${COM}new db${RESET}       ${EXP}: create new database${RESET}"
	echo -e "${COM}clear${RESET}         ${EXP}: clear buffer${RESET}  |  ${COM}toggle${RESET}       ${EXP}: toggle menu on/off${RESET}"
	echo -e "${COM}quit${RESET}          ${EXP}: quit${RESET}          |"
	echo
    elif [ $menu_mode == 3 ]; then
	echo -e "${COM}o${RESET}     ${EXP}: open file${RESET}        |   ${COM}new${RESET}    ${EXP}: new entry${RESET}" 
	echo -e "${COM}p${RESET}     ${EXP}: print db${RESET}         |   ${COM}pe${RESET}     ${EXP}: print entry${RESET}" 
	echo -e "${COM}del${RESET}   ${EXP}: delete entry${RESET}     |   ${COM}s${RESET}      ${EXP}: save workspace${RESET}" 
	echo -e "${COM}l${RESET}     ${EXP}: load from file${RESET}   |   ${COM}new db${RESET} ${EXP}: create new database${RESET}"
	echo -e "${COM}c${RESET}     ${EXP}: clear workspace${RESET}  |   ${COM}t${RESET}      ${EXP}: toggle menu on/off${RESET}"
	echo -e "${COM}q${RESET}     ${EXP}: quit${RESET}             |"
	echo
    elif [ $menu_mode == 4 ]; then
	echo
    fi
}

#I/O FUNCTIONS

#read db from file to buffer
function read_db(){
    
    #msg
    echo "Reading from $DB_NAME"

    #clear buffer
    db_buff=()

    #check if file exists
    if [ ! -f $DB_NAME ]; then
	echo "Database file $DB_NAME not found"
    else
	str=$(<$DB_NAME)
	IFS=';' read -r -a db_buff <<< "$str"

	get_last_id
	id_buff=$(( $i_buff + 1 ))
    fi
    
    if [ $1 == 1 ]; then
	read -p "Workspace loaded."
    fi
}

#write db buffer to file
function write_db(){
    
    if [ -f $DB_NAME ]; then
	rm $DB_NAME
    fi

    for(( i = 0; i < ${#db_buff[@]}; i++ )); do
	echo -n "${db_buff[$i]};" >> $DB_NAME
    done

    echo "Buffer written to file."
    read -p "Press Enter to continue."
}

#DB MANIPULATION FUNCTIONS

#create new entry
#Input: id_buff
function new_entry(){

    #set entry ID
    push_db_buff $id_buff
    (( id_buff++ ))

    #get user input
    echo "Enter information as follows: "
    
    for(( i = 1; i < ${#TABLE[@]}; i++ )); do
	read -p "${TABLE[$i]}: " usr_in
	push_db_buff $usr_in	
    done

    #print_db_buff
    echo "Entry added."
    read -p "Press Enter to continue."
}

#delete an entry
function del_entry(){
    
    read -p "Entry ID: " usr_in

    i_buff=$usr_in
    find_entry

    upp_limit=$(( i_buff + NUM_FIELDS ))
    if [[ $err_buff != false ]]; then
	echo "$err_buff"
    else
	new_buff=()
	counter=0
	(( upp_limit-- ))

	echo "i_buff: $i_buff"
	for(( i = 0; i < ${#db_buff[@]}; i++ )); do
	    if [[ $i -lt $i_buff || $i -gt $upp_limit ]]; then
		if [ $i -gt $upp_limit ]; then
		    if [ $(( $i % $NUM_FIELDS )) == 0 ]; then
			db_buff[$i]=$(( ${db_buff[$i]} - 1 ))
		    fi
		    new_buff[$counter]=${db_buff[$i]}
		    (( counter++ ))
		else
		    new_buff[$counter]=${db_buff[$i]}
		    (( counter++ ))
		fi
	    fi
	done
	
	db_buff=()
	for(( i = 0; i < ${#new_buff[@]}; i++ )); do
	    db_buff[$i]=${new_buff[$i]}
	done
    fi

    echo "Entry $i_buff removed from workspace"
    read -p "Press Enter to continue."
}

#create new database
function new_db(){

    read -p "Are you sure? Creating new database will delete all unsaved data. y/n: " usr_in
    
    case $usr_in in
	y)
	    read -p "Database name: " DB_NAME
	    db_buff=()
	    echo "Database $DB_NAME created"
	    id_buff=0
	    ;;
	n)
	    ;;
	*)
	    echo "Non valid option" ;;
    esac

    read -p "Press Enter to continue."
}


# BUFFER FUNCTIONS

#clear workspace
function clear_db_buff(){
    db_buff=()
    id_buff=0

    read -p "Workspace is empty. Press Enter to continue."
}

#push field to front of db_buff 
function push_db_buff(){
    index=${#db_buff[@]}
    db_buff[$index]=$1
}

#print db_buff
function print_db_buff(){
    
    for (( i = 0; i < ${#db_buff[@]}; i++ )); do
	echo ${db_buff[$i]}
    done
}

#find first index of entry in db_buff
#Input: i_buff, d_buff
#Output: i_buff
function find_entry(){
    
    #check if entry is out of range
    db_buff_len=${#db_buff[@]}
    num_entries=$(( db_buff_len / NUM_FIELDS ))
    (( num_entries-- ))
    if [[ $i_buff > $num_entries ]]; then
	err_buff="index out of range"
    else
	#calculate index
	i_buff=$(( i_buff * NUM_FIELDS ))
	err_buff=false
    fi
}

#Get last id from db_buff
#Output: i_buff, err_buff
function get_last_id(){

    #get db_buff size
    size=${#db_buff[@]}

    if [ $size -lt $NUM_FIELDS ]; then
	err_buff="Buffer is empty or corrupted."
	
    else
	index=$(( size - NUM_FIELDS ))
	i_buff=${db_buff[$index]}
	err_buff=false
    fi
}

#UI FUNCTIONS

#toggles the options menu on/off
function toggle_opt(){
    
    if [ $menu_mode -lt 4 ]; then
	(( menu_mode++ ))
    else
	menu_mode=0
    fi
}


#open file
function open_db(){
    
    echo "[$PWD]"
    ls *.db; echo

    read -p "> " file

    if [ ! -f $file ]; then
	err_buff="> No file named $file."
	read -p "$err_buff"
    else
	DB_NAME=$file
	read_db
	err_buff=false
    fi

}

#Main function
function main(){
    
    #load default database
    read_db

    #run until false
    run=true

    #main loop
    while [ $run == true ]; do
	
	#welcome banner
	print_banner
	
	#print usage
	print_menu

	#take user input
	read -p "> " opt

	#perform action
	case $opt in
	    new | "new entry")
		new_entry ;;

	    p | print)
		print_db ;;

	    q | quit)
		run=false ;;

	    pe | "print entry")
		print_entry ;;

	    del | "delete entry")
		del_entry ;;

	    s | save)
		write_db ;;
	    
	    l | load)
		read_db 1 ;;

	    o | open)
		open_db ;;
	    
	    "new db")
		new_db ;;

	    c | clear)
		clear_db_buff ;;

	    t | toggle)
		toggle_opt ;;
 
	    *)
		read -p "Option $opt does not exist. Press enter to continue" ;;

	esac
    i
    done

    print_quit_msg
}

main

