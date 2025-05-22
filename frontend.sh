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

dnf module disable nginx -y
VALIDATE $? " Disabling Default nginx "

dnf module enable nginx:1.24 -y
VALIDATE $? "Enabling Nginx:1.24 "

dnf install nginx -y
VALIDATE $? "Installing Nginx:1.24"

systemctl enable nginx 
VALIDATE $? "Enabling Nginx service"

systemctl start nginx 
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing Default Content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading Frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "Unzipping Frontend"

rm -rf /etc/nginx/nginx.conf
VALIDATE $? "Removing Default nginx conf file"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Adding nginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarting Nginx"
