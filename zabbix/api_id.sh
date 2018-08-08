#!/bin/bash
# Script to get zabbix id and pass it to sendreport script 
# Mohamad Yousri - 5/2018


request_body="$(cat <<-EOF
{
 "jsonrpc": "2.0",
    "method": "host.get",
    "params": {
        "output": "host_id",
        "filter": {
            "host": [
                "exa102.yaqob.com"
            ]
        }
    },
    "auth": "4eeca011ce9997d316bdfda362a7f5b5",
    "id": 1

    }
EOF
)"

host="$(curl -sSH "Content-Type: application/json" -X POST -d "$request_body" http://monitoring.exahost.com/api_jsonrpc.php)"

id=`echo $host | cut -c39-43`



echo "$id;eng.ahmed.saber76@gmail.com;exa102.yaqob.com" | ssh monadmin@monitoring.exahost.com "cat >> /usr/share/zabbix/sendreport/clients" > /dev/null 2>&1
#echo $id


