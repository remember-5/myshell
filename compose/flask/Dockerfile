FROM python:3.10.12-alpine

WORKDIR /data
COPY app.py requirements.txt /data/

RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip install -r requirements.txt && \
    pip list && \
    pip -V

CMD ["gunicorn", "-w" ,"4" ,"-b" ,"0.0.0.0:8000", "app:app" ,"&"]

EXPOSE 8000
