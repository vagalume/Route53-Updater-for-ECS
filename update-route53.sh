#!/bin/bash
function valid_ip () {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
          stat=$?
    fi
    return $stat
}

while [[ 1 ]]; do
    CURRENT_IP=$(curl -sS $IP_PROVIDER)
    LAST_IP=$(getent hosts $AWS_ROUTE53_HOST | awk '{ print $1 ; exit }')

    if ! valid_ip $CURRENT_IP; then
      echo "Invalid IP address CURRENT_IP: $CURRENT_IP"
      sleep $UPDATE_INTERVAL
      continue
    fi

    if [ $CURRENT_IP == $LAST_IP ]; then
        echo "IP is the same ($CURRENT_IP)"
        sleep $UPDATE_INTERVAL
        continue
    else
        echo "IP has changed to $CURRENT_IP (last was $LAST_IP)"
        # Fill a temp file with valid JSON
        TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
        cat > ${TMPFILE} << EOF
        {
          "Comment":"Auto update @ `date`",
          "Changes":[
            {
              "Action":"UPSERT",
              "ResourceRecordSet":{
                "ResourceRecords":[
                  {
                    "Value":"$CURRENT_IP"
                  }
                ],
                "Name":"$AWS_ROUTE53_HOST",
                "Type":"A",
                "TTL":$AWS_ROUTE53_TTL
              }
            }
          ]
        }
EOF

        # Update the Hosted Zone record
        echo "Updating Route53..."
        aws route53 change-resource-record-sets \
            --hosted-zone-id $AWS_ROUTE53_ZONEID \
            --change-batch file://"$TMPFILE"

        rm -f $TMPFILE
    fi

    sleep $UPDATE_INTERVAL
done
