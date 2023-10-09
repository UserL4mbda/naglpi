#Usage:
# docker build -t naglpi .
# docker run --name supervision --rm -d -p 80:80 -t naglpi

# The line below states we will base our new image on the Latest Official Ubuntu 
# The source is: https://hub.docker.com/r/jasonrivers/nagios/dockerfile
FROM jasonrivers/nagios:latest as build

LABEL maintainer="stephane.dany@greta06.fr"

# Update the image to the latest packages
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y tmux vim curl

# Installation pwsh
#RUN apt-get install -y wget apt-transport-https software-properties-common
#RUN wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
#RUN dpkg -i packages-microsoft-prod.deb
#RUN apt-get update #Un second update pour être certain que le dépackages soit bien prit en compte
#RUN apt-get install -y powershell

# Installation de check_snmp_printer
#RUN curl https://raw.githubusercontent.com/ynlamy/check_snmp_printer/master/check_snmp_printer -o /opt/nagios/libexec/check_snmp_printer
#RUN chown nagios /opt/nagios/libexec/check_snmp_printer
#RUN chmod +x /opt/nagios/libexec/check_snmp_printer

#Changer la ligne de commande pour correspondre au docker "cfg_file=/opt/nagios/etc/objects/printer.cfg"
#COPY printer.cfg /opt/nagios/etc/objects
COPY commands.cfg /opt/nagios/etc/objects
COPY nagios.cfg /opt/nagios/etc
#COPY switch.cfg /opt/nagios/etc/objects
COPY templates.cfg /opt/nagios/etc/objects
#COPY devices.cfg /opt/nagios/etc/objects
COPY localhost.cfg /opt/nagios/etc/objects


#Version modifiee de check_snmp_printer
#qui renvoie UNKNOWN quand info est vide (et non OK)
#COPY check_snmp_printer /opt/nagios/libexec
#COPY check_snmp_printer_alert /opt/nagios/libexec
#COPY check_test /opt/nagios/libexec

# Installation de GOLANG
RUN mkdir /temp 2>/dev/null
RUN mkdir /usr/local/go 2>/dev/null
RUN curl -s -L https://go.dev/dl/go1.21.1.linux-amd64.tar.gz -o /temp/go1.21.1.linux-amd64.tar.gz
RUN tar -C /usr/local -xzf /temp/go1.21.1.linux-amd64.tar.gz

ENV GOPATH /opt/nagios/libexec
ENV GOROOT /usr/local/go
ENV PATH $GOPATH:$GOPATH/bin:$GOROOT/bin:$PATH


RUN curl -s https://raw.githubusercontent.com/UserL4mbda/check_teamviewer/main/check_teamviewer.go -o /opt/nagios/libexec/check_teamviewer.go
RUN go build -o /opt/nagios/libexec/check_teamviewer /opt/nagios/libexec/check_teamviewer.go
RUN chmod +x /opt/nagios/libexec/check_teamviewer

FROM build

COPY devices.cfg /opt/nagios/etc/objects