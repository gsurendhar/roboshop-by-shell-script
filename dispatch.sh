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

dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Installing GoLang"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "Roboshop system user " roboshop 
    VALIDATE $? "Roboshop system user creating" 
else
    echo -e "roboshop user is already Created ....$Y SKIPPING USER Creation $N"
fi

mkdir -p /app
VALIDATE $? "Creating App directory"

curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading dispatch"

cd /app 
rm -rf /app/*
unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "Unzipping dispatch"

go mod init dispatch &>>$LOG_FILE
go get  &>>$LOG_FILE
go build  &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "Copying Dispatch Service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon Reloading"

systemctl enable dispatch &>>$LOG_FILE
VALIDATE $? "Enabling Dispatch Service"

systemctl start dispatch &>>$LOG_FILE
VALIDATE $? "Starting Dispatch Service"

END_TIME=$(date +%S)
TOTAL_TIME=$(($END_TIME-$START_TIME))
echo -e "Script Execution Completed Successfully, $Y time taken : $TOTAL_TIME Seconds $N " | tee -a $LOG_FILE