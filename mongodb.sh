#!/bin/bash
#variables
START_SCRIPT=$(date +%S)
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


cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo &>>$LOG_FILE
VALIDATE $? "Copying mongodb repo"

dnf install mongodb-org -y   &>>$LOG_FILE
VALIDATE $? "MongoDB installation"

systemctl enable mongod   &>>$LOG_FILE
VALIDATE $? "Enabling MongoDB Service "

systemctl start mongod    &>>$LOG_FILE
VALIDATE $? "Starting MongoDB Service "

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf     &>>$LOG_FILE
VALIDATE $? "Editing mongodb conf file for remote connection "

systemctl restart mongod    &>>$LOG_FILE
VALIDATE $? "Restarting MongoDB Service "