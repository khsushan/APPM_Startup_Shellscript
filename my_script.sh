#!/bin/bash
# My first script

FILE_NAME=appm_startup.properties
prop_value=""
getProperty()
{
        prop_key=$1
        prop_value=`cat ${FILE_NAME} | grep ${prop_key} | cut -d'=' -f2`
}

getProperty "tomcat_installtion_path"
tomcatPath=${prop_value} 
echo "Tomcat tomcat_installtion_path : "$tomcatPath


getProperty "appm_installtion_path"
appmPath=${prop_value} 
echo "APPM installtion_path : "$appmPath

getProperty "tomcat_zip_file"
tomcatPackPath=${prop_value} 
echo "Tomcat zip file : "$tomcatPackPath

getProperty "appm_zip_file"
appmPackPath=${prop_value} 
echo "Appm zip file : "$appmPackPath

getProperty "planyourtrip_war_file"
travelAppwar=${prop_value} 

getProperty "travel_booking_war_file"
travelBookingAppwar=${prop_value} 

unzipFile(){
	unzip $1 -d $2	
}

unzipFile $tomcatPackPath $tomcatPath
unzipFile $appmPackPath $appmPath
unzipFile $travelAppwar $tomcatPath"/apache-tomcat-7.0.59/webapps/plan-your-trip"
echo "Travel Application deployed"
unzipFile $travelBookingAppwar $tomcatPath"/apache-tomcat-7.0.59/webapps/tavel-booking"	
echo "Travel Booking Application deployed"

echo "Starting tomcat......"
sudo chmod 755 -R $tomcatPath"/apache-tomcat-7.0.59/bin"
sh $tomcatPath"/apache-tomcat-7.0.59/bin/startup.sh"

echo "Starting app manager......"
sudo chmod 755 -R $appmPath"/wso2appm-1.0.0-SNAPSHOT/bin"

gnome-terminal -e  "sh $appmPath/wso2appm-1.0.0-SNAPSHOT/bin/wso2server.sh"

java -cp /home/ushan/IdeaProjects/APPM_Startup/target/APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies.jar com.wso2.main.MainController

echo "webapps deployed..."