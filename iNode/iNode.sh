declare -i cnt
declare -i dcnt
declare -i bcnt
declare -i tl
declare -i bl
declare -i bc
declare -i bt
declare -i DTYPE

#---------------------------------------
#--------READ CONFIGURATION FILE--------
#---------------------------------------
if test -f ./iNode.sh ; then
	  . ./iNode.conf
fi

#---------------------------------------
#-------------READ BTH RAW--------------
#---------------------------------------
if [[ $1 == "parse" ]]; then
	packet=""
  	capturing=""
  	count=0
	GT_TEMP = 0
	LT_TEMP = 0
	GT_HUMI = 0
	LT_HUMI = 0


	while read line
  	do
    	count=$[count + 1]
    	if [ "$capturing" ]; then
    		if [[ $line =~ ^[0-9a-fA-F]{2}\ [0-9a-fA-F] ]]; then
        		packet="$packet $line"
      		else
				#echo RAW: $packet
				cnt=0
				dcnt=0
				bl=0
				bt=0
        		bc=0
				np=""
				mp=""
				DTYPE=0
        		for i in $packet; do
            		if [[ "$cnt" -eq "13" ]]; then
	      				tl=`echo "ibase=16; $i"|bc`
	      				#echo TL $tl
            		fi
            		if [[ "$cnt" -gt "13" ]]; then
	      				np+=$i
	      				if [[ "$bl" -eq "0" ]]; then
							if [[ "$DTYPE" -eq "155" ]]; then # 155 -> iNode HT
	            				MAC=`echo $packet | awk '{print $13$12$11$10$9$8}'`
	            				echo $mp
		       					#---------------------------------------
		       					#------------READ TEMPERATURE-----------
		       					#---------------------------------------
		       					HEX=`echo $mp | awk '{print $12$11}'`
		       					DEC=`echo "ibase=16; $HEX"|bc`
		       					TEMPERATURE=`echo $DEC 175.72 4 65536 46.85 | awk '{ printf "%.2f\n", ($1*$2*$3/$4-$5)}'`
		       
		       					if (( $(echo  "$TEMPERATURE < -30" |bc -l) )); then
			      					TEMPERATURE=-30
		       					fi

		       					if (( $(echo "$TEMPERATURE > 70" | bc -l) )); then
			    					TEMPERATURE=70
		       					fi

		      					#---------------------------------------
		       					#-------------READ HUMIDITY-------------
		       					#---------------------------------------
		       					HEX=`echo $mp | awk '{print $14$13}'`     
		       					DEC=`echo "ibase=16; $HEX"|bc`
		       					HUMIDITY=`echo $DEC 125 4 65536 6 | awk '{ printf "%.2f\n", ($1*$2*$3/$4-$5)}'`
		       
		       					if (( $(echo "$HUMIDITY < 1" | bc -l) )); then
			       					HUMIDITY=1
		       					fi

		       					if (( $(echo "$HUMIDITY > 100" |bc -l) )); then
			       					HUMIDITY=100
		       					fi
								#print na ekranie
		       					echo MAC: $MAC TEMPERATURE: $TEMPERATURE C HUMIDITY: $HUMIDITY % | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
		       
		       					#---------------------------------------
		       					#----------SEND MQTT MESSAGES-----------
		       					#---------------------------------------
		       					if [ "$MAC" == "$INODE1_MAC" ]; then
									
									if [[ "$count" -lt "10000" ]]; then
			    						mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE1_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d
										echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE1_TOPIC_TEMPERATURE $TEMPERATURE | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
			    						mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE1_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d     
			    						echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE1_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
										INODE1T=$TEMPERATURE
			    						INODE1H=$HUMIDITY								
									
									else									
										GT_TEMP=`echo $INODE1T 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
										LT_TEMP=`echo $INODE1T 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
										GT_HUMI=`echo $INODE1H 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
									 	LT_HUMI=`echo $INODE1H 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
					
		       							if (( $(echo "$TEMPERATURE < $GT_TEMP" |bc -l) )) && (( $(echo "$TEMPERATURE > $LT_TEMP" |bc -l) )) && (( $(echo "$HUMIDITY < $GT_HUMI" |bc -l) )) && (( $(echo "$HUMIDITY > $LT_HUMI" |bc -l) )); then
			       							mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE1_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d
											echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE1_TOPIC_TEMPERATURE $TEMPERATURE | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
			    							mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE1_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE	-d	     
			    							echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE1_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
											INODE1T=$TEMPERATURE
			    							INODE1H=$HUMIDITY
		       							fi
									fi
		       					fi

								if [ "$MAC" == "$INODE2_MAC" ]; then	

									if [[ "$count" -lt "10000" ]]; then
			    						mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE2_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d
										echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE2_TOPIC_TEMPERATURE $TEMPERATURE | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
			    						mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE2_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE	-d	     
			    						echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE2_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
										INODE2T=$TEMPERATURE
			    						INODE2H=$HUMIDITY								
									
									else									
										GT_TEMP=`echo $INODE2T 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
										LT_TEMP=`echo $INODE2T 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
										GT_HUMI=`echo $INODE2H 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
									 	LT_HUMI=`echo $INODE2H 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
					
		       							if (( $(echo "$TEMPERATURE < $GT_TEMP" |bc -l) )) && (( $(echo "$TEMPERATURE > $LT_TEMP" |bc -l) )) && (( $(echo "$HUMIDITY < $GT_HUMI" |bc -l) )) && (( $(echo "$HUMIDITY > $LT_HUMI" |bc -l) )); then
			       							mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE2_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d
											echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE2_TOPIC_TEMPERATURE $TEMPERATURE | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
			    							mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE2_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d	     
			    							echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE2_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
											INODE2T=$TEMPERATURE
			    							INODE2H=$HUMIDITY
		       							fi
									fi
								fi
		       				

								if [ "$MAC" == "$INODE3_MAC" ]; then

									if [[ "$count" -lt "10000" ]]; then
			    						mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE3_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d
										echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE3_TOPIC_TEMPERATURE $TEMPERATURE | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
			    						mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE3_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d	     
			    						echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE3_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
										INODE3T=$TEMPERATURE
			    						INODE3H=$HUMIDITY								
									
									else									
										GT_TEMP=`echo $INODE3T 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
										LT_TEMP=`echo $INODE3T 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
										GT_HUMI=`echo $INODE3H 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
									 	LT_HUMI=`echo $INODE3H 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
					
		       							if (( $(echo "$TEMPERATURE < $GT_TEMP" |bc -l) )) && (( $(echo "$TEMPERATURE > $LT_TEMP" |bc -l) )) && (( $(echo "$HUMIDITY < $GT_HUMI" |bc -l) )) && (( $(echo "$HUMIDITY > $LT_HUMI" |bc -l) )); then
			       							mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE3_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d
											echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE3_TOPIC_TEMPERATURE $TEMPERATURE | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
			    							mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE3_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE -d	     
			    							echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE3_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
											INODE3T=$TEMPERATURE
			    							INODE3H=$HUMIDITY
		       							fi
									fi
		       					fi

								##Uncomment and modify those lines to add new iNode/Mosquitto client
								# if [ "$MAC" == "$INODE4_MAC" ]; then
								# 	if [[ "$count" -lt "10000" ]]; then
			    				# 		mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE4_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE
								#		echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE4_TOPIC_TEMPERATURE $TEMPERATURE | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
			    				# 		mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE4_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE	     
			    				# 		echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE4_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
								# 		INODE4T=$TEMPERATURE
			    				# 		INODE4H=$HUMIDITY								
									
								# 	else									
								# 		GT_TEMP=`echo $INODE4T 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
								# 		LT_TEMP=`echo $INODE4T 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
								# 		GT_HUMI=`echo $INODE4H 5 | awk '{ printf "%.2f\n", ($1+$2)}'`
								# 	 	LT_HUMI=`echo $INODE4H 5 | awk '{ printf "%.2f\n", ($1-$2)}'`
					
		       					# 		if (( $(echo "$TEMPERATURE < $GT_TEMP" |bc -l) )) && (( $(echo "$TEMPERATURE > $LT_TEMP" |bc -l) )) && (( $(echo "$HUMIDITY < $GT_HUMI" |bc -l) )) && (( $(echo "$HUMIDITY > $LT_HUMI" |bc -l) )); then
			       				# 			mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE4_TOPIC_TEMPERATURE -m $TEMPERATURE -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE
			    				# 			mosquitto_pub  -h $MQTT_BROKER_IP -p $MQTT_BROKER_PORT  -t $INODE4_TOPIC_HUMIDITY -m $HUMIDITY -u $MQTT_BROKER_LOGIN -P $MQTT_BROKER_PASSWORD --cafile $CA_FILE	     
			    				# 			echo MOSQUITTO_PUB: $MQTT_BROKER_IP $MQTT_BROKER_PORT  $INODE4_TOPIC_HUMIDITY $HUMIDITY | awk -v data="$(date +"%Y-%m-%d %H:%M:%S")" '{print data, $0; fflush();}'
								# 			INODE4T=$TEMPERATURE
			    				# 			INODE4H=$HUMIDITY
		       					# 		fi
								# 	fi
		       					# fi


		       					DTYPE=0
	        				fi

							if [[ "$dcnt" -lt "$tl" ]]; then
								bl=`echo "ibase=16; $i"|bc`
	    						bcnt=0
								#echo BL $bl
  		  						mp=$i" "
        					fi
	   						else
							if [[ "$bcnt" -eq "0" ]]; then
								bc=`echo "ibase=16; $i"|bc`
								#echo BC $bc
							fi
							if [[ "$bc" -eq "255" ]]; then
	    						if [[ "$bcnt" -eq "2" ]]; then
		    						DTYPE=`echo "ibase=16; $i"|bc`
		    						#echo DTYPE $DTYPE
								fi
							fi
							bcnt=$bcnt+1
							bl=$bl-1
							mp+=$i" "
	    				fi
	    				dcnt=$dcnt+1
        			fi
	    			cnt=$cnt+1
				done

        		capturing=""
        		packet=""
			fi
    	fi
    	if [ ! "$capturing" ]; then
      		if [[ $line =~ ^\> ]]; then
        		packet=`echo $line | sed 's/^>.\(.*$\)/\1/'`
        		capturing=1
    		fi
    	fi
	done else
	hcitool lescan --duplicates --passive 1>/dev/null &
	if [ "$(pidof hcitool)" ]; then
		#tutaj było ./$0! ale przez to nie mozna wywolac gdziekolwiek
    	hcidump --raw | $0 parse $1
	fi
fi
