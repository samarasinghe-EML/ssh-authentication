#!/bin/bash
TARGET_USER=ec2-user

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install pam_yubico ruby git -y

echo "Switched to $TARGET_USER"

# Clone the repo and move it to the appropriate directory

TMP_GIT_GARGET=/tmp/ssh-authentication/

sudo -u $TARGET_USER -H git clone https://github.com/Wantsa/ssh-authentication.git $TMP_GIT_GARGET --branch two-factor
sudo -u $TARGET_USER -H rsync -ac $TMP_GIT_GARGET /home/$TARGET_USER/.ssh/
sudo -u $TARGET_USER -H rm -rf $TMP_GIT_GARGET

sudo -u $TARGET_USER -H /home/$TARGET_USER/.ssh/rebase.sh

# Update the SSH config

perl -i.original -pe 's/^ChallengeResponseAuthentication (yes|no)/ChallengeResponseAuthentication yes\nAuthenticationMethods publickey,keyboard-interactive:pam\n/gm' /etc/ssh/sshd_config
service sshd reload


# Append the cron job to the root user's crontab, creating one if it does not exist:

command="/home/$TARGET_USER/.ssh/rebase.sh >/dev/null 2>&1"
job="*/5 * * * * $command"
cat <(fgrep -i -v "$command" <(sudo -u $TARGET_USER -H crontab -l)) <(echo "$job") | sudo -u $TARGET_USER -H crontab -