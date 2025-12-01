FROM apache/superset:latest

USER root

RUN apt-get update && apt-get install -y \
    pkg-config \
    libmariadb-dev \
    unixodbc \
    unixodbc-dev \
    libpq-dev \
    gcc \
    g++ \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install DB drivers into Superset's virtualenv so the runtime can load them
RUN /app/.venv/bin/pip install --no-cache-dir \
    psycopg2-binary \
    pymongo \
    pymssql \
    pyodbc \
    mysqlclient \
    sqlalchemy \
    snowflake-connector-python \
    snowflake-sqlalchemy

# sanity checks using the same venv
RUN /app/.venv/bin/pip show snowflake-sqlalchemy && /app/.venv/bin/pip show snowflake-connector-python

ENV ADMIN_USERNAME $ADMIN_USERNAME
ENV ADMIN_EMAIL $ADMIN_EMAIL
ENV ADMIN_PASSWORD $ADMIN_PASSWORD

COPY /config/superset_init.sh ./superset_init.sh
RUN chmod +x ./superset_init.sh

COPY /config/superset_config.py /app/
ENV SUPERSET_CONFIG_PATH /app/superset_config.py
ENV SECRET_KEY $SECRET_KEY

USER superset

ENTRYPOINT [ "./superset_init.sh" ]
