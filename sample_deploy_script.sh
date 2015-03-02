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
	if file --mime-type "$zip_path" | grep -q zip$ || file --mime-type "$zip_path" | grep -q gzip$ ;
	then
		echo "$2/$3"
		if [ -d "$2/$3" ] ;
		then
			echo $3" zip file already exists in directory"
		else
			unzip $1 -d $2		
		fi
		
	elif file --mime-type "$zip_path" | grep -q war$ :
	then
		if [ -d "$2/$3" ] ;
		then
			echo $3" zip file already exists in directory"
		else
			unzip $1 -d $2/$3		
		fi
	else
		echo $3" is not a zip file"
		exit
	fi
}

copyFile(){
	if [ -d "$2/$3" ] ;
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
validatePath $appm_startup_jar_file_path "appm_startup_jar_file_path"

getProperty "username"
username=${prop_value}

getProperty "password"
password=${prop_value}

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

echo "Starting tomcat......"
sudo chmod 755 -R $tomcatPath"/"$tomcat_name"/bin"
sh $tomcatPath"/"$tomcat_name"/bin/startup.sh"
sudo /etc/init.d/apache2 stop
sudo $lampPath/lampp/lampp start
echo "Starting app manager......"
sudo chmod 755 -R $appmPath"/"$appm_name"/bin"
gnome-terminal -e  "sh $appmPath/$appm_name/bin/wso2server.sh"

getFileName $appm_startup_jar_file_path
appm_startup_jarFileName=${file_name}

if [ -f "$source_chekout_path/pom.xml" ] ;
then
	echo "building from source"
	if [ ! -f $source_chekout_path"/target/"APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies.jar ];then

		cd $source_chekout_path 
		mvn clean install
		cd 
	fi
	java -cp $source_chekout_path"/target/"APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies.jar org.wso2.carbon.appmgt.sampledeployer.main.MainController 8080 80 $appmPath"/"$appm_name $username $password
elif [ $appm_startup_jarFileName=="APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies" ] ;
then
	echo "run it from jar file"
	java -cp $appm_startup_jar_file_path org.wso2.carbon.appmgt.sampledeployer.main.MainController 8080 80 $appmPath"/"$appm_name $username $password
else
	echo "please set valid path for source_checkout_path or appm_startup_jar_file_path "	
	exit
fi

echo "process complete......."