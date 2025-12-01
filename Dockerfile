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
    build-essential \
    python3-dev \
    libssl-dev \
    libffi-dev \
    default-libmysqlclient-dev \
    freetds-dev \
    libsasl2-dev \
    apt-transport-https \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# create the venv so /app/.venv exists at build time; upgrade pip tooling
RUN python3 -m venv /app/.venv \
    && /app/.venv/bin/python -m pip install --upgrade pip setuptools wheel

# Install packages in smaller groups to make failures obvious.
# 1) pure-python packages first
RUN /app/.venv/bin/pip install --no-cache-dir \
    pymongo \
    sqlalchemy

# 2) snowflake packages next (these sometimes pull cryptography)
RUN /app/.venv/bin/pip install --no-cache-dir --prefer-binary \
    "snowflake-connector-python==4.1.0" \
    "snowflake-sqlalchemy==1.7.7"

# 3) native DB drivers last (mysqlclient, pyodbc, pymssql)
RUN /app/.venv/bin/pip install --no-cache-dir \
    psycopg2-binary \
    pyodbc \
    mysqlclient \
    pymssql

# sanity checks
RUN /app/.venv/bin/pip show snowflake-sqlalchemy || true
RUN /app/.venv/bin/pip show snowflake-connector-python || true
RUN /app/.venv/bin/python -c "import importlib,sys; print('py',sys.executable); print('sqlalchemy', importlib.import_module('sqlalchemy').__version__); print('snowflake spec', importlib.util.find_spec('snowflake.sqlalchemy'))"

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
