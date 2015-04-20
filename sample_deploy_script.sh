echo "starting shell script......"
echo $JAVA_HOME
FILE_NAME=appm_startup.properties
trim()
{
    trimmed=$1
    trimmed=${trimmed%%}
    trimmed=${trimmed##}
}

getProperty(){
       	prop_key=$1
       	property_value=`cat ${FILE_NAME} | grep ${prop_key} | cut -d'=' -f2`
       	trim $property_value
       	prop_value=${trimmed}
}

validatePath(){
	path=$1
	propertyName=$2
	if [ -f "$path" ] || [ -d "$path" ];then 
		echo  "valid path for "$propertyName
	else
		echo  "please set correct property value for "$propertyName	
		exit
	fi
}

unzipFile(){
	zip_path=$1
	filename=$(basename "$zip_path")
	extension="${filename##*.}"
	echo "extension is "$extension
	if [ "$extension" = "zip" ];
	then
		echo "$2/$3"
		if [ -d "$2/$3" ] ;
		then
			echo $3" zip file already exists in directory"
		else
			unzip $1 -d $2		
		fi
		
	elif [ "$extension" = "war" ];
	then
		if [ -d "$2/$3" ] ;
		
		then
			echo $3" zip file already exists in directory"
		else
			echo "deploy war file......................................."
			unzip $1 -d $2/$3		
		fi
	else
		echo $3" is not a zip file"
		exit
	fi
}

copyFile(){
	if [ -d "$2/$3/CleanCalc" || -d "$2/$3/admin" ] ;
	then
		echo $3" folder already exists in directory"
	else
		cp -R $1 $2
	fi
}

getFileName(){
	FILENAME=${1##*/}
	file_name=${FILENAME%.*}
}
#setup tomcat installation path
getProperty "tomcat_installtion_path"
tomcatPath=${prop_value}
validatePath $tomcatPath "tomcat_installtion_path"
echo "Tomcat tomcat_installtion_path : "$tomcatPath

#setup appm installation path
getProperty "appm_installtion_path"
appmPath=${prop_value} 
validatePath $appmPath "appm_installtion_path"
echo "APPM installtion_path : "$appmPath

#setup lamp server installation path
getProperty "lamp_installation_path"
lampPath=${prop_value} 
echo "LAMP installtion_path : "$lampPath
validatePath $lampPath "lamp_installation_path"

getProperty "tomcat_zip_file"
tomcatPackPath=${prop_value} 
validatePath $tomcatPackPath "tomcat_zip_file"
echo "Tomcat zip file : "$tomcatPackPath

getProperty "appm_zip_file"
appmPackPath=${prop_value} 
validatePath $appmPackPath "appm_zip_file"
echo "Appm zip file : "$appmPackPath

getProperty "planyourtrip_war_file"
travelAppwar=${prop_value} 
validatePath $travelAppwar "planyourtrip_war_file"

getProperty "travel_booking_war_file"
travelBookingAppwar=${prop_value} 
validatePath $travelBookingAppwar "travel_booking_war_file"

getProperty "mobile_application_folder_path"
mobile_application_folderPath=${prop_value} 
validatePath $mobile_application_folderPath "mobile_application_folder_path"
echo "Mobile application folder path : "$mobile_application_folderPath

#notifi_webapp_folder
getProperty "notifi_webapp_folder"
notifi_application_folderPath=${prop_value} 
validatePath $notifi_application_folderPath "notifi_webapp_folder"

getProperty "lamp_zip_file"
lamp_zip_file_path=${prop_value}
validatePath $lamp_zip_file_path "lamp_zip_file"

getProperty "source_checkout_path"
source_chekout_path=${prop_value}
#validatePath $source_chekout_path "source_checkout_path"

getProperty "appm_startup_jar_file_path"
appm_startup_jar_file_path=${prop_value}
#validatePath $appm_startup_jar_file_path "appm_startup_jar_file_path"

getProperty "username"
username=${prop_value}

getProperty "password"
password=${prop_value}

getProperty "isStacts"
isStacts=${prop_value} 

getProperty "ip_address"
ip_address=${prop_value}

getProperty "hit_count" 
hit_count=${prop_value}

if [ $isStacts = "true" ] ;
then
	echo "stacts enabled...................."		
	getProperty "bam_zip_file"
	bam_zip_file_path=${prop_value} 
	echo "bam zip file path "$bam_zip_file_path
	validatePath $bam_zip_file_path "bam_zip_file"

	getProperty "bam_installation_path"
	bam_installation_path=${prop_value} 
	validatePath $bam_installation_path "bam_installation_path"	
	
	getFileName $bam_zip_file_path
	bam_name=${file_name} 
	unzipFile $bam_zip_file_path $bam_installation_path $bam_name


fi

#setting up servers
#settinguptomcat
getFileName $tomcatPackPath
tomcat_name=${file_name} 
echo "Tomcat file name "$tomcat_name
unzipFile $tomcatPackPath $tomcatPath $tomcat_name
#settingup lamp
getFileName $lamp_zip_file_path
lamp_name=${file_name} 
unzipFile $lamp_zip_file_path $lampPath $lamp_name
#settingup appm
getFileName $appmPackPath
appm_name=${file_name} 
unzipFile $appmPackPath $appmPath $appm_name

#deploaying web application
#deploy plan-your-trip
getFileName $travelAppwar
travel_webapp_name=${file_name}
unzipFile $travelAppwar $tomcatPath"/"$tomcat_name"/webapps" $travel_webapp_name 
echo "Travel Application deployed"
#deploy travel-booking
getFileName $travelBookingAppwar
travel_booking_webapp_name=${file_name}
echo "travel_booking_webapp_name "$travel_booking_webapp_name
unzipFile $travelBookingAppwar $tomcatPath"/"$tomcat_name"/webapps" $travel_booking_webapp_name
#deploy notifi 
copyFile $notifi_application_folderPath $lampPath"/"$lamp_name"/htdocs" "notifi"

#deploy mobile application
copyFile $mobile_application_folderPath $appmPath"/"$appm_name"/repository/resources" "mobileapps"

getFileName $appm_startup_jar_file_path
appm_startup_jarFileName=${file_name}

cp -R "./carbon.xml" $appmPath"/"$appm_name"/repository/conf"

if [ -f "$source_chekout_path/pom.xml" ] ;
then
	echo "building from source"
	if [ ! -f $source_chekout_path"/target/"APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies.jar ];then
		cd $source_chekout_path 
		mvn clean install
		cd 
	fi
		
elif [ $appm_startup_jarFileName = "APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies" ] ;
then
	echo "run it from jar file"
else
	echo "please set valid path for source_checkout_path or appm_startup_jar_file_path "	
	exit
fi

if [ $isStacts = "true" ] ;
then
  #echo configured appmanager and bam for  Statistics	
  cp $appmPath/$appm_name/statistics/API_Manager_Analytics.tbox $bam_installation_path/$bam_name/repository/deployment/server/bam-toolbox 
  java -cp $source_chekout_path"/target/"APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies.jar org.wso2.carbon.appmgt.sampledeployer.main.ConfigureStatisticsMain $appmPath"/"$appm_name $bam_installation_path"/"$bam_name 3 $ip_address

  sudo chmod 755 -R $bam_installation_path"/"$bam_name"/bin"
  gnome-terminal -e "sh $bam_installation_path/$bam_name/bin/wso2server.sh"
fi

sudo chmod 755 -R $appmPath"/"$appm_name"/bin"
gnome-terminal -e  "sh $appmPath/$appm_name/bin/wso2server.sh"

java -cp $source_chekout_path"/target/"APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies.jar org.wso2.carbon.appmgt.sampledeployer.main.ApplicationPublisher 8080 $appmPath"/"$appm_name $username $password $tomcatPath"/"$tomcat_name $lampPath"/"$lamp_name $ip_address $hit_count


echo "process complete......."