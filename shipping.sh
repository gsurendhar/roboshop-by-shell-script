#!/bin/bash
#variables
START_TIME=$(date +%S)
USERID=$(id -u)
SCRIPT_DIR=$PWD
LOG_FOLDER="/var/log/roboshop-shell-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


echo "Script execution started at $(date) " | tee -a $LOG_FILE

mkdir -p $LOG_FOLDER

# ROOT PRIVILEGES CHECKING
if [ $USERID -ne 0 ]
then 
    echo -e " $R ERROR:$N Please run Script with the root access " | tee -a $LOG_FILE
    exit 1
else 
    echo -e " You are already running with $Y ROOT $N access " | tee -a $LOG_FILE
fi

# VALIDATION FUNCTION
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ........$G SUCCESSES $N"  | tee -a $LOG_FILE
    else    
        echo -e "$2 is .........$R FAILURE $N"   | tee -a $LOG_FILE
        exit 1
    fi
}


dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing MAVEN and JAVA"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user " roboshop 
    VALIDATE $? "Roboshop system user creating" 
else
    echo -e "roboshop user is already Created ....$Y SKIPPING USER Creation $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating App directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading Shipping"

cd /app 
rm -rf /app/*
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Packing the Sipping Application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving and Renaming JAR file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &>>$LOG_FILE
VALIDATE $? "Copying Shipping Service File"

systemctl daemon-reload  &>>$LOG_FILE
VALIDATE $? "Daemon Reloading"

systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enabling Shipping Service"

systemctl start shipping  &>>$LOG_FILE
VALIDATE $? "Starting Shipping Service"

echo "Please enter MySql Root Password"  | tee -a $LOG_FILE
read -s MYSQL_ROOT_PASSWORD

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySql Client"

mysql -h mysql.gonela.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql  &>>$LOG_FILE
VALIDATE $? "Loading SCHEMAS to MySQL"

mysql -h mysql.gonela.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
VALIDATE $? "Loading APP-USER DATA to MySQL"

mysql -h mysql.gonela.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "Loading MASTER_DATA to MySQL"

systemctl restart shipping  &>>$LOG_FILE
VALIDATE $? "Restarting Shipping Services" 

END_TIME=$(date +%S)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script Execution Completed Successfully, $Y time taken : $TOTAL_TIME Seconds $N " | tee -a $LOG_FILE