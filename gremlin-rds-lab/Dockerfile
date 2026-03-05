FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq ca-certificates \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ec2-user

WORKDIR /home/ec2-user/gremlin-rds-lab

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY seed_rds.sh .
COPY start.sh .
COPY db_test_query.sh .
COPY connect_to_rds.sh .

RUN chmod +x seed_rds.sh start.sh && chown -R ec2-user:ec2-user /home/ec2-user

USER ec2-user

ENV PYTHONUNBUFFERED=1
EXPOSE 8080

ENTRYPOINT ["./start.sh"]
