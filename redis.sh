#!/bin/bash
#variables
START_TIME=$(date +%S)
USERID=$(id -u)
SCRIPT_DIR=$PWD
LOG_FOLDER="/var/log/roboshop-shell-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
R="\e[31"
G="\e[31"
Y="\e[31"
N="\e[31"

echo "Script execution started at $START_TIME " | tee -a $LOG_FILE

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

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling Default Redis "

dnf module enable redis:7 -y  &>>$LOG_FILE
VALIDATE $? "Enabling Redis:7 "

dnf install redis -y   &>>$LOG_FILE
VALIDATE $? "Installing Redis:7 "

sed -i -e '/s/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c /protected-mode no' /etc/redis/redis.conf  &>>$LOG_FILE
VALIDATE $? "Edited Redis conf file to accept remote connections"

systemctl enable redis &>>$LOG_FILE
VALIDATE $? "Enabling Redis service"

systemctl start redis &>>$LOG_FILE
VALIDATE $? "Starting the Redis service"

END_TIME=$(date +%S)
TOTAL_TIME=$(($END_TIME-$START_TIME)) &>>$LOG_FILE
echo -e "Script Execution Completed Successfully, $Y time taken : $TOTAL_TIME Seconds $N" | tee -a $LOG_FILE