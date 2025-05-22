#!/bin/bash
#variables
START_SCRIPT=$(date +%S)
USERID=$(id -u)
SCRIPT_DIR=$PWD
LOG_FOLDER="/var/log/roboshop-shell-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
R="\e[31"
G="\e[31"
Y="\e[31"
N="\e[31"

echo "Script execution started at $START_SCRIPT " | tee -a $LOG_FILE

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

dnf module disable nodejs -y   &>>$LOG_FILE
VALIDATE $? "Disabling Default nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "enabling Default nodejs"

dnf install nodejs -y      &>>$LOG_FILE
VALIDATE $? "Installing nodejs:20 "

useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user " roboshop  &>>$LOG_FILE
VALIDATE $? "Roboshop system user creating" 

mkdir -p /app
VALIDATE $? "Creating App directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading Catalogue"

cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "catalogue service file is copied "

systemctl daemon-reload  &>>$LOG_FILE
VALIDATE $? "Daemon Realoding"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Catalogue is enabling"

systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Staring the Catalogue service"

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing Mongodb Client"







