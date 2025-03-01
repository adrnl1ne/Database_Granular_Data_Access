FROM mcr.microsoft.com/mssql/server:2019-latest

ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=SuperSecret123!
ENV MSSQL_PID=Developer

USER root
RUN apt-get update && apt-get install -y curl gnupg dos2unix && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev

COPY setup.sql /usr/src/app/setup.sql
RUN dos2unix /usr/src/app/setup.sql && \
    mkdir -p /var/opt/mssql/data && \
    chmod -R 777 /var/opt/mssql/data && \
    (/opt/mssql/bin/sqlservr & ) && \
    sleep 30 && \
    /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "SuperSecret123!" -d master -i /usr/src/app/setup.sql && \
    pkill sqlservr && sleep 5

CMD ["/opt/mssql/bin/sqlservr"]