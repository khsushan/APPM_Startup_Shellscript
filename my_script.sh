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

getProperty "mobile_application_folder"
mobile_application_folderPath=${prop_value} 
echo "Mobile application folder path : "$mobile_application_folderPath

#notifi_webapp_folder
getProperty "notifi_webapp_folder"
notifi_application_folderPath=${prop_value} 

getProperty "lamp_zip_file"
lamp_zip_file_path=${prop_value}

unzipFile(){
	unzip $1 -d $2	
}

#setting up servers
unzipFile $tomcatPackPath $tomcatPath
sudo chmod 777 -R /opt
unzipFile $lamp_zip_file_path "/opt"
unzipFile $appmPackPath $appmPath
#deploying web application samples
FILENAME=${tomcatPackPath##*/}
tomcat_name=${FILENAME%.*}
unzipFile $travelAppwar $tomcatPath"/"$tomcat_name"/webapps/plan-your-trip"
echo "Travel Application deployed"
unzipFile $travelBookingAppwar $tomcatPath"/"$tomcat_name"/webapps/tavel-booking"	
echo "Travel Booking Application deployed"
sudo chmod 777 -R /opt/lampp/htdocs
cp -R $notifi_application_folderPath "/opt/lampp/htdocs"
echo "notifi Application deployed"
#deploying mobile applications
FILENAME=${appmPackPath##*/}
appm_name=${FILENAME%.*}
cp -R $mobile_application_folderPath $appmPath"/"$appm_name"/repository/resources"
#starting servers
echo "Starting tomcat......"
sudo chmod 755 -R $tomcatPath"/"$tomcat_name"/bin"
sh $tomcatPath"/"$tomcat_name"/bin/startup.sh"
sudo /opt/lampp/lampp start
echo "Starting app manager......"
sudo chmod 755 -R $appmPath"/"$appm_name"/bin"
gnome-terminal -e  "sh $appmPath/$appm_name/bin/wso2server.sh"
#run java programme
java -cp ./APPM_Startup-1.0-SNAPSHOT-jar-with-dependencies.jar com.wso2.main.MainController 8080 80 $appmPath"/"$appm_name

echo "webapps deployed..."